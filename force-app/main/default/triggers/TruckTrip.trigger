trigger TruckTrip on Truck_Trip__c (before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete) {

    TruckTrip.triggerHandler
      (trigger.oldMap,
       trigger.newMap,
       trigger.new,
       trigger.isBefore,
       trigger.isInsert,
       trigger.isUpdate,
       trigger.isDelete);
}