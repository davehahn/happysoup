/**
 * Created by dhavalmacbook on 20/01/22.
 */

public inherited sharing class TA_DealerOrderLine_HandlePartnerPro implements TriggerAction.AfterInsert{


    public void afterInsert(List<Dealer_Order_Line__c> newList) {

        DealerOrderLine_Service.handlePartnerProgram (newList);
    }
}