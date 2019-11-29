trigger DealerOrder on Dealer_Order__c (
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete) {

  if( !DealerOrder_Ext.disableTrigger )
  {

    DealerOrder_Ext.triggerHandler
      (trigger.oldMap,
       trigger.newMap,
       trigger.new,
       trigger.isBefore,
       trigger.isInsert,
       trigger.isUpdate,
       trigger.isDelete);
  }

}