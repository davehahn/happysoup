@isTest
private class gcTest_User {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static testMethod void coverage_Test() {
    gcUser.coverage();
  }

  static testMethod void trigger_Test() {
    User u = Factory_User.buildUser('Test-Fname', 'Test-Lname', 'System Administrator');
    insert u;
  }
}
