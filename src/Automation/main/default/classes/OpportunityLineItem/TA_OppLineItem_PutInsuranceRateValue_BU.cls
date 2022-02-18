/**
 * Created by dhavalmacbook on 27/01/22.
 */

public inherited sharing class TA_OppLineItem_PutInsuranceRateValue_BU implements TriggerAction.BeforeUpdate{

    public void beforeUpdate(List<OpportunityLineItem> newList, List<OpportunityLineItem> oldList) {
        OpportunityLineItem_Service.putInsuranceRateValueOnLineItem(newList);
    }
}