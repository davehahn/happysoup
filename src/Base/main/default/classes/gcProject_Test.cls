@isTest(SeeAllData=true)
private class gcProject_Test {
  static testMethod void test1() {
    gcProject.coverage();
  }

  /*static testMethod void test2()
    {
        update [SELECT Id FROM AcctSeed__Project__c ORDER BY CreatedDate DESC LIMIT 1];
    }*/
}
