/**
 * Created by dave on 2022-07-25.
 */

public without sharing class TA_Lead_SetOwnerOnAccepted implements TriggerAction.BeforeUpdate {
  public void beforeUpdate(List<Lead> newList, List<Lead> oldList) {
    Map<Id, Lead> oldMap = new Map<Id, Lead>(oldList);
    for (Lead newRecord : newList) {
      Lead oldRecord = oldMap.get(newRecord.Id);
      if (oldRecord.Status == Lead_Service.NEW_STATUS && newRecord.Status != Lead_Service.NEW_STATUS) {
        newRecord.OwnerId = UserInfo.getUserId();
      }
    }
  }
}
