public inherited sharing class TA_SalesOrder_TaxSetUp implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate {
  public void beforeInsert(List<AcctSeedERP__Sales_Order__c> newList) {
    SalesOrder_Service.refreshStatics(newList);
    SalesOrder_Service.setTaxVariablesBI(newList);
  }
  public void beforeUpdate(List<AcctSeedERP__Sales_Order__c> newList, List<AcctSeedERP__Sales_Order__c> oldList) {
    Map<Id, AcctSeedERP__Sales_Order__c> oldMap = new Map<Id, AcctSeedERP__Sales_Order__c>(oldList);
    SalesOrder_Service.refreshStatics(newList);
    SalesOrder_Service.setTaxVariablesBU(newList, oldMap);
  }
}
