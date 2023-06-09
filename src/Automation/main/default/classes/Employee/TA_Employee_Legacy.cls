/**
 * Created by Pooja on 2022-01-01.
 */

public without sharing class TA_Employee_Legacy implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate, TriggerAction.BeforeDelete, TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {
  public void beforeInsert(List<Employee__c> newList) {
    if (!gcEmployee.disableTrigger) {
      gcEmployee.triggerHandler(null, null, newList, true, true, false, false);
    }
  }

  public void afterInsert(List<Employee__c> newList) {
    if (!gcEmployee.disableTrigger) {
      Map<Id, Employee__c> newMap = new Map<Id, Employee__c>(newList);
      gcEmployee.triggerHandler(null, newMap, newList, false, true, false, false);
    }
  }

  public void beforeUpdate(List<Employee__c> newList, List<Employee__c> oldList) {
    if (!gcEmployee.disableTrigger) {
      Map<Id, Employee__c> newMap = new Map<Id, Employee__c>(newList);
      Map<Id, Employee__c> oldMap = new Map<Id, Employee__c>(oldList);
      gcEmployee.triggerHandler(oldMap, newMap, newList, true, false, true, false);
    }
  }

  public void afterUpdate(List<Employee__c> newList, List<Employee__c> oldList) {
    if (!gcEmployee.disableTrigger) {
      Map<Id, Employee__c> newMap = new Map<Id, Employee__c>(newList);
      Map<Id, Employee__c> oldMap = new Map<Id, Employee__c>(oldList);
      gcEmployee.triggerHandler(oldMap, newMap, newList, false, false, true, false);
    }
  }

  public void beforeDelete(List<Employee__c> oldList) {
    if (!gcEmployee.disableTrigger) {
      Map<Id, Employee__c> oldMap = new Map<Id, Employee__c>(oldList);
      gcEmployee.triggerHandler(oldMap, null, null, true, false, false, true);
    }
  }

  public void afterDelete(List<Employee__c> oldList) {
    if (!gcEmployee.disableTrigger) {
      Map<Id, Employee__c> oldMap = new Map<Id, Employee__c>(oldList);
      gcEmployee.triggerHandler(oldMap, null, null, false, false, false, true);
    }
  }
}
