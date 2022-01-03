/**
 * Created by Pooja on 2022-01-01.
 */

public inherited sharing class TA_ProjectTask_Legacy implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate, TriggerAction.BeforeDelete, TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {
  public void beforeInsert(List<AcctSeed__Project_Task__c> newList) {
    if (!gcProjectTask.disableTrigger) {
      gcProjectTask.triggerHandler(null, null, newList, true, true, false, false);
    }
  }

  public void afterInsert(List<AcctSeed__Project_Task__c> newList) {
    if (!gcProjectTask.disableTrigger) {
      Map<Id, AcctSeed__Project_Task__c> newMap = new Map<Id, AcctSeed__Project_Task__c>(newList);
      gcProjectTask.triggerHandler(null, newMap, newList, false, true, false, false);
    }
  }

  public void beforeUpdate(List<AcctSeed__Project_Task__c> newList, List<AcctSeed__Project_Task__c> oldList) {
    if (!gcProjectTask.disableTrigger) {
      Map<Id, AcctSeed__Project_Task__c> newMap = new Map<Id, AcctSeed__Project_Task__c>(newList);
      Map<Id, AcctSeed__Project_Task__c> oldMap = new Map<Id, AcctSeed__Project_Task__c>(oldList);
      gcProjectTask.triggerHandler(oldMap, newMap, newList, true, false, true, false);
    }
  }

  public void afterUpdate(List<AcctSeed__Project_Task__c> newList, List<AcctSeed__Project_Task__c> oldList) {
    if (!gcProjectTask.disableTrigger) {
      Map<Id, AcctSeed__Project_Task__c> newMap = new Map<Id, AcctSeed__Project_Task__c>(newList);
      Map<Id, AcctSeed__Project_Task__c> oldMap = new Map<Id, AcctSeed__Project_Task__c>(oldList);
      gcProjectTask.triggerHandler(oldMap, newMap, newList, false, false, true, false);
    }
  }

  public void beforeDelete(List<AcctSeed__Project_Task__c> oldList) {
    if (!gcProjectTask.disableTrigger) {
      Map<Id, AcctSeed__Project_Task__c> oldMap = new Map<Id, AcctSeed__Project_Task__c>(oldList);
      gcProjectTask.triggerHandler(oldMap, null, null, true, false, false, true);
    }
  }

  public void afterDelete(List<AcctSeed__Project_Task__c> oldList) {
    if (!gcProjectTask.disableTrigger) {
      Map<Id, AcctSeed__Project_Task__c> oldMap = new Map<Id, AcctSeed__Project_Task__c>(oldList);
      gcProjectTask.triggerHandler(oldMap, null, null, false, false, false, true);
    }
  }
}
