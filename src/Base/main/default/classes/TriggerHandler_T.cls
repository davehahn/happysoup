/**
 * Created by dave on 2019-10-07.
 */

@isTest
private class TriggerHandler_T {

  static Account testAccount;

  @isTest static void test_method_one() {
    Id accountBusinessRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND IsActive = true AND DeveloperName LIKE '%business%'][0].Id;
    testAccount = new Account(
      Name = 'Test Account',
      RecordTypeId = accountBusinessRecordType);
    insert testAccount;
    update testAccount;
    delete testAccount;
    Database.undelete(testAccount.Id);
  }
  @isTest static void test_method_two() {
    try {
      TriggerHandler handler = new TriggerHandler();
      handler.run();
    }catch(exception Ex){}
  }
  @isTest static void test_method_three() {
    TriggerHandler.AddProcessRun('test', '003o0000005C74S');
    system.assert(TriggerHandler.DidProcessRan('test', '003o0000005C74S'));
  }
}