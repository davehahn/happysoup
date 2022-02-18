/**
 * Created by dhavalmacbook on 27/01/22.
 */

public inherited sharing class TA_Opportunity_UpdateTax_BU implements TriggerAction.BeforeUpdate {

    public void beforeUpdate(List<Opportunity> newList, List<Opportunity> oldList) {
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity> (oldList);
        for( Opportunity opp : newList )
        {
            if( opp.Probability == 0 )
                opp.Pickup_Location__c = null;

            if( opp.Pickup_Location__c == null )
                opp.Delivery_Date__c = null;

            Opportunity_Service.updateTaxes( opp, oldMap.get(opp.Id) );
        }
    }
}