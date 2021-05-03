@isTest
private class gcTest_InboundInventoryMovement{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

	static testMethod void coverage_Test()
	{
    gcInboundInventoryMovement.coverage();
  }

  @isTest
  static void trigger_Test()
  {
    //AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    AcctSeed__Accounting_Settings__c accSetting = [SELECT AcctSeed__Default_Ledger__c FROM AcctSeed__Accounting_Settings__c ORDER BY CreatedDate][0];
    AcctSeed__GL_Account__c glA = [SELECT Id
                                   FROM AcctSeed__GL_Account__c
                                   LIMIT 1];
    AcctSeedERP__Warehouse__c wh = [SELECT Id FROM AcctSeedERP__Warehouse__c LIMIT 1];
    AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(
      Name = 'Test Loc',
      AcctSeedERP__Warehouse__c = wh.Id
    );
    insert loc;
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
    AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
      AcctSeedERP__Location__c = loc.Id,
      AcctSeedERP__Warehouse__c = wh.Id,
      AcctSeedERP__Product__c = part.Id
    );
    insert balance;
    AcctSeedERP__Inbound_Inventory_Movement__c movement = new AcctSeedERP__Inbound_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      AcctSeedERP__Type__c = 'Inventory Transfer',
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Credit_GL_Account__c = glA.Id,
      AcctSeedERP__Inventory_Balance__c = balance.Id,
      AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
      GMBLASERP__Warehouse__c = wh.Id
    );
    GMBLASERP.gcInboundInventoryMovement.disableTrigger = true;
    insert movement;
  }


}