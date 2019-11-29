trigger gtInventoryBalance on AcctSeedERP__Inventory_Balance__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(!gcInventoryBalance.disableTrigger)
	{
		gcInventoryBalance.triggerHandler
			(trigger.oldMap,
			 trigger.newMap,
			 trigger.new,
			 trigger.isBefore,
			 trigger.isInsert,
			 trigger.isUpdate,
			 trigger.isDelete);
	}
}