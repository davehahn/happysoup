trigger TruckDeliveryItem on Truck_Delivery_Item__c (before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete) {

    TruckDeliveryItem.triggerHandler
      (trigger.oldMap,
       trigger.newMap,
       trigger.new,
       trigger.isBefore,
       trigger.isInsert,
       trigger.isUpdate,
       trigger.isDelete);
}