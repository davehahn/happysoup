/**
 * Created by dave on 2022-06-21. Different comments
 */

public without sharing class TA_Lead_AcceptedTimeStamp implements TriggerAction.BeforeUpdate {
  public void beforeUpdate(List<Lead> newList, List<Lead> oldList) {
    Map<Id, Lead> oldMap = new Map<Id, Lead>(oldList);
    for (Lead newLead : newList) {
      Lead oldLead = oldMap.get(newLead.Id);
      //Now Accepted
      if (
        LGND_Utilities.sObjectNameFromId(oldLead.OwnerId) == 'Group' &&
        LGND_Utilities.sObjectNameFromId(newLead.OwnerId) == 'User'
      ) {
        newLead.Accepted_On__c = DateTime.now();
        newLead.Status = Lead_Service.ACCEPTED_STATUS;
      }
      //Unaccepted
      if (
        LGND_Utilities.sObjectNameFromId(oldLead.OwnerId) == 'User' &&
        LGND_Utilities.sObjectNameFromId(newLead.OwnerId) == 'Group'
      ) {
        newLead.Accepted_On__c = null;
        newLead.Status = Lead_Service.NEW_STATUS;
      }
    }
  }
}
