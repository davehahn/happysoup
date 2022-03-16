/**
 * Created by dave on 2021-12-22.
 */

public without sharing class TA_Account_Legacy implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate, TriggerAction.BeforeDelete, TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {
  public void beforeInsert(List<Account> newList) {
    if (!gcAccount.disableTrigger) {
      gcAccount.triggerHandler(null, null, newList, true, true, false, false);
    }
  }

  public void afterInsert(List<Account> newList) {
    if (!gcAccount.disableTrigger) {
      Map<Id, Account> newMap = new Map<Id, Account>(newList);
      gcAccount.triggerHandler(null, newMap, newList, false, true, false, false);
    }
  }

  public void beforeUpdate(List<Account> newList, List<Account> oldList) {
    if (!gcAccount.disableTrigger) {
      Map<Id, Account> newMap = new Map<Id, Account>(newList);
      Map<Id, Account> oldMap = new Map<Id, Account>(oldList);
      gcAccount.triggerHandler(oldMap, newMap, newList, true, false, true, false);
    }
  }

  public void afterUpdate(List<Account> newList, List<Account> oldList) {
    if (!gcAccount.disableTrigger) {
      Map<Id, Account> newMap = new Map<Id, Account>(newList);
      Map<Id, Account> oldMap = new Map<Id, Account>(oldList);
      gcAccount.triggerHandler(oldMap, newMap, newList, false, false, true, false);
    }
  }

  public void beforeDelete(List<Account> oldList) {
    if (!gcAccount.disableTrigger) {
      Map<Id, Account> oldMap = new Map<Id, Account>(oldList);
      gcAccount.triggerHandler(oldMap, null, null, true, false, false, true);
    }
  }

  public void afterDelete(List<Account> oldList) {
    if (!gcAccount.disableTrigger) {
      Map<Id, Account> oldMap = new Map<Id, Account>(oldList);
      gcAccount.triggerHandler(oldMap, null, null, false, false, false, true);
    }
  }
}
