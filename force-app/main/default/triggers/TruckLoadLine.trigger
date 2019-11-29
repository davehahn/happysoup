trigger TruckLoadLine on TruckLoadLine__c (
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete) {

    Truck_Load_Ext.lineTriggerHandler
      (trigger.oldMap,
       trigger.newMap,
       trigger.new,
       trigger.isBefore,
       trigger.isInsert,
       trigger.isUpdate,
       trigger.isDelete);
}