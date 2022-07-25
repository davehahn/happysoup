@isTest(SeeAllData=true)
private class gcTest_InventoryBalance {
  static testMethod void test1() {
    gcInventoryBalance.coverage();
  }
  /*static testMethod void test2()
    {
        update [SELECT Id FROM AcctSeedERP__Inventory_Balance__c ORDER BY CreatedDate DESC LIMIT 1];
    }*/
}
