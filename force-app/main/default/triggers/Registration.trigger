trigger Registration on Registration__c (
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete) {

//    RegistrationExt.triggerHandler
//      (trigger.oldMap,
//       trigger.newMap,
//       trigger.new,
//       trigger.isBefore,
//       trigger.isInsert,
//       trigger.isUpdate,
//       trigger.isDelete);
    new Registration_TriggerHandler().run();
}