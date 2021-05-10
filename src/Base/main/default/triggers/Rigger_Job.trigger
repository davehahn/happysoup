/**
 * Created by dave on 2019-11-26.
 */

trigger Rigger_Job on Rigger_Job__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
  new RiggerJob_TriggerHandler().run();
}