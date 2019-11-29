trigger JournalEntryTrigger_ar on AcctSeed__Journal_Entry__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(!JournalEntryTriggerHandler_ar.disableTrigger)
	{
		JournalEntryTriggerHandler_ar.triggerHandler
			(trigger.oldMap,
			 trigger.newMap,
			 trigger.new,
			 trigger.isBefore,
			 trigger.isInsert,
			 trigger.isUpdate,
			 trigger.isDelete);
	}
}