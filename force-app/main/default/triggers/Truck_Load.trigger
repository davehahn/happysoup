trigger Truck_Load on Truck_Load__c (
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete) {
System.debug('Truck Load Trigger activated');
    Truck_Load_Ext.loadTriggerHandler
      (trigger.oldMap,
       trigger.newMap,
       trigger.new,
       trigger.isBefore,
       trigger.isInsert,
       trigger.isUpdate,
       trigger.isDelete);
}