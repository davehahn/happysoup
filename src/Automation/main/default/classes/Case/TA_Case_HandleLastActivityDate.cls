/**
 * Created by dave on 2022-03-28.
 */

public without sharing class TA_Case_HandleLastActivityDate implements TriggerAction.BeforeUpdate {
  public void beforeUpdate(List<Case> newList, List<Case> oldList) {
    for (Case c : newList) {
      if (c.Last_Activity_Date__c != null && c.First_Activity_date__c == null) {
        c.First_Activity_Date__c = c.Last_Activity_date__c;
      }
    }
  }
}
