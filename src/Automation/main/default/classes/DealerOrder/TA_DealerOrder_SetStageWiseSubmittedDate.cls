
public without sharing class TA_DealerOrder_SetStageWiseSubmittedDate implements TriggerAction.BeforeUpdate{



    public void beforeUpdate(List<Dealer_Order__c> newList, List<Dealer_Order__c> oldList) {

        Map<Id, Dealer_Order__c> oldMap = new Map<Id, Dealer_Order__c> (oldList);
        DealerOrder_Service.SetStageWiseSubmittedDate(newList,oldMap);

    }
}