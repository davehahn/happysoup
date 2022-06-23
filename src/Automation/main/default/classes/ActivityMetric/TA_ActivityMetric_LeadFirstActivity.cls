/**
 * Created by dave on 2022-06-22.
 */

public without sharing class TA_ActivityMetric_LeadFirstActivity implements TriggerAction.AfterInsert, TriggerAction.AfterUpdate {
  public void afterInsert(List<ActivityMetric> newList) {
    setLeadFirstActivity(newList, null);
  }
  public void afterUpdate(List<ActivityMetric> newList, List<ActivityMetric> oldList) {
    setLeadFirstActivity(newList, new Map<Id, ActivityMetric>(oldList));
  }

  private void setLeadFirstActivity(List<ActivityMetric> newList, Map<Id, ActivityMetric> oldMap) {
    List<Lead> leads = new List<Lead>();
    for (ActivityMetric am : newList) {
      String sObjectType = LGND_Utilities.sObjectNameFromId(am.BaseId);
      if (sObjectType == 'Lead') {
        //After Insert
        if (oldMap == null) {
          if (am.LastActivityDateTime != null) {
            leads.add(new Lead(Id = am.BaseId, First_Activity_Date__c = am.LastActivityDateTime));
          }
          continue;
        }
        if (oldMap != null) {
          ActivityMetric oldAm = oldMap.get(am.Id);
          if (oldAm.LastActivityDateTime == null && am.LastActivityDateTime != null) {
            leads.add(new Lead(Id = am.BaseId, First_Activity_Date__c = am.LastActivityDateTime));
          }
        }
      }
    }
    if (leads.size() > 0) {
      update leads;
    }
  }
}
