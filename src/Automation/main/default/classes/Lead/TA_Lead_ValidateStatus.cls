/**
 * Created by dave on 2022-07-19.
 */

public without sharing class TA_Lead_ValidateStatus implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate {
  public void beforeInsert(List<Lead> newList) {
    validateStatus(newList);
  }
  public void beforeUpdate(List<Lead> newList, List<Lead> oldList) {
    validateStatus(newList);
  }

  private void validateStatus(List<Lead> newList) {
    for (Lead l : newList) {
      System.debug(l);
      if (LGND_Utilities.sObjectNameFromId(l.OwnerId) == 'Group' && l.Status != Lead_Service.NEW_STATUS) {
        l.addError('Status', 'A Lead owned by a Queue can only have a Status of \"' + Lead_Service.NEW_STATUS + '\"');
      }
      if (LGND_Utilities.sObjectNameFromId(l.OwnerId) == 'User' && l.Status == Lead_Service.NEW_STATUS) {
        l.addError('Status','Only Leads owned by a Queue can have a Status of \"' + Lead_Service.NEW_STATUS + '\"');
      }
    }
  }
}
