@isTest
private class gcTest_AccountPayable{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

	static testMethod void coverage_Test()
	{
    gcAccountPayable.coverage();
    gcAccountPayable_Override.coverage();
    gcAccountPayable_Clone.coverage();
  }

  @isTest
  static void trigger_Test()
  {
    Factory_AccountPayable.insertAccountPayable(0);
  }


}