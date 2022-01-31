/**
 * Created by dhavalmacbook on 20/01/22.
 */

public inherited sharing class TA_DealerOrderLine_HandlePartnerProg_AD implements TriggerAction.AfterDelete{
    public void afterDelete(List<Dealer_Order_Line__c> oldList) {
        Set<Id> motorRequestIds = new Set<Id>();
        List<Dealer_Order_Line__c> dols = (List<Dealer_Order_Line__c>) Trigger.oldMap.values();
        DealerOrderLine_Service.handlePartnerProgram( dols );
    }

}