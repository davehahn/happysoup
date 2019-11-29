trigger DealerOrderLine on Dealer_Order_Line__c (
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete) {

  if( !Dealer_Order_Line_Ext.disableTrigger ) {
    Dealer_Order_Line_Ext.triggerHandler
      (trigger.oldMap,
        trigger.newMap,
        trigger.new,
        trigger.isBefore,
        trigger.isInsert,
        trigger.isUpdate,
        trigger.isDelete);
  }

}