trigger TradeInRecord on Trade_in_Record__c (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {

		if( !TradeInRecord_TriggerHandler.disableTrigger )
		{
			TradeInRecord_TriggerHandler.doHandle( trigger.oldMap,
																		         trigger.newMap,
																		         trigger.new,
																		         trigger.isBefore,
																		         trigger.isInsert,
																		         trigger.isUpdate,
																		         trigger.isDelete );
		}
}