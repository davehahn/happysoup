/**
 * Created by dave on 2022-03-03.
 */

trigger ProductConsumed on ProductConsumed (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
  new MetadataTriggerHandler().run();
}