trigger gtInboundInventoryMovement on AcctSeedERP__Inbound_Inventory_Movement__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(!gcInboundInventoryMovement.disableTrigger)
	{
		gcInboundInventoryMovement.triggerHandler
			(trigger.oldMap,
			 trigger.newMap,
			 trigger.new,
			 trigger.isBefore,
			 trigger.isInsert,
			 trigger.isUpdate,
			 trigger.isDelete);
	}
}