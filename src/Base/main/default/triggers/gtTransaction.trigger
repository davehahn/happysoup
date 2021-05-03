trigger gtTransaction on AcctSeed__Transaction__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(!gcTransaction.disableTrigger)
	{
		gcTransaction.triggerHandler
			(trigger.oldMap,
			 trigger.newMap,
			 trigger.new,
			 trigger.isBefore,
			 trigger.isInsert,
			 trigger.isUpdate,
			 trigger.isDelete);
	}
}