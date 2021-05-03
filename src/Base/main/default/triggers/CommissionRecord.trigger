trigger CommissionRecord on CommissionRecord__c (
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete) {

    CommissionRecordERP.triggerHandler
      (trigger.oldMap,
       trigger.newMap,
       trigger.new,
       trigger.isBefore,
       trigger.isInsert,
       trigger.isUpdate,
       trigger.isDelete);
}