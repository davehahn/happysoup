@isTest
private class gcInventoryAdjustment_Ext_Test {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void testAdjustmentValue() {
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    Id idWarehouse = gcConstants.idWarehouseMontreal;
    AcctSeedERP__Location__c loc = [
      SELECT Id
      FROM AcctSeedERP__Location__c
      WHERE AcctSeedERP__Warehouse__c = :idWarehouse
      LIMIT 1
    ];
    Id idBalance = GCR_InventoryBalance.findOrCreateBalance(part.Id, idWarehouse, loc.Id);
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
    insert pol;

    AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      GMBLASERP__Cost_Override__c = true,
      AcctSeedERP__Quantity__c = 10,
      AcctSeedERP__Inventory_Balance__c = idBalance,
      AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
      GMBLASERP__Warehouse__c = idWarehouse,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Product__c = part.Id,
      AcctSeedERP__Purchase_Order_Line__c = pol.Id,
      GMBLASERP__Purchase_Order__c = po.Id
    );
    gcPurchaseOrderInventoryMovement.disableTrigger = true;
    insert movement;

    GMBLASERP.gcInventoryMovementCube.allowDML = true;
    GMBLASERP__Inventory_Movement_Cube__c cube = new GMBLASERP__Inventory_Movement_Cube__c();
    cube.GMBLASERP__Inventory_Balance__c = idBalance;
    cube.GMBLASERP__Location__c = loc.Id;
    cube.GMBLASERP__Product__c = part.Id;
    cube.GMBLASERP__Movement_Date__c = Date.today();
    cube.GMBLASERP__Warehouse__c = idWarehouse;
    cube.GMBLASERP__Movement_Type__c = 'AcctSeedERP__Purchase_Order_Inventory_Movement__c';
    cube.GMBLASERP__Quantity__c = 10;
    cube.GMBLASERP__Inventory_GL_Amount__c = 100;
    insert cube;

    GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c();
    adj.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
    adj.Department_GLV_2__c = gcConstants.idGlv2Sales;
    adj.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
    adj.GMBLASERP__Product__c = part.Id;
    adj.GMBLASERP__Adjustment_Type__c = 'Value';
    insert adj;

    Test.startTest();
    ApexPages.StandardController sc = new ApexPages.StandardController(adj);
    gcInventoryAdjustment_Ext obj = new gcInventoryAdjustment_Ext(sc);
    List<SelectOption> listPT = obj.getListProductType();
    map<string, string> mapString = gcInventoryAdjustment_Ext.createAdjustment(adj.Id, part.Id);
    Id idMove = mapString.get('idMove');
    GMBLASERP.gcInventoryAdjustment.disableTrigger = true;
    gcInboundInventoryMovement.disableTrigger = true;
    gcOutboundInventoryMovement.disableTrigger = true;
    gcInventoryAdjustment_Ext.adjustValue(idMove, -5);
    gcInventoryAdjustment_Ext.adjustValueIn(idMove, -5);
    Test.stopTest();
  }

  @IsTest
  static void testAdjustmentQuantity() {
    Id idWarehouse = gcConstants.idWarehouseMontreal;
    AcctSeedERP__Location__c loc = [
      SELECT Id
      FROM AcctSeedERP__Location__c
      WHERE AcctSeedERP__Warehouse__c = :idWarehouse
      LIMIT 1
    ];
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    Id idBalance = GCR_InventoryBalance.findOrCreateBalance(part.Id, idWarehouse, loc.Id);
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
    insert pol;

    AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      GMBLASERP__Cost_Override__c = true,
      AcctSeedERP__Quantity__c = 10,
      AcctSeedERP__Inventory_Balance__c = idBalance,
      AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
      GMBLASERP__Warehouse__c = idWarehouse,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Product__c = part.Id,
      AcctSeedERP__Purchase_Order_Line__c = pol.Id,
      GMBLASERP__Purchase_Order__c = po.Id
    );
    GMBLASERP.gcPurchaseOrderInventoryMovement.disableTrigger = true;
    insert movement;

    GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c();
    adj.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
    adj.Department_GLV_2__c = gcConstants.idGlv2Sales;
    adj.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
    adj.GMBLASERP__Warehouse__c = idWarehouse;
    adj.GMBLASERP__Product__c = part.Id;
    adj.GMBLASERP__Adjustment_Type__c = 'Quantity';
    insert adj;

    Test.startTest();
    map<string, string> mapString = gcInventoryAdjustment_Ext.createAdjustment(adj.Id, part.Id);
    Id idMove = mapString.get('idMove');
    gcInventoryAdjustment_Ext.adjustQuantity(idMove, 1);
    Test.stopTest();
  }

  @IsTest
  static void testAdjustmentDelete() {
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    Account[] accts = Factory_Account.insertSupplierAccounts(2);
    Account vendor = accts[0];
    Account shipTo = accts[1];
    AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO(vendor.Id, shipTo.Id);
    AcctSeedERP__Purchase_Order_Line__c pol = new AcctSeedERP__Purchase_Order_Line__c(
      AcctSeedERP__Purchase_Order__c = po.Id,
      AcctSeedERP__Product__c = part.Id,
      AcctSeedERP__Quantity__c = 10,
      AcctSeedERP__Unit_Price__c = 10.00
    );
    insert pol;
    Id idWarehouse = gcConstants.idWarehouseMontreal;
    AcctSeedERP__Location__c loc = [
      SELECT Id
      FROM AcctSeedERP__Location__c
      WHERE AcctSeedERP__Warehouse__c = :idWarehouse
      LIMIT 1
    ];
    Id idBalance = GCR_InventoryBalance.findOrCreateBalance(part.Id, idWarehouse, loc.Id);

    AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      GMBLASERP__Cost_Override__c = true,
      AcctSeedERP__Quantity__c = 10,
      AcctSeedERP__Inventory_Balance__c = idBalance,
      AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
      GMBLASERP__Warehouse__c = idWarehouse,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Product__c = part.Id,
      AcctSeedERP__Purchase_Order_Line__c = pol.Id,
      GMBLASERP__Purchase_Order__c = po.Id
    );
    GMBLASERP.gcPurchaseOrderInventoryMovement.disableTrigger = true;
    insert movement;

    GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c();
    adj.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
    adj.Department_GLV_2__c = gcConstants.idGlv2Sales;
    adj.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
    adj.GMBLASERP__Warehouse__c = idWarehouse;
    adj.GMBLASERP__Product__c = part.Id;
    adj.GMBLASERP__Adjustment_Type__c = 'Quantity';
    insert adj;

    Test.startTest();
    map<string, string> mapString = gcInventoryAdjustment_Ext.createAdjustment(adj.Id, part.Id);
    Id idMove = mapString.get('idMove');
    gcInventoryAdjustment_Ext.adjustQuantity(idMove, 1);
    gcInventoryAdjustment_Ext.deleteMove(idMove);
    Test.stopTest();
  }

  @IsTest
  static void testAdjustmentValueSerialized() {
    Product2 boat = Factory_Product.buildSerializedProduct('Boat', 'Full Windshield');
    insert boat;
    Id idWarehouse = gcConstants.idWarehouseMontreal;
    AcctSeedERP__Location__c loc = [
      SELECT Id
      FROM AcctSeedERP__Location__c
      WHERE AcctSeedERP__Warehouse__c = :idWarehouse
      LIMIT 1
    ];
    Id idBalance = GCR_InventoryBalance.findOrCreateBalance(boat.Id, idWarehouse, loc.Id);
    GMBLASERP__Serial_Number__c boatSerial = Factory_SerialNumber.insertSerialNumber(boat, 'Test666');
    boatSerial = [
      SELECT Id, Name, GMBLASERP__Lot__c, GMBLASERP__Product__c
      FROM GMBLASERP__Serial_Number__c
      WHERE Id = :boatSerial.Id
    ];
    Account[] accts = Factory_Account.insertSupplierAccounts(2);
    Account vendor = accts[0];
    Account shipTo = accts[1];
    AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO(vendor.Id, shipTo.Id);
    AcctSeedERP__Purchase_Order_Line__c pol = new AcctSeedERP__Purchase_Order_Line__c(
      AcctSeedERP__Purchase_Order__c = po.Id,
      AcctSeedERP__Product__c = boatSerial.GMBLASERP__Product__c,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Unit_Price__c = 1000.00
    );
    insert pol;

    AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 1000,
      GMBLASERP__Cost_Override__c = true,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Inventory_Balance__c = idBalance,
      AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
      GMBLASERP__Warehouse__c = idWarehouse,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Product__c = boatSerial.GMBLASERP__Product__c,
      GMBLASERP__Serial_Number__c = boatSerial.Id,
      GMBLASERP__Lot__c = boatSerial.GMBLASERP__Lot__c,
      AcctSeedERP__Purchase_Order_Line__c = pol.Id,
      GMBLASERP__Purchase_Order__c = po.Id
    );
    insert movement;

    GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c();
    adj.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
    adj.Department_GLV_2__c = gcConstants.idGlv2Sales;
    adj.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
    adj.GMBLASERP__Product__c = boatSerial.GMBLASERP__Product__c;
    adj.GMBLASERP__Adjustment_Type__c = 'Value';
    adj.GMBLASERP__Adjustment_Date__c = Date.today();
    insert adj;

    Test.startTest();
    map<string, string> mapString = gcInventoryAdjustment_Ext.createAdjustment(adj.Id, boatSerial.Id);
    Id idMove = mapString.get('idMove');
    GMBLASERP.gcInventoryAdjustment.disableTrigger = true;
    gcInboundInventoryMovement.disableTrigger = true;
    gcOutboundInventoryMovement.disableTrigger = true;
    gcInventoryAdjustment_Ext.adjustValue(idMove, 100);
    gcInventoryAdjustment_Ext.adjustValueIn(idMove, 100);
    Test.stopTest();
  }
}
