trigger gtPurchaseOrderInventoryMovement on AcctSeedERP__Purchase_Order_Inventory_Movement__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(!gcPurchaseOrderInventoryMovement.disableTrigger)
	{
		gcPurchaseOrderInventoryMovement.triggerHandler
			(trigger.oldMap,
			 trigger.newMap,
			 trigger.new,
			 trigger.isBefore,
			 trigger.isInsert,
			 trigger.isUpdate,
			 trigger.isDelete);
	}
}