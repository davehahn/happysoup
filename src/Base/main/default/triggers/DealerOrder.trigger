//TODO : Need to delete
trigger DealerOrder on Dealer_Order__c (
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete)
{
  //new DealerOrder_TriggerHandler().run();
}