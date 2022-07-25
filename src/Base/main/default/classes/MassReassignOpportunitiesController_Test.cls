@isTest
private class MassReassignOpportunitiesController_Test {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  public static testMethod void testReassign() {
    Account testAccount = new Account();
    testAccount.Name = 'test';
    insert testAccount;

    List<Account> a = [SELECT Id FROM Account WHERE Name = 'test' LIMIT 1];
    System.assertEquals(testAccount.Id, a[0].Id);

    Opportunity testOpty = new Opportunity();
    testOpty.StageName = 'Quoting';
    testOpty.CloseDate = System.today() + 1;
    testOpty.AccountId = testAccount.Id;
    testOpty.Name = 'testOpty';
    testOpty.Type = 'testType';
    insert testOpty;
    MassReassignOpportunitiesController controller = new MassReassignOpportunitiesController();
    controller.refreshOptyList();
    controller.filterId = controller.listviewoptions[1].getValue();
    controller.refreshOptyList();
    controller.searchRecord.stageName = 'Quoting';
    controller.helperRecord.ClosedDate_From__c = System.today();
    controller.helperRecord.ClosedDate_To__c = System.today() + 12;
    controller.helperRecord.From__c = System.today();
    controller.helperRecord.To__c = System.today() + 12;
    controller.searchRecord.Type = 'testType';
    controller.refreshOptyListBySearch();

    System.assert(controller.optyList.size() > 0);

    controller.optyList[0].selected = true;
    controller.helperRecord.Assign_to__c = UserInfo.getUserId();
    controller.Assign();
  }
}
