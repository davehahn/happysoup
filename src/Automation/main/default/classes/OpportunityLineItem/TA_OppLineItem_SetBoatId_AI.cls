/**
 * Created by dhavalmacbook on 27/01/22.
 */

public without sharing class TA_OppLineItem_SetBoatId_AI implements TriggerAction.AfterInsert{

    public void afterInsert(List<OpportunityLineItem> newList) {
        Map<Id, OpportunityLineItem> newMap = new Map<Id, OpportunityLineItem> (newList);
        
        OpportunityLineItem_Service.setBoatId(newMap.keySet());
    }
}