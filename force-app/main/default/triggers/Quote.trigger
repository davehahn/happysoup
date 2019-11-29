trigger Quote on Quote (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {

		if( !Quote_TriggerHandler.disableTrigger )
		{
			Quote_TriggerHandler.doHandle( trigger.oldMap,
														         trigger.newMap,
														         trigger.new,
														         trigger.isBefore,
														         trigger.isInsert,
														         trigger.isUpdate,
														         trigger.isDelete );
		}
}