@isTest
private class gcPurchaseOrderInventoryMovement_Test{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static testMethod void coverage_Test()
  {
    gcPurchaseOrderInventoryMovement.coverage();
  }

  static testMethod void trigger_Test()
  {
    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    AcctSeed__GL_Account__c glA = [SELECT Id
                                   FROM AcctSeed__GL_Account__c
                                   LIMIT 1];
    AcctSeedERP__Warehouse__c wh = [SELECT Id FROM AcctSeedERP__Warehouse__c LIMIT 1];
    AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(
      Name = 'Test Loc',
      AcctSeedERP__Warehouse__c = wh.Id
    );
    insert loc;
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
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
    AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO( vendor.Id, shipTo.Id );
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
    //gcPurchaseOrderInventoryMovement.disableTrigger = true;
    insert movement;
  }
}