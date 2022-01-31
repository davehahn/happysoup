//TODO : Need to delete
trigger DealerOrderLine on Dealer_Order_Line__c (
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete) {

  //new DealerOrderLine_TriggerHandler().run();

}