/**
 * Created by Pooja on 2022-01-01.
 */

public inherited sharing class TA_SerialNumber_Legacy implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate, TriggerAction.BeforeDelete, TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {
  public void beforeInsert(List<GMBLASERP__Serial_Number__c> newList) {
    if (!gcSerialNumber.disableTrigger) {
      gcSerialNumber.triggerHandler(null, null, newList, true, true, false, false);
    }
  }

  public void afterInsert(List<GMBLASERP__Serial_Number__c> newList) {
    if (!gcSerialNumber.disableTrigger) {
      Map<Id, GMBLASERP__Serial_Number__c> newMap = new Map<Id, GMBLASERP__Serial_Number__c>(newList);
      gcSerialNumber.triggerHandler(null, newMap, newList, false, true, false, false);
    }
  }

  public void beforeUpdate(List<GMBLASERP__Serial_Number__c> newList, List<GMBLASERP__Serial_Number__c> oldList) {
    if (!gcSerialNumber.disableTrigger) {
      Map<Id, GMBLASERP__Serial_Number__c> newMap = new Map<Id, GMBLASERP__Serial_Number__c>(newList);
      Map<Id, GMBLASERP__Serial_Number__c> oldMap = new Map<Id, GMBLASERP__Serial_Number__c>(oldList);
      gcSerialNumber.triggerHandler(oldMap, newMap, newList, true, false, true, false);
    }
  }

  public void afterUpdate(List<GMBLASERP__Serial_Number__c> newList, List<GMBLASERP__Serial_Number__c> oldList) {
    if (!gcSerialNumber.disableTrigger) {
      Map<Id, GMBLASERP__Serial_Number__c> newMap = new Map<Id, GMBLASERP__Serial_Number__c>(newList);
      Map<Id, GMBLASERP__Serial_Number__c> oldMap = new Map<Id, GMBLASERP__Serial_Number__c>(oldList);
      gcSerialNumber.triggerHandler(oldMap, newMap, newList, false, false, true, false);
    }
  }

  public void beforeDelete(List<GMBLASERP__Serial_Number__c> oldList) {
    if (!gcSerialNumber.disableTrigger) {
      Map<Id, GMBLASERP__Serial_Number__c> oldMap = new Map<Id, GMBLASERP__Serial_Number__c>(oldList);
      gcSerialNumber.triggerHandler(oldMap, null, null, true, false, false, true);
    }
  }

  public void afterDelete(List<GMBLASERP__Serial_Number__c> oldList) {
    if (!gcSerialNumber.disableTrigger) {
      Map<Id, GMBLASERP__Serial_Number__c> oldMap = new Map<Id, GMBLASERP__Serial_Number__c>(oldList);
      gcSerialNumber.triggerHandler(oldMap, null, null, false, false, false, true);
    }
  }
}
