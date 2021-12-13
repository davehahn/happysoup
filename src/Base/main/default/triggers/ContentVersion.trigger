/**
 * Created by dave on 2021-12-13.
 */

trigger ContentVersion on ContentVersion (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
  new ContentVersion_TriggerHandler().run();
}