/**
 * Created by Pooja on 2022-01-01.
 */

public without sharing class TA_Project_Legacy implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate, TriggerAction.BeforeDelete, TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {
  public void beforeInsert(List<AcctSeed__Project__c> newList) {
    if (Test.isRunningTest()) {
      for (AcctSeed__Project__c p : newList) {
        p.IsForUnitTest__c = true;
      }
    }
    if (!gcProject.disableTrigger) {
      gcProject.triggerHandler(null, null, newList, true, true, false, false);
    }
  }

  public void afterInsert(List<AcctSeed__Project__c> newList) {
    if (!gcProject.disableTrigger) {
      Map<Id, AcctSeed__Project__c> newMap = new Map<Id, AcctSeed__Project__c>(newList);
      gcProject.triggerHandler(null, newMap, newList, false, true, false, false);
    }
  }

  public void beforeUpdate(List<AcctSeed__Project__c> newList, List<AcctSeed__Project__c> oldList) {
    if (!gcProject.disableTrigger) {
      Map<Id, AcctSeed__Project__c> newMap = new Map<Id, AcctSeed__Project__c>(newList);
      Map<Id, AcctSeed__Project__c> oldMap = new Map<Id, AcctSeed__Project__c>(oldList);
      gcProject.triggerHandler(oldMap, newMap, newList, true, false, true, false);
    }
  }

  public void afterUpdate(List<AcctSeed__Project__c> newList, List<AcctSeed__Project__c> oldList) {
    if (!gcProject.disableTrigger) {
      Map<Id, AcctSeed__Project__c> newMap = new Map<Id, AcctSeed__Project__c>(newList);
      Map<Id, AcctSeed__Project__c> oldMap = new Map<Id, AcctSeed__Project__c>(oldList);
      gcProject.triggerHandler(oldMap, newMap, newList, false, false, true, false);
    }
  }

  public void beforeDelete(List<AcctSeed__Project__c> oldList) {
    if (!gcProject.disableTrigger) {
      Map<Id, AcctSeed__Project__c> oldMap = new Map<Id, AcctSeed__Project__c>(oldList);
      gcProject.triggerHandler(oldMap, null, null, true, false, false, true);
    }
  }

  public void afterDelete(List<AcctSeed__Project__c> oldList) {
    if (!gcProject.disableTrigger) {
      Map<Id, AcctSeed__Project__c> oldMap = new Map<Id, AcctSeed__Project__c>(oldList);
      gcProject.triggerHandler(oldMap, null, null, false, false, false, true);
    }
  }
}
