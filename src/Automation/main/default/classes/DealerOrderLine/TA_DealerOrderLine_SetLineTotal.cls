/**
 * Created by dhavalmacbook on 20/01/22.
 */

public inherited sharing class TA_DealerOrderLine_SetLineTotal implements TriggerAction.BeforeInsert{

    public void beforeInsert(List<Dealer_Order_Line__c> newList) {
        DealerOrderLine_Service.setLineTotal(newList);
    }
}