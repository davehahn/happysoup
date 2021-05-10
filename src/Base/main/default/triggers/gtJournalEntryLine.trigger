trigger gtJournalEntryLine on AcctSeed__Journal_Entry_Line__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(!gcJournalEntryLine.disableTrigger)
	{
		gcJournalEntryLine.triggerHandler
			(trigger.oldMap,
			 trigger.newMap,
			 trigger.new,
			 trigger.isBefore,
			 trigger.isInsert,
			 trigger.isUpdate,
			 trigger.isDelete);
	}
}