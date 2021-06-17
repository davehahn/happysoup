@isTest
private class gcTest_ProductPart{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

	static testMethod void coverage_Test()
	{
    //gcProductPart.coverage();
  }

  static testMethod void trigger_Test()
  {
    Product2[] parts = Factory_Product.buildNonSerializedProducts('Part', 'Electronics', 2);
    insert parts;
  	insert new AcctSeed__Product_Part__c(
      AcctSeed__Product__c = parts[0].Id,
      AcctSeed__Product_Part__c = parts[1].Id,
      AcctSeed__Quantity__c = 1
    );
  }
}