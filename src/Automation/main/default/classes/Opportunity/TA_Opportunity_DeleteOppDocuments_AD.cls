/**
 * Created by dhavalmacbook on 27/01/22.
 */

public without sharing class TA_Opportunity_DeleteOppDocuments_AD implements TriggerAction.AfterDelete {
  public void afterDelete(List<Opportunity> oldList) {
    Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>(oldList);
    Opportunity_Service.deleteOpportunityDocuments(oldMap.keySet());
  }
}
