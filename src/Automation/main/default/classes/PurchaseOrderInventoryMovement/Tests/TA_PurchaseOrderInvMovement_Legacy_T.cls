@isTest
public class TA_PurchaseOrderInvMovement_Legacy_T {
  static List<AcctSeedERP__Purchase_Order_Inventory_Movement__c> poMovements;
  private static List<AcctSeedERP__Purchase_Order_Inventory_Movement__c> getData() {
    return Database.query(LGND_Utilities.getAllFieldsSOQL('AcctSeedERP__Purchase_Order_Inventory_Movement__c'));
  }
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    AcctSeed__GL_Account__c glA = [SELECT Id FROM AcctSeed__GL_Account__c LIMIT 1];
    AcctSeedERP__Warehouse__c wh = [SELECT Id FROM AcctSeedERP__Warehouse__c LIMIT 1];
    AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(Name = 'Test Loc', AcctSeedERP__Warehouse__c = wh.Id);
    insert loc;
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
    AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
      AcctSeedERP__Location__c = loc.Id,
      AcctSeedERP__Warehouse__c = wh.Id,
      AcctSeedERP__Product__c = part.Id
    );
    // Required for Hibiscus;
    //balance.AcctSeedERP__Ledger__c = ledger.Id;
    insert balance;

    Account[] accts = Factory_Account.insertSupplierAccounts(2);
    Account vendor = accts[0];
    Account shipTo = accts[1];
    AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO(vendor.Id, shipTo.Id);
    System.debug([SELECT Id, AcctSeedERP__Vendor_Country__c FROM AcctSeedERP__Purchase_Order__c WHERE Id = :po.Id]);
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
      AcctSeedERP__Inventory_Balance__c = balance.Id,
      AcctSeedERP__Ledger__c = ledger.Id,
      GMBLASERP__Warehouse__c = wh.Id,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Product__c = part.Id,
      AcctSeedERP__Purchase_Order_Line__c = pol.Id,
      GMBLASERP__Purchase_Order__c = po.Id
    );
    GMBLASERP.gcPurchaseOrderInventoryMovement.disableTrigger = true;
    insert movement;
  }

  @IsTest
  static void beforeInsertTest() {
    Test.startTest();
    poMovements = getData();
    new TA_PurchaseOrderInventoryMovement_Legacy().beforeInsert(poMovements);
    Test.stopTest();
  }
  @IsTest
  static void afterInsertTest() {
    Test.startTest();
    new TA_PurchaseOrderInventoryMovement_Legacy().afterInsert(getData());
    Test.stopTest();
  }
  @IsTest
  static void afterUpdateTest() {
    Test.startTest();
    poMovements = getData();
    AcctSeedERP__Purchase_Order_Inventory_Movement__c movementClone = poMovements[0].clone(true, true, true, true);
    new TA_PurchaseOrderInventoryMovement_Legacy()
      .afterUpdate(
        new List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>{ poMovements[0] },
        new List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>{ movementClone }
      );
    Test.stopTest();
  }
  @IsTest
  static void beforeUpdateTest() {
    Test.startTest();
    poMovements = getData();
    AcctSeedERP__Purchase_Order_Inventory_Movement__c movementClone = poMovements[0].clone(true, true, true, true);
    new TA_PurchaseOrderInventoryMovement_Legacy()
      .beforeUpdate(
        new List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>{ poMovements[0] },
        new List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>{ movementClone }
      );

    Test.stopTest();
  }
  @IsTest
  static void beforeDeleteTest() {
    Test.startTest();
    new TA_PurchaseOrderInventoryMovement_Legacy().beforeDelete(getData());
    Test.stopTest();
  }
  @IsTest
  static void afterDeleteTest() {
    Test.startTest();
    new TA_PurchaseOrderInventoryMovement_Legacy().afterDelete(getData());
    Test.stopTest();
  }
}
