/* TODO: DELETE ME */
trigger gtProduct on Product2 (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

//	// set this flag if we are running unit tests
//	if( Test.isRunningTest() && trigger.isBefore && trigger.isInsert )
//	{
//		for( Product2 p : trigger.new )
//		{
//			p.IsForUnitTest__c= true;
//		}
//	}
//	if(!gcProduct.disableTrigger)
//	{
//		gcProduct.triggerHandler
//			(trigger.oldMap,
//			 trigger.newMap,
//			 trigger.new,
//			 trigger.isBefore,
//			 trigger.isInsert,
//			 trigger.isUpdate,
//			 trigger.isDelete);
//	}
}