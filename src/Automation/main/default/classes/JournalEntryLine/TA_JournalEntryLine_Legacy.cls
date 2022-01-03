/**
 * Created by Pooja on 2022-01-01.
 */

public inherited sharing class TA_JournalEntryLine_Legacy
        implements
                        TriggerAction.BeforeInsert,
                        TriggerAction.BeforeUpdate,
                        TriggerAction.BeforeDelete,
                        TriggerAction.AfterInsert,
                        TriggerAction.AfterUpdate,
                        TriggerAction.AfterDelete
{

    public void beforeInsert(
            List<AcctSeed__Journal_Entry_Line__c> newList
    )
    {
        if (!gcJournalEntryLine.disableTrigger)
        {

            gcJournalEntryLine.triggerHandler(
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
            List<AcctSeed__Journal_Entry_Line__c> newList
    )
    {
        if (!gcJournalEntryLine.disableTrigger)
        {
            Map<Id, AcctSeed__Journal_Entry_Line__c> newMap =
                    new Map<Id, AcctSeed__Journal_Entry_Line__c>(newList);
            gcJournalEntryLine.triggerHandler(
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
            List<AcctSeed__Journal_Entry_Line__c> newList,
            List<AcctSeed__Journal_Entry_Line__c> oldList
    )
    {
        if (!gcJournalEntryLine.disableTrigger)
        {
            Map<Id, AcctSeed__Journal_Entry_Line__c> newMap =
                    new Map<Id, AcctSeed__Journal_Entry_Line__c>(newList);
            Map<Id, AcctSeed__Journal_Entry_Line__c> oldMap =
                    new Map<Id, AcctSeed__Journal_Entry_Line__c>(oldList);
            gcJournalEntryLine.triggerHandler(
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
            List<AcctSeed__Journal_Entry_Line__c> newList,
            List<AcctSeed__Journal_Entry_Line__c> oldList
    )
    {
        if (!gcJournalEntryLine.disableTrigger)
        {
            Map<Id, AcctSeed__Journal_Entry_Line__c> newMap =
                    new Map<Id, AcctSeed__Journal_Entry_Line__c>(newList);
            Map<Id, AcctSeed__Journal_Entry_Line__c> oldMap =
                    new Map<Id, AcctSeed__Journal_Entry_Line__c>(oldList);
            gcJournalEntryLine.triggerHandler(
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
            List<AcctSeed__Journal_Entry_Line__c> oldList
    )
    {
        if (!gcJournalEntryLine.disableTrigger)
        {
            Map<Id, AcctSeed__Journal_Entry_Line__c> oldMap =
                    new Map<Id, AcctSeed__Journal_Entry_Line__c>(oldList);
            gcJournalEntryLine.triggerHandler(
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
            List<AcctSeed__Journal_Entry_Line__c> oldList
    )
    {
        if (!gcJournalEntryLine.disableTrigger)
        {
            Map<Id, AcctSeed__Journal_Entry_Line__c> oldMap =
                    new Map<Id, AcctSeed__Journal_Entry_Line__c>(oldList);
            gcJournalEntryLine.triggerHandler(
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