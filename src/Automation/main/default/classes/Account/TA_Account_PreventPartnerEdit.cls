/**
 * Created by dave on 2021-12-22. Build
 */

public without sharing class TA_Account_PreventPartnerEdit implements TriggerAction.BeforeUpdate {
  public void beforeUpdate(List<Account> newList, List<Account> oldList) {
    User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
    Id dealerRtId = new Application_RecordType().getAccountRecordTypes().getDealerId();
    if (user.AccountId != null) {
      for (Account a : newList) {
        if (a.Id != user.AccountId && a.RecordTypeId == dealerRtId) {
          a.addError('You are not allowed to edit another Partners information');
        }
      }
    }
  }
}
