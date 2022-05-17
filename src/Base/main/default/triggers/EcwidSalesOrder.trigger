/**
 * Created by Legend on 16/5/22.
 */

trigger EcwidSalesOrder on Ecwid_Sales_Order__e (after insert)
{
    //new Lead_TriggerHandler().run();
    //Checking OLD Style
    System.debug('Hello it is a pip');
    Set<Id> setIdSO = new Set<Id>();
    for(Ecwid_Sales_Order__e eso : Trigger.new){
        if(eso.Sales_Order_Id__c != null){
            setIdSO.add(eso.Sales_Order_Id__c);
        }
    }
    System.debug('setIdSO : '+setIdSO);
    if(!setIdSO.isEmpty()) {
        List<AcctSeedERP__Sales_Order__c> lstSalesOrderForCashReceipt = [Select Id,AcctSeedERP__Customer__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,AcctSeedERP__Total__c,Name from AcctSeedERP__Sales_Order__c where Id IN:setIdSO];
        SalesOrder_Service.generateCashReceipt(lstSalesOrderForCashReceipt);
    }
}