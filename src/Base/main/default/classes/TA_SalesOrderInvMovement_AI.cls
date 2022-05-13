/**
 * Created by Legend on 12/5/22.
 */

public inherited sharing class TA_SalesOrderInvMovement_AI implements  TriggerAction.AfterInsert
{
    public void afterInsert( List<AcctSeedERP__Sales_Order_Line__c> newList) {
        set<Id> setId = new set<Id>();
        for (AcctSeedERP__Sales_Order_Line__c b : newList) {
            setId.add(b.AcctSeedERP__Sales_Order__c);
        }
        // Create JE if necessary in the future
        SalesOrderInventoryMovement_Service.createJEFuture(setId);
    }
}