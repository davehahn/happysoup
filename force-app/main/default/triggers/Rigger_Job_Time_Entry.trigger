/**
 * Created by dave on 2019-11-22.
 */

trigger Rigger_Job_Time_Entry on Rigger_Job_Time_Entry__c ( before insert,
                                                            before update,
                                                            before delete,
                                                            after insert,
                                                            after update,
                                                            after delete,
                                                            after undelete )
{
  new RiggerJobTimeEntry_TriggerHandler().run();
}