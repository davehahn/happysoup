@isTest
private class SerialNumberHistorySearch_Test{

  static Map<String, AcctSeedERP__Inventory_Balance__c> inventoryBalances;
  static AcctSeedERP__Warehouse__c wh;
  static AcctSeedERP__Location__c loc;
  static Product2 part;
  static GMBLASERP__Serial_Number__c ser;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void createData()
  {
    inventoryBalances = new Map<String, AcctSeedERP__Inventory_Balance__c>();
    ser = Factory_SerialNumber.insertFullSerial('Boat','Pontoon','0987654321');
    wh = [SELECT Id, Name FROM AcctSeedERP__Warehouse__c LIMIT 1];
    loc = new AcctSeedERP__Location__c(
      Name = 'Test Loc',
      AcctSeedERP__Warehouse__c = wh.Id
    );
    insert loc;
    part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    inventoryBalances.put('part', new AcctSeedERP__Inventory_Balance__c(
      AcctSeedERP__Location__c = loc.Id,
      AcctSeedERP__Warehouse__c = wh.Id,
      AcctSeedERP__Product__c = part.Id
    ));

    inventoryBalances.put('boat', new AcctSeedERP__Inventory_Balance__c(
      AcctSeedERP__Location__c = loc.Id,
      AcctSeedERP__Warehouse__c = wh.Id,
      AcctSeedERP__Product__c = ser.GMBLASERP__Product__c
    ));
    insert inventoryBalances.values();
  }

  static testMethod void class_Test1()
  {
    createData();

    Account[] accts = Factory_Account.insertSupplierAccounts(2);
    AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO( accts[0].Id, accts[1].Id );
    AcctSeedERP__Purchase_Order_Line__c pol = new AcctSeedERP__Purchase_Order_Line__c(
      AcctSeedERP__Purchase_Order__c = po.Id,
      AcctSeedERP__Product__c = part.Id,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Unit_Price__c = 10.00
    );
    insert pol;

    AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Inventory_Balance__c = inventoryBalances.get('part').Id,
      AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
      GMBLASERP__Warehouse__c = wh.Id,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Product__c = part.Id,
      AcctSeedERP__Purchase_Order_Line__c = pol.Id
    );
    gcPurchaseOrderInventoryMovement.disableTrigger = true;
    insert movement;

    AcctSeedERP__Outbound_Inventory_Movement__c movementOut = new AcctSeedERP__Outbound_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      AcctSeedERP__Type__c = 'Accounting',
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Debit_GL_Account__c = gcConstants.idGlClearingARAP,
      AcctSeedERP__Inventory_Balance__c = inventoryBalances.get('part').Id,
      AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
      GMBLASERP__Warehouse__c = wh.Id,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Product__c = part.Id
    );
    gcOutboundInventoryMovement.disableTrigger = true;
    insert movementOut;


    Account cust = Factory_Account.insertFullPersonAccount('TestFname', 'TestLname');
    Boolean orig = gcProject.disableTrigger;
    Boolean origTask = gcProjectTask.ignoreCommissions;
    gcProject.disableTrigger = true;
    gcProjectTask.ignoreCommissions = true;
    AcctSeed__Project__c erp = Factory_ERPOrder.insertRetailBoatSale( cust, wh, DateTime.now(), ser);
    gcProject.disableTrigger = orig;
    gcProjectTask.ignoreCommissions = origTask;
    AcctSeed__Project_Task__c erpTask = [SELECT Id FROM AcctSeed__Project_Task__c WHERE AcctSeed__Project__c =:erp.Id LIMIT 1][0];

    Product2 prod = [SELECT Id, AcctSeed__Inventory_GL_Account__c FROM Product2 WHERE Id=:ser.GMBLASERP__Product__c LIMIT 1];
    AcctSeedERP__Material__c matl = [SELECT Id, AcctSeedERP__Product__c FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c =:erp.Id AND GMBLASERP__Serial_Number__c =:ser.Id][0];

    AcctSeedERP__Inbound_Inventory_Movement__c inmove = new AcctSeedERP__Inbound_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 100000,
      AcctSeedERP__Type__c = 'Accounting',
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Credit_GL_Account__c = prod.AcctSeed__Inventory_GL_Account__c,
      AcctSeedERP__Inventory_Balance__c = inventoryBalances.get('boat').Id,
      AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
      GMBLASERP__Warehouse__c = wh.Id,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
      GMBLASERP__Serial_Number__c = ser.Id
    );
    gcInboundInventoryMovement.disableTrigger = true;
    insert inmove;
    ////
    AcctSeedERP__Manufacturing_Inventory_Movement__c mfgmovement = new AcctSeedERP__Manufacturing_Inventory_Movement__c(
      AcctSeedERP__Material__c = matl.Id,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Inventory_Balance__c = inventoryBalances.get('boat').Id,
      AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
      GMBLASERP__Serial_Number__c = ser.Id,
      AcctSeedERP__Unit_Cost__c = 0,
      GMBLASERP__Project__c = erp.Id,
      GMBLASERP__Project_Task__c = erpTask.Id
    );
    gcManufacturingInventoryMovement.disableTrigger = true;
    insert mfgmovement;

    Test.startTest();
    SerialNumberHistorySearchController_ar.listWarehouses();
    SerialNumberHistorySearchController_ar.checkCanSeeGLAmount();
    Map<String,String> mapFilter = new Map<String,String>{'idFilter'=>Part.Id,'idProduct'=>part.Id};
    SerialNumberHistorySearchController_ar.retrieveHistoryDetails(mapFilter);
    mapFilter.clear();
    mapFilter = new Map<String,String>{'idFilter'=>ser.Id,'idSerial'=>ser.Id};
    SerialNumberHistorySearchController_ar.retrieveHistoryDetails(mapFilter);
    Test.stopTest();
  }
}