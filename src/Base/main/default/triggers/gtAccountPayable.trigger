trigger gtAccountPayable on AcctSeed__Account_Payable__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(!gcAccountPayable.disableTrigger)
	{
		gcAccountPayable.triggerHandler
			(trigger.oldMap,
			 trigger.newMap,
			 trigger.new,
			 trigger.isBefore,
			 trigger.isInsert,
			 trigger.isUpdate,
			 trigger.isDelete);
	}
}