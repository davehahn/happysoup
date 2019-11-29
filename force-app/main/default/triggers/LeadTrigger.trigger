trigger LeadTrigger on Lead (
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete) {

    new Lead_TriggerHandler().run();
//    LGND_Lead.doHandle
//      (trigger.oldMap,
//       trigger.newMap,
//       trigger.new,
//       trigger.isBefore,
//       trigger.isInsert,
//       trigger.isUpdate,
//       trigger.isDelete);
}