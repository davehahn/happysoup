/**
 * Created by Pooja on 2022-01-01.
 */

public without sharing class TA_ProductPart_Legacy implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate, TriggerAction.BeforeDelete, TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {
  public void beforeInsert(List<AcctSeed__Product_Part__c> newList) {
    if (!gcProductPart.disableTrigger) {
      gcProductPart.triggerHandler(null, null, newList, true, true, false, false);
    }
  }

  public void afterInsert(List<AcctSeed__Product_Part__c> newList) {
    if (!gcProductPart.disableTrigger) {
      Map<Id, AcctSeed__Product_Part__c> newMap = new Map<Id, AcctSeed__Product_Part__c>(newList);
      gcProductPart.triggerHandler(null, newMap, newList, false, true, false, false);
    }
  }

  public void beforeUpdate(List<AcctSeed__Product_Part__c> newList, List<AcctSeed__Product_Part__c> oldList) {
    if (!gcProductPart.disableTrigger) {
      Map<Id, AcctSeed__Product_Part__c> newMap = new Map<Id, AcctSeed__Product_Part__c>(newList);
      Map<Id, AcctSeed__Product_Part__c> oldMap = new Map<Id, AcctSeed__Product_Part__c>(oldList);
      gcProductPart.triggerHandler(oldMap, newMap, newList, true, false, true, false);
    }
  }

  public void afterUpdate(List<AcctSeed__Product_Part__c> newList, List<AcctSeed__Product_Part__c> oldList) {
    if (!gcProductPart.disableTrigger) {
      Map<Id, AcctSeed__Product_Part__c> newMap = new Map<Id, AcctSeed__Product_Part__c>(newList);
      Map<Id, AcctSeed__Product_Part__c> oldMap = new Map<Id, AcctSeed__Product_Part__c>(oldList);
      gcProductPart.triggerHandler(oldMap, newMap, newList, false, false, true, false);
    }
  }

  public void beforeDelete(List<AcctSeed__Product_Part__c> oldList) {
    if (!gcProductPart.disableTrigger) {
      Map<Id, AcctSeed__Product_Part__c> oldMap = new Map<Id, AcctSeed__Product_Part__c>(oldList);
      gcProductPart.triggerHandler(oldMap, null, null, true, false, false, true);
    }
  }

  public void afterDelete(List<AcctSeed__Product_Part__c> oldList) {
    if (!gcProductPart.disableTrigger) {
      Map<Id, AcctSeed__Product_Part__c> oldMap = new Map<Id, AcctSeed__Product_Part__c>(oldList);
      gcProductPart.triggerHandler(oldMap, null, null, false, false, false, true);
    }
  }
}
