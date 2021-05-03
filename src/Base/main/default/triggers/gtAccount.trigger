trigger gtAccount on Account (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(!gcAccount.disableTrigger)
	{
		gcAccount.triggerHandler
			(trigger.oldMap,
			 trigger.newMap,
			 trigger.new,
			 trigger.isBefore,
			 trigger.isInsert,
			 trigger.isUpdate,
			 trigger.isDelete);
	}
}