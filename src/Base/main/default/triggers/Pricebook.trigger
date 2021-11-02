/**
 * Created by dave on 2021-11-02.
 */

trigger Pricebook on Pricebook2 (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
  new Pricebook_TriggerHandler().run();
}