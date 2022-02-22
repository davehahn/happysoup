/**
 * Created by dhavalmacbook on 27/01/22.
 */

public inherited sharing class TA_OppLineItem_UpdateOpp_AD implements TriggerAction.AfterDelete{

    public void afterDelete(List<OpportunityLineItem> oldList) {
        OpportunityLineItem_Service.updateOppotuities(oldList);
    }
}