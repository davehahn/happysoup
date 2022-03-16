/**
 * Created by dhavalmacbook on 19/01/22.
 */

public without sharing class TA_DealerOrder_DeleteERPs implements TriggerAction.BeforeDelete{

    public void beforeDelete(List<Dealer_Order__c> oldList) {

        Map<Id, Dealer_Order__c> oldMap = new Map<Id, Dealer_Order__c> (oldList);
        DealerOrder_Service.deleteERPs(oldMap);
    }
}