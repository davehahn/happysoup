trigger ERPDocument_Trigger on ERP_document__c (before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete) {

    ERPDocument_Trigger.doHandle
      (trigger.oldMap,
       trigger.newMap,
       trigger.new,
       trigger.isBefore,
       trigger.isInsert,
       trigger.isUpdate,
       trigger.isDelete);
}