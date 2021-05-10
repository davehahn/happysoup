trigger gtOutboundInventoryMovement on AcctSeedERP__Outbound_Inventory_Movement__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(!gcOutboundInventoryMovement.disableTrigger)
	{
		gcOutboundInventoryMovement.triggerHandler
			(trigger.oldMap,
			 trigger.newMap,
			 trigger.new,
			 trigger.isBefore,
			 trigger.isInsert,
			 trigger.isUpdate,
			 trigger.isDelete);
	}
}