trigger Truck_Destination on Truck_Destination__c (before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete) {

    TruckDestination.triggerHandler
      (trigger.oldMap,
       trigger.newMap,
       trigger.new,
       trigger.isBefore,
       trigger.isInsert,
       trigger.isUpdate,
       trigger.isDelete);
}