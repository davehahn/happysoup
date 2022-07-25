@isTest(SeeAllData=true)
private class gcTest_Material {
  static testMethod void test1() {
    gcMaterial.coverage();
    //arMaterial_PACKAGE.coverage();
  }

  /*static testMethod void test2()
    {
    	update [SELECT Id FROM AcctSeedERP__Material__c ORDER BY CreatedDate DESC LIMIT 1];
    }*/
}
