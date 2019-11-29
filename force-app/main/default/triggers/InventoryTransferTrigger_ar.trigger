trigger InventoryTransferTrigger_ar on GMBLASERP__Inventory_Transfer__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(!InventoryTransfer_ar.disableTrigger)
	{
		InventoryTransfer_ar.triggerHandler
			(trigger.oldMap,
			 trigger.newMap,
			 trigger.new,
			 trigger.isBefore,
			 trigger.isInsert,
			 trigger.isUpdate,
			 trigger.isDelete);
	}
}