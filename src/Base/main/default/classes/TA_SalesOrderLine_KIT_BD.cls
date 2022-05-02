/**
 * Created by Legend on 21/4/22.
 */

public inherited sharing class  TA_SalesOrderLine_KIT_BD implements TriggerAction.BeforeDelete{

    public void beforeDelete(List<AcctSeedERP__Sales_Order_Line__c> oldList) {

        Map<Id, AcctSeedERP__Sales_Order_Line__c> oldMap = new Map<Id, AcctSeedERP__Sales_Order_Line__c> (oldList);
        for(AcctSeedERP__Sales_Order_Line__c sol : oldMap.values())
        {
            if(sol.Sales_Order_Line__c != null && !oldMap.containsKey(sol.Sales_Order_Line__c) )
                sol.addError('Kit Parts cannot be deleted directly. Deleting Kit would aumatically delete Kit Parts.');
        }
        SalesOrderLine_Service.cascadeDeleteKitMaterial(oldMap.keySet());
    }
}