trigger gtAccountPayableLine on AcctSeed__Account_Payable_Line__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(!gcAccountPayableLine.disableTrigger)
	{
		gcAccountPayableLine.triggerHandler
			(trigger.oldMap,
			 trigger.newMap,
			 trigger.new,
			 trigger.isBefore,
			 trigger.isInsert,
			 trigger.isUpdate,
			 trigger.isDelete);
	}
}