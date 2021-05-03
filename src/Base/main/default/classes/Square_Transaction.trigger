/**
 * Created by dave on 2020-06-19.
 */

trigger Square_Transaction on Square_Transaction__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
  new SquareTransaction_TriggerHandler().run();
}