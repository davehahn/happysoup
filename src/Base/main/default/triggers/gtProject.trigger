trigger gtProject on AcctSeed__Project__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

//	// set this flag if we are running unit tests
//	if( Test.isRunningTest() && trigger.isBefore && trigger.isInsert )
//	{
//		for( AcctSeed__Project__c p : trigger.new )
//		{
//			p.IsForUnitTest__c= true;
//		}
//	}
//	if(!gcProject.disableTrigger)
//	{
//		gcProject.triggerHandler
//			(trigger.oldMap,
//			 trigger.newMap,
//			 trigger.new,
//			 trigger.isBefore,
//			 trigger.isInsert,
//			 trigger.isUpdate,
//			 trigger.isDelete);
//	}
}