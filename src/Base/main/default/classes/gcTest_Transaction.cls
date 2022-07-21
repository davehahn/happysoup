@isTest(SeeAllData=true)
private class gcTest_Transaction {
  static testMethod void test1() {
    gcTransaction.coverage();
  }

  static testMethod void test2() {
    update [SELECT Id FROM AcctSeed__Transaction__c ORDER BY LastModifiedDate DESC LIMIT 1];
  }
}
