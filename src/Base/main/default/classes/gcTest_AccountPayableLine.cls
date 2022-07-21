@isTest
private class gcTest_AccountPayableLine {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static testMethod void coverage_Test() {
    gcAccountPayableLine.coverage();
  }

  static testMethod void trigger_Test() {
    Factory_AccountPayable.insertAccountPayable(1);
  }
}
