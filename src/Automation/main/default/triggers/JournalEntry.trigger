/**
 * Created by dave on 2022-03-15.
 */

trigger JournalEntry on AcctSeed__Journal_Entry__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
  new MetadataTriggerHandler().run();
}