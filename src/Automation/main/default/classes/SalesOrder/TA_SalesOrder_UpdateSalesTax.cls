public inherited sharing class TA_SalesOrder_UpdateSalesTax implements TriggerAction.AfterUpdate {
  public void afterUpdate(List<AcctSeedERP__Sales_Order__c> newList, List<AcctSeedERP__Sales_Order__c> oldList) {
    Map<Id, AcctSeedERP__Sales_Order__c> oldMap = new Map<Id, AcctSeedERP__Sales_Order__c>(oldList);
    SalesOrder_Service.updateSalesTax(newList, oldMap);
  }
}
