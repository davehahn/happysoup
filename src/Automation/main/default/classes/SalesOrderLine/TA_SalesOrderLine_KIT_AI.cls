/**
 * Created by Legend on 21/4/22.
 */
public inherited sharing class TA_SalesOrderLine_KIT_AI implements  TriggerAction.AfterInsert
{

    public void afterInsert( List<AcctSeedERP__Sales_Order_Line__c> newList)
    {
        set<Id> setId = new set<Id>();
        for(AcctSeedERP__Sales_Order_Line__c sol : newList){
            setId.add(sol.Id);
        }
        SalesOrderLine_Service.insertKitParts(setId);
    }

}