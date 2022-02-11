/**
 * Created by dave on 2020-01-30.
 */

trigger CommissionRecord2 on CommissionRecord2__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
  //new CommissionRecord2_TriggerHandler().run();
  new MetadataTriggerHandler().run();
}