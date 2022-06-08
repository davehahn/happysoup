public class TA_SalesOrder_CashReceipt_AI implements TriggerAction.AfterInsert
{
    public void afterInsert(List<AcctSeedERP__Sales_Order__c> newList) {
        
        Map<Id, AcctSeedERP__Sales_Order__c> newMap = new Map<Id, AcctSeedERP__Sales_Order__c> (newList);
        //SalesOrder_Service.generateCashReceiptFuture(newMap.keySet());
        // SalesOrder_Service.generateCashReceipt(newList);
    }

}