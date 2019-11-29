trigger gtCashDisbursement on AcctSeed__Cash_Disbursement__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(!gcCashDisbursement.disableTrigger)
	{
		gcCashDisbursement.triggerHandler
			(trigger.oldMap,
			 trigger.newMap,
			 trigger.new,
			 trigger.isBefore,
			 trigger.isInsert,
			 trigger.isUpdate,
			 trigger.isDelete);
	}
}