/**
 * Created by dave on 2021-12-22.
 */

public without sharing class TA_AccountPayableLine_Legacy implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate, TriggerAction.BeforeDelete, TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {
  public void beforeInsert(List<AcctSeed__Account_Payable_Line__c> newList) {
    if (!gcAccountPayable.disableTrigger) {
      gcAccountPayableLine.triggerHandler(null, null, newList, true, true, false, false);
    }
  }

  public void afterInsert(List<AcctSeed__Account_Payable_Line__c> newList) {
    if (!gcAccountPayable.disableTrigger) {
      Map<Id, AcctSeed__Account_Payable_Line__c> newMap = new Map<Id, AcctSeed__Account_Payable_Line__c>(newList);
      gcAccountPayableLine.triggerHandler(null, newMap, newList, false, true, false, false);
    }
  }

  public void beforeUpdate(
    List<AcctSeed__Account_Payable_Line__c> newList,
    List<AcctSeed__Account_Payable_Line__c> oldList
  ) {
    if (!gcAccountPayable.disableTrigger) {
      Map<Id, AcctSeed__Account_Payable_Line__c> newMap = new Map<Id, AcctSeed__Account_Payable_Line__c>(newList);
      Map<Id, AcctSeed__Account_Payable_Line__c> oldMap = new Map<Id, AcctSeed__Account_Payable_Line__c>(oldList);
      gcAccountPayableLine.triggerHandler(oldMap, newMap, newList, true, false, true, false);
    }
  }

  public void afterUpdate(
    List<AcctSeed__Account_Payable_Line__c> newList,
    List<AcctSeed__Account_Payable_Line__c> oldList
  ) {
    if (!gcAccountPayableLine.disableTrigger) {
      Map<Id, AcctSeed__Account_Payable_Line__c> newMap = new Map<Id, AcctSeed__Account_Payable_Line__c>(newList);
      Map<Id, AcctSeed__Account_Payable_Line__c> oldMap = new Map<Id, AcctSeed__Account_Payable_Line__c>(oldList);
      gcAccountPayableLine.triggerHandler(oldMap, newMap, newList, false, false, true, false);
    }
  }

  public void beforeDelete(List<AcctSeed__Account_Payable_Line__c> oldList) {
    if (!gcAccountPayableLine.disableTrigger) {
      Map<Id, AcctSeed__Account_Payable_Line__c> oldMap = new Map<Id, AcctSeed__Account_Payable_Line__c>(oldList);
      gcAccountPayableLine.triggerHandler(oldMap, null, null, true, false, false, true);
    }
  }

  public void afterDelete(List<AcctSeed__Account_Payable_Line__c> oldList) {
    if (!gcAccountPayableLine.disableTrigger) {
      Map<Id, AcctSeed__Account_Payable_Line__c> oldMap = new Map<Id, AcctSeed__Account_Payable_Line__c>(oldList);
      gcAccountPayableLine.triggerHandler(oldMap, null, null, false, false, false, true);
    }
  }
}
