/**
 * Created by Pooja on 2022-01-01.
 */

public inherited sharing class TA_Transaction_Legacy implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate, TriggerAction.BeforeDelete, TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {
  public void beforeInsert(List<AcctSeed__Transaction__c> newList) {
    if (!gcTransaction.disableTrigger) {
      gcTransaction.triggerHandler(null, null, newList, true, true, false, false);
    }
  }

  public void afterInsert(List<AcctSeed__Transaction__c> newList) {
    if (!gcTransaction.disableTrigger) {
      Map<Id, AcctSeed__Transaction__c> newMap = new Map<Id, AcctSeed__Transaction__c>(newList);
      gcTransaction.triggerHandler(null, newMap, newList, false, true, false, false);
    }
  }

  public void beforeUpdate(List<AcctSeed__Transaction__c> newList, List<AcctSeed__Transaction__c> oldList) {
    if (!gcTransaction.disableTrigger) {
      Map<Id, AcctSeed__Transaction__c> newMap = new Map<Id, AcctSeed__Transaction__c>(newList);
      Map<Id, AcctSeed__Transaction__c> oldMap = new Map<Id, AcctSeed__Transaction__c>(oldList);
      gcTransaction.triggerHandler(oldMap, newMap, newList, true, false, true, false);
    }
  }

  public void afterUpdate(List<AcctSeed__Transaction__c> newList, List<AcctSeed__Transaction__c> oldList) {
    if (!gcTransaction.disableTrigger) {
      Map<Id, AcctSeed__Transaction__c> newMap = new Map<Id, AcctSeed__Transaction__c>(newList);
      Map<Id, AcctSeed__Transaction__c> oldMap = new Map<Id, AcctSeed__Transaction__c>(oldList);
      gcTransaction.triggerHandler(oldMap, newMap, newList, false, false, true, false);
    }
  }

  public void beforeDelete(List<AcctSeed__Transaction__c> oldList) {
    if (!gcTransaction.disableTrigger) {
      Map<Id, AcctSeed__Transaction__c> oldMap = new Map<Id, AcctSeed__Transaction__c>(oldList);
      gcTransaction.triggerHandler(oldMap, null, null, true, false, false, true);
    }
  }

  public void afterDelete(List<AcctSeed__Transaction__c> oldList) {
    if (!gcTransaction.disableTrigger) {
      Map<Id, AcctSeed__Transaction__c> oldMap = new Map<Id, AcctSeed__Transaction__c>(oldList);
      gcTransaction.triggerHandler(oldMap, null, null, false, false, false, true);
    }
  }
}
