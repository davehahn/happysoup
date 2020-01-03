/**
 * Created by dave on 2020-01-02.
 */

trigger SystemIssue on System_Issue__c (before insert,
                                        before update,
                                        before delete,
                                        after insert,
                                        after update,
                                        after delete,
                                        after undelete)
{
  new SystemIssue_TriggerHandler().run();
}