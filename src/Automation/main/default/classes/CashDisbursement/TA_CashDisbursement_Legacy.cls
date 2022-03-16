/**
 * Created by dave on 2021-12-22.
 */

public without sharing class TA_CashDisbursement_Legacy implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate, TriggerAction.BeforeDelete, TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {
  public void beforeInsert(List<AcctSeed__Cash_Disbursement__c> newList) {
    if (!gcCashDisbursement.disableTrigger) {
      gcCashDisbursement.triggerHandler(null, null, newList, true, true, false, false);
    }
  }

  public void afterInsert(List<AcctSeed__Cash_Disbursement__c> newList) {
    if (!gcCashDisbursement.disableTrigger) {
      Map<Id, AcctSeed__Cash_Disbursement__c> newMap = new Map<Id, AcctSeed__Cash_Disbursement__c>(newList);
      gcCashDisbursement.triggerHandler(null, newMap, newList, false, true, false, false);
    }
  }

  public void beforeUpdate(List<AcctSeed__Cash_Disbursement__c> newList, List<AcctSeed__Cash_Disbursement__c> oldList) {
    if (!gcCashDisbursement.disableTrigger) {
      Map<Id, AcctSeed__Cash_Disbursement__c> newMap = new Map<Id, AcctSeed__Cash_Disbursement__c>(newList);
      Map<Id, AcctSeed__Cash_Disbursement__c> oldMap = new Map<Id, AcctSeed__Cash_Disbursement__c>(oldList);
      gcCashDisbursement.triggerHandler(oldMap, newMap, newList, true, false, true, false);
    }
  }

  public void afterUpdate(List<AcctSeed__Cash_Disbursement__c> newList, List<AcctSeed__Cash_Disbursement__c> oldList) {
    if (!gcCashDisbursement.disableTrigger) {
      Map<Id, AcctSeed__Cash_Disbursement__c> newMap = new Map<Id, AcctSeed__Cash_Disbursement__c>(newList);
      Map<Id, AcctSeed__Cash_Disbursement__c> oldMap = new Map<Id, AcctSeed__Cash_Disbursement__c>(oldList);
      gcCashDisbursement.triggerHandler(oldMap, newMap, newList, false, false, true, false);
    }
  }

  public void beforeDelete(List<AcctSeed__Cash_Disbursement__c> oldList) {
    if (!gcCashDisbursement.disableTrigger) {
      Map<Id, AcctSeed__Cash_Disbursement__c> oldMap = new Map<Id, AcctSeed__Cash_Disbursement__c>(oldList);
      gcCashDisbursement.triggerHandler(oldMap, null, null, true, false, false, true);
    }
  }

  public void afterDelete(List<AcctSeed__Cash_Disbursement__c> oldList) {
    if (!gcCashDisbursement.disableTrigger) {
      Map<Id, AcctSeed__Cash_Disbursement__c> oldMap = new Map<Id, AcctSeed__Cash_Disbursement__c>(oldList);
      gcCashDisbursement.triggerHandler(oldMap, null, null, false, false, false, true);
    }
  }
}
