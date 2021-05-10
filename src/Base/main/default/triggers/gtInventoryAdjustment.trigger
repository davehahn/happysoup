trigger gtInventoryAdjustment on GMBLASERP__Inventory_Adjustment__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	
	if(!gcInventoryAdjustment.disableTrigger)
	{
		gcInventoryAdjustment.triggerHandler
			(trigger.oldMap,
			 trigger.newMap,
			 trigger.new,
			 trigger.isBefore,
			 trigger.isInsert,
			 trigger.isUpdate,
			 trigger.isDelete);
	}
}