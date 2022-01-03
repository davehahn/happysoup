/**
 * Created by dave on 2021-12-22.
 */

public inherited sharing class TA_BillingLine_Legacy implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate, TriggerAction.BeforeDelete, TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {
  public void beforeInsert(List<AcctSeed__Billing_Line__c> newList) {
    if (!gcBillingLine.disableTrigger) {
      gcBillingLine.triggerHandler(null, null, newList, true, true, false, false);
    }
  }

  public void afterInsert(List<AcctSeed__Billing_Line__c> newList) {
    if (!gcBillingLine.disableTrigger) {
      Map<Id, AcctSeed__Billing_Line__c> newMap = new Map<Id, AcctSeed__Billing_Line__c>(newList);
      gcBillingLine.triggerHandler(null, newMap, newList, false, true, false, false);
    }
  }

  public void beforeUpdate(List<AcctSeed__Billing_Line__c> newList, List<AcctSeed__Billing_Line__c> oldList) {
    if (!gcBillingLine.disableTrigger) {
      Map<Id, AcctSeed__Billing_Line__c> newMap = new Map<Id, AcctSeed__Billing_Line__c>(newList);
      Map<Id, AcctSeed__Billing_Line__c> oldMap = new Map<Id, AcctSeed__Billing_Line__c>(oldList);
      gcBillingLine.triggerHandler(oldMap, newMap, newList, true, false, true, false);
    }
  }

  public void afterUpdate(List<AcctSeed__Billing_Line__c> newList, List<AcctSeed__Billing_Line__c> oldList) {
    if (!gcBillingLine.disableTrigger) {
      Map<Id, AcctSeed__Billing_Line__c> newMap = new Map<Id, AcctSeed__Billing_Line__c>(newList);
      Map<Id, AcctSeed__Billing_Line__c> oldMap = new Map<Id, AcctSeed__Billing_Line__c>(oldList);
      gcBillingLine.triggerHandler(oldMap, newMap, newList, false, false, true, false);
    }
  }

  public void beforeDelete(List<AcctSeed__Billing_Line__c> oldList) {
    if (!gcBillingLine.disableTrigger) {
      Map<Id, AcctSeed__Billing_Line__c> oldMap = new Map<Id, AcctSeed__Billing_Line__c>(oldList);
      gcBillingLine.triggerHandler(oldMap, null, null, true, false, false, true);
    }
  }

  public void afterDelete(List<AcctSeed__Billing_Line__c> oldList) {
    if (!gcBillingLine.disableTrigger) {
      Map<Id, AcctSeed__Billing_Line__c> oldMap = new Map<Id, AcctSeed__Billing_Line__c>(oldList);
      gcBillingLine.triggerHandler(oldMap, null, null, false, false, false, true);
    }
  }
}
