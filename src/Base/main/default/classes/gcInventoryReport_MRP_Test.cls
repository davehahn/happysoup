/**
 * Created by Legend on 2/12/21.
 */

@IsTest
private class gcInventoryReport_MRP_Test {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void testInventoryMRP() {
    map<Id, map<Id, map<Id, Id>>> mapPWLB = new Map<Id, map<Id, map<Id, Id>>>();
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    Product2 serialProd = Factory_Product.createSerializedProduct('Boat', 'Full Windshield');
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertSerialNumber(serialProd, '1234567');
    Id idWarehouse = gcConstants.idWarehouseMontreal;
    AcctSeedERP__Location__c loc = [
      SELECT Id
      FROM AcctSeedERP__Location__c
      WHERE AcctSeedERP__Warehouse__c = :idWarehouse
      LIMIT 1
    ];

    mapPWLB.put(part.Id, new Map<Id, map<Id, Id>>());
    mapPWLB.get(part.Id).put(idWarehouse, new Map<Id, Id>());
    mapPWLB.get(part.Id).get(idWarehouse).put(loc.Id, null);
    mapPWLB.put(serialProd.Id, new Map<Id, map<Id, Id>>());
    mapPWLB.get(serialProd.Id).put(idWarehouse, new Map<Id, Id>());
    mapPWLB.get(serialProd.Id).get(idWarehouse).put(loc.Id, null);

    GCR_InventoryBalance.findOrCreateBalances(mapPWLB);
    Account[] accts = Factory_Account.insertSupplierAccounts(2);
    Account vendor = accts[0];
    Account shipTo = accts[1];
    AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO(vendor.Id, shipTo.Id);
    System.debug([SELECT Id, AcctSeedERP__Vendor_Country__c FROM AcctSeedERP__Purchase_Order__c WHERE Id = :po.Id]);
    AcctSeedERP__Purchase_Order_Line__c pol = new AcctSeedERP__Purchase_Order_Line__c(
      AcctSeedERP__Purchase_Order__c = po.Id,
      AcctSeedERP__Product__c = part.Id,
      AcctSeedERP__Quantity__c = 10,
      AcctSeedERP__Unit_Price__c = 10.00
    );
    AcctSeedERP__Purchase_Order_Line__c pol2 = new AcctSeedERP__Purchase_Order_Line__c(
      AcctSeedERP__Purchase_Order__c = po.Id,
      AcctSeedERP__Product__c = serialProd.Id,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Unit_Price__c = 10.00
    );
    insert new List<AcctSeedERP__Purchase_Order_Line__c>{ pol, pol2 };

    AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      GMBLASERP__Cost_Override__c = true,
      AcctSeedERP__Quantity__c = 5,
      AcctSeedERP__Inventory_Balance__c = mapPWLB.get(part.Id).get(idWarehouse).get(loc.Id),
      AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
      GMBLASERP__Warehouse__c = idWarehouse,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Product__c = part.Id,
      AcctSeedERP__Purchase_Order_Line__c = pol.Id,
      GMBLASERP__Purchase_Order__c = po.Id
    );

    AcctSeedERP__Purchase_Order_Inventory_Movement__c movement2 = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      GMBLASERP__Cost_Override__c = true,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Inventory_Balance__c = mapPWLB.get(serialProd.Id).get(idWarehouse).get(loc.Id),
      AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
      GMBLASERP__Warehouse__c = idWarehouse,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Product__c = serialProd.Id,
      AcctSeedERP__Purchase_Order_Line__c = pol2.Id,
      GMBLASERP__Purchase_Order__c = po.Id,
      GMBLASERP__Serial_Number__c = serial.Id,
      GMBLASERP__Lot__c = serial.GMBLASERP__Lot__c
    );
    gcPurchaseOrderInventoryMovement.disableTrigger = true;
    insert new List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>{ movement, movement2 };

    GMBLASERP.gcInventoryMovementCube.allowDML = true;
    GMBLASERP__Inventory_Movement_Cube__c cube = new GMBLASERP__Inventory_Movement_Cube__c();
    cube.GMBLASERP__Inventory_Balance__c = mapPWLB.get(part.Id).get(idWarehouse).get(loc.Id);
    cube.GMBLASERP__Location__c = loc.Id;
    cube.GMBLASERP__Product__c = part.Id;
    cube.GMBLASERP__Movement_Date__c = Date.today();
    cube.GMBLASERP__Warehouse__c = idWarehouse;
    cube.GMBLASERP__Movement_Type__c = 'AcctSeedERP__Purchase_Order_Inventory_Movement__c';
    cube.GMBLASERP__Quantity__c = 10;
    cube.GMBLASERP__Inventory_GL_Amount__c = 100;

    GMBLASERP__Inventory_Movement_Cube__c cube2 = new GMBLASERP__Inventory_Movement_Cube__c();
    cube.GMBLASERP__Inventory_Balance__c = mapPWLB.get(serialProd.Id).get(idWarehouse).get(loc.Id);
    cube.GMBLASERP__Location__c = loc.Id;
    cube.GMBLASERP__Product__c = serialProd.Id;
    cube.GMBLASERP__Movement_Date__c = Date.today();
    cube.GMBLASERP__Warehouse__c = idWarehouse;
    cube.GMBLASERP__Movement_Type__c = 'AcctSeedERP__Purchase_Order_Inventory_Movement__c';
    cube.GMBLASERP__Quantity__c = 1;
    cube.GMBLASERP__Serial_Number__c = serial.Id;
    cube.GMBLASERP__Lot__c = serial.GMBLASERP__Lot__c;
    cube.GMBLASERP__Inventory_GL_Amount__c = 10;

    GMBLASERP.gcInventoryMovementCube.disableTrigger = true;
    insert new List<GMBLASERP__Inventory_Movement_Cube__c>{ cube, cube2 };
    serial.GMBLASERP__Inventory_Balance__c = mapPWLB.get(serialProd.Id).get(idWarehouse).get(loc.Id);
    serial.GMBLASERP__Product__c = serialProd.Id;
    gcSerialNumber.disableTrigger = true;
    update serial;

    Id idRTPart = LGND_Constants.productRtId_Part;
    Test.startTest();
    PageReference pageRef = Page.gpInventoryReport_MRP;
    Test.setCurrentPage(pageRef);
    gcInventoryReport_MRP obj = new gcInventoryReport_MRP();
    obj.getListWarehouse();
    obj.getListProductType();
    obj.getListProductSuppliers();

    Set<Id> setProductIds = new Set<Id>{ part.Id, serialProd.Id };
    List<Id> listProductIds = new List<Id>();
    listProductIds.addAll(setProductIds);
    gcInventoryReport_MRP.listProductFamily(idRTPart);
    gcInventoryReport_MRP.retrieveProducts(setProductIds, idWarehouse);
    gcInventoryReport_MRP.retrieveProductsByFamily(listProductIds, idWarehouse, idRTPart, 'Hardware');
    gcInventoryReport_MRP.retrieveSerialNumbers(new List<Id>{ serialProd.Id }, null);
    gcInventoryReport_MRP.retrieveProductsByWarehouse(setProductIds, new Set<ID>{ idWarehouse });
    gcInventoryReport_MRP.retrievePurchaseOrders(new List<Id>{ part.Id }, null);
    gcInventoryReport_MRP.updateProductAvailabilityBatch(setProductIds);
    gcInventoryReport_MRP.updateProductAvailabilityWarehouseBatch(setProductIds);
    gcInventoryReport_MRP.updateProductAverageArrivalTime(setProductIds);
    Test.stopTest();
  }

  @IsTest
  static void testInventoryMRPProject() {
    map<Id, map<Id, map<Id, Id>>> mapPWLB = new Map<Id, map<Id, map<Id, Id>>>();
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    Product2 serialProd = Factory_Product.createSerializedProduct('Boat', 'Full Windshield');
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertSerialNumber(serialProd, '1234567');
    Id idWarehouse = gcConstants.idWarehouseMontreal;
    AcctSeedERP__Location__c loc = [
      SELECT Id
      FROM AcctSeedERP__Location__c
      WHERE AcctSeedERP__Warehouse__c = :idWarehouse
      LIMIT 1
    ];

    mapPWLB.put(part.Id, new Map<Id, map<Id, Id>>());
    mapPWLB.get(part.Id).put(idWarehouse, new Map<Id, Id>());
    mapPWLB.get(part.Id).get(idWarehouse).put(loc.Id, null);
    mapPWLB.put(serialProd.Id, new Map<Id, map<Id, Id>>());
    mapPWLB.get(serialProd.Id).put(idWarehouse, new Map<Id, Id>());
    mapPWLB.get(serialProd.Id).get(idWarehouse).put(loc.Id, null);

    GCR_InventoryBalance.findOrCreateBalances(mapPWLB);
    Account[] accts = Factory_Account.insertSupplierAccounts(2);
    Account vendor = accts[0];
    Account shipTo = accts[1];
    AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO(vendor.Id, shipTo.Id);
    System.debug([SELECT Id, AcctSeedERP__Vendor_Country__c FROM AcctSeedERP__Purchase_Order__c WHERE Id = :po.Id]);
    AcctSeedERP__Purchase_Order_Line__c pol = new AcctSeedERP__Purchase_Order_Line__c(
      AcctSeedERP__Purchase_Order__c = po.Id,
      AcctSeedERP__Product__c = part.Id,
      AcctSeedERP__Quantity__c = 10,
      AcctSeedERP__Unit_Price__c = 10.00
    );
    AcctSeedERP__Purchase_Order_Line__c pol2 = new AcctSeedERP__Purchase_Order_Line__c(
      AcctSeedERP__Purchase_Order__c = po.Id,
      AcctSeedERP__Product__c = serialProd.Id,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Unit_Price__c = 10.00
    );
    insert new List<AcctSeedERP__Purchase_Order_Line__c>{ pol, pol2 };

    AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      GMBLASERP__Cost_Override__c = true,
      AcctSeedERP__Quantity__c = 5,
      AcctSeedERP__Inventory_Balance__c = mapPWLB.get(part.Id).get(idWarehouse).get(loc.Id),
      AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
      GMBLASERP__Warehouse__c = idWarehouse,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Product__c = part.Id,
      AcctSeedERP__Purchase_Order_Line__c = pol.Id,
      GMBLASERP__Purchase_Order__c = po.Id
    );

    AcctSeedERP__Purchase_Order_Inventory_Movement__c movement2 = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      GMBLASERP__Cost_Override__c = true,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Inventory_Balance__c = mapPWLB.get(serialProd.Id).get(idWarehouse).get(loc.Id),
      AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
      GMBLASERP__Warehouse__c = idWarehouse,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Product__c = serialProd.Id,
      AcctSeedERP__Purchase_Order_Line__c = pol2.Id,
      GMBLASERP__Purchase_Order__c = po.Id,
      GMBLASERP__Serial_Number__c = serial.Id,
      GMBLASERP__Lot__c = serial.GMBLASERP__Lot__c
    );
    gcPurchaseOrderInventoryMovement.disableTrigger = true;
    insert new List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>{ movement, movement2 };

    GMBLASERP.gcInventoryMovementCube.allowDML = true;
    GMBLASERP__Inventory_Movement_Cube__c cube = new GMBLASERP__Inventory_Movement_Cube__c();
    cube.GMBLASERP__Inventory_Balance__c = mapPWLB.get(part.Id).get(idWarehouse).get(loc.Id);
    cube.GMBLASERP__Location__c = loc.Id;
    cube.GMBLASERP__Product__c = part.Id;
    cube.GMBLASERP__Movement_Date__c = Date.today();
    cube.GMBLASERP__Warehouse__c = idWarehouse;
    cube.GMBLASERP__Movement_Type__c = 'AcctSeedERP__Purchase_Order_Inventory_Movement__c';
    cube.GMBLASERP__Quantity__c = 10;
    cube.GMBLASERP__Inventory_GL_Amount__c = 100;

    GMBLASERP__Inventory_Movement_Cube__c cube2 = new GMBLASERP__Inventory_Movement_Cube__c();
    cube.GMBLASERP__Inventory_Balance__c = mapPWLB.get(serialProd.Id).get(idWarehouse).get(loc.Id);
    cube.GMBLASERP__Location__c = loc.Id;
    cube.GMBLASERP__Product__c = serialProd.Id;
    cube.GMBLASERP__Movement_Date__c = Date.today();
    cube.GMBLASERP__Warehouse__c = idWarehouse;
    cube.GMBLASERP__Movement_Type__c = 'AcctSeedERP__Purchase_Order_Inventory_Movement__c';
    cube.GMBLASERP__Quantity__c = 1;
    cube.GMBLASERP__Serial_Number__c = serial.Id;
    cube.GMBLASERP__Lot__c = serial.GMBLASERP__Lot__c;
    cube.GMBLASERP__Inventory_GL_Amount__c = 10;

    GMBLASERP.gcInventoryMovementCube.disableTrigger = true;
    insert new List<GMBLASERP__Inventory_Movement_Cube__c>{ cube, cube2 };
    serial.GMBLASERP__Inventory_Balance__c = mapPWLB.get(serialProd.Id).get(idWarehouse).get(loc.Id);
    serial.GMBLASERP__Product__c = serialProd.Id;
    gcSerialNumber.disableTrigger = true;
    update serial;
    gcAccount.disableTrigger = true;
    gcProject.disableTrigger = true;
    gcProjectTask.disableTrigger = true;
    gcMaterial.disableTrigger = true;
    Account dealer = AccountFactory.buildDealerAccount('Testy McDealer');
    insert dealer;
    Id ppOrderRtId = LGND_Utilities.recordTypeIdFromName('AcctSeed__Project__c', 'Legend Partner Parts Order');
    AcctSeed__Project__c partsOrder = Factory_ERPOrder.buildERP(dealer, serial.Id, ppOrderRtId);
    insert partsOrder;
    AcctSeed__Project_Task__c task = Factory_ERPOrder.buildProjectTask(partsOrder.Id, 'Test Task');
    insert task;
    AcctSeedERP__Material__c material = Factory_ERPOrder.buildMaterial(partsOrder.Id, task.Id, part.Id);
    insert material;

    Test.startTest();
    gcInventoryReport_MRP.retrieveProjects(new List<Id>{ part.Id }, null);
    Test.stopTest();
  }
}
