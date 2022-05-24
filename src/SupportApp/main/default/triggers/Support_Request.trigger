/**
 * Created by dave on 2022-05-20.
 */

trigger Support_Request on Support_Request__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
  new MetadataTriggerHandler().run();
}