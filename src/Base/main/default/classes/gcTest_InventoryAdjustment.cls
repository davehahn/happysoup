@isTest
private class gcTest_InventoryAdjustment{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

	static testMethod void coverage_Test()
	{
    gcInventoryAdjustment.coverage();
  }

  static testMethod void trigger_Test()
  {
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
    AcctSeedERP__Warehouse__c wh = [SELECT Id FROM AcctSeedERP__Warehouse__c LIMIT 1];
    AcctSeed__GL_Account__c glA = [SELECT Id
                                   FROM AcctSeed__GL_Account__c
                                   LIMIT 1];
    insert new GMBLASERP__Inventory_Adjustment__c(
      Description__c = 'Test run',
      GMBLASERP__Adjustment_Type__c = 'Quantity',
      GMBLASERP__Adjustment_Date__c = Date.today(),
      GMBLASERP__Product__c = part.Id,
      GMBLASERP__Warehouse__c = wh.Id,
      GMBLASERP__GL_Account__c = glA.Id
    );
  }
}