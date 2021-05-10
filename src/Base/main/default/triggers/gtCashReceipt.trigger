trigger gtCashReceipt on AcctSeed__Cash_Receipt__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(!gcCashReceipt.disableTrigger)
	{
		gcCashReceipt.triggerHandler
			(trigger.oldMap,
			 trigger.newMap,
			 trigger.new,
			 trigger.isBefore,
			 trigger.isInsert,
			 trigger.isUpdate,
			 trigger.isDelete);
	}
}