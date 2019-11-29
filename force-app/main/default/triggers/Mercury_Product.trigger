trigger Mercury_Product on Mercury_Product__c (
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete) {

  if( !Mercury_Product_dh.disableTrigger )
  {
    Mercury_Product_dh.triggerHandler
      (trigger.oldMap,
      trigger.newMap,
      trigger.new,
      trigger.isBefore,
      trigger.isInsert,
      trigger.isUpdate,
      trigger.isDelete);
  }

}