trigger CaseTrigger on Case (
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete)
{
  // set this flag if we are running unit tests
  if( Test.isRunningTest() && trigger.isBefore && trigger.isInsert )
  {
    for( Case c : trigger.new )
    {
      c.IsForUnitTest__c = true;
    }
  }
  new Case_TriggerHandler().run();
}