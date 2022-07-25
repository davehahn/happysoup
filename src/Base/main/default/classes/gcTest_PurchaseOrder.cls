@isTest
private class gcTest_PurchaseOrder {
  static testMethod void test1() {
    gcPurchaseOrder.coverage();
    gcPurchaseOrder_Actions.coverage();
    gcPurchaseOrder_Ext.coverage();
    //        gcPurchaseOrderLine.coverage();
    gcPurchaseOrder_PDF.coverage();
  }

  /*static testMethod void test2()
    {
    	update [SELECT Id FROM AcctSeedERP__Purchase_Order_Line__c WHERE AcctSeedERP__Purchase_Order__r.AcctSeedERP__Status__c = 'Open' limit 1];
    }*/
}
