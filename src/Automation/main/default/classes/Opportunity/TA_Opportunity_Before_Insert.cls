/**
 * Created by dhavalmacbook on 27/01/22.
 */

public without sharing class TA_Opportunity_Before_Insert implements TriggerAction.BeforeInsert{

    public void beforeInsert(List<Opportunity> newList) {
		Opportunity_Service.beforeInsert(newList);
        
    }
}