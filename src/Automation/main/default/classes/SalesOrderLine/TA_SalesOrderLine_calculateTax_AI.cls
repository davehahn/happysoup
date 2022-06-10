/**
 * Created by Legend on 11/5/22.
 */

public class TA_SalesOrderLine_calculateTax_AI implements  TriggerAction.AfterInsert{
    public void afterInsert( List<AcctSeedERP__Sales_Order_Line__c> newList)
    {
        set<Id> setId = new set<Id>();
        for(AcctSeedERP__Sales_Order_Line__c sol : newList){
            setId.add(sol.AcctSeedERP__Sales_Order__c);
        }
        SalesOrderLine_Service.updateSalesTax(setId);
    }
}