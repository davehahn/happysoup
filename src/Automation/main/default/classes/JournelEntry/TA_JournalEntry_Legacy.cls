/**
 * Created by dave on 2022-01-26.
 */

public without sharing class TA_JournalEntry_Legacy
  implements
      TriggerAction.BeforeInsert,
      TriggerAction.BeforeUpdate,
      TriggerAction.BeforeDelete,
      TriggerAction.AfterInsert,
      TriggerAction.AfterUpdate,
      TriggerAction.AfterDelete
{

  public void beforeInsert(
    List<AcctSeed__Journal_Entry__c> newList
  )
  {
    if (!JournalEntry_dh.disableTrigger)
    {

      JournalEntry_dh.triggerHandler(
        null,
        null,
        newList,
        true,
        true,
        false,
        false
      );
    }
  }

  public void afterInsert(
    List<AcctSeed__Journal_Entry__c> newList
  )
  {
    if (!JournalEntry_dh.disableTrigger)
    {
      Map<Id, AcctSeed__Journal_Entry__c> newMap =
        new Map<Id, AcctSeed__Journal_Entry__c>(newList);
      JournalEntry_dh.triggerHandler(
        null,
        newMap,
        newList,
        false,
        true,
        false,
        false
      );
    }
  }

  public void beforeUpdate(
    List<AcctSeed__Journal_Entry__c> newList,
    List<AcctSeed__Journal_Entry__c> oldList
  )
  {
    if (!JournalEntry_dh.disableTrigger)
    {
      Map<Id, AcctSeed__Journal_Entry__c> newMap =
        new Map<Id, AcctSeed__Journal_Entry__c>(newList);
      Map<Id, AcctSeed__Journal_Entry__c> oldMap =
        new Map<Id, AcctSeed__Journal_Entry__c>(oldList);
      JournalEntry_dh.triggerHandler(
        oldMap,
        newMap,
        newList,
        true,
        false,
        true,
        false
      );
    }
  }

  public void afterUpdate(
    List<AcctSeed__Journal_Entry__c> newList,
    List<AcctSeed__Journal_Entry__c> oldList
  )
  {
    if (!JournalEntry_dh.disableTrigger)
    {
      Map<Id, AcctSeed__Journal_Entry__c> newMap =
        new Map<Id, AcctSeed__Journal_Entry__c>(newList);
      Map<Id, AcctSeed__Journal_Entry__c> oldMap =
        new Map<Id, AcctSeed__Journal_Entry__c>(oldList);
      JournalEntry_dh.triggerHandler(
        oldMap,
        newMap,
        newList,
        false,
        false,
        true,
        false
      );
    }
  }

  public void beforeDelete(
    List<AcctSeed__Journal_Entry__c> oldList
  )
  {
    if (!JournalEntry_dh.disableTrigger)
    {
      Map<Id, AcctSeed__Journal_Entry__c> oldMap =
        new Map<Id, AcctSeed__Journal_Entry__c>(oldList);
      JournalEntry_dh.triggerHandler(
        oldMap,
        null,
        null,
        true,
        false,
        false,
        true
      );
    }
  }

  public void afterDelete(
    List<AcctSeed__Journal_Entry__c> oldList
  )
  {
    if (!JournalEntry_dh.disableTrigger)
    {
      Map<Id, AcctSeed__Journal_Entry__c> oldMap =
        new Map<Id, AcctSeed__Journal_Entry__c>(oldList);
      JournalEntry_dh.triggerHandler(
        oldMap,
        null,
        null,
        false,
        false,
        false,
        true
      );
    }
  }

}