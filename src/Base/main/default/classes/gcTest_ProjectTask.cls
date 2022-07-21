@isTest(SeeAllData=true)
private class gcTest_ProjectTask {
  static testMethod void test1() {
    gcProjectTask.coverage();
  }

  /*static testMethod void test2()
    {
		Boolean boolOld = gcProjectTask.disableTrigger;
        gcProjectTask.disableTrigger = true;
        update [SELECT Id FROM AcctSeed__Project_Task__c ORDER BY CreatedDate LIMIT 1];
        gcProjectTask.disableTrigger = boolOld;        
    }*/
}
