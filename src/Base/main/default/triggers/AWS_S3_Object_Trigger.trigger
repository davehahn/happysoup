trigger AWS_S3_Object_Trigger on AWS_S3_Object__c (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {

		AWS_S3_Object_TriggerHandler handler = new AWS_S3_Object_TriggerHandler(Trigger.isExecuting, Trigger.size);

		//before
		if (Trigger.isBefore) {
	  	if(trigger.isInsert)
			{

			}
			if(trigger.isUpdate)
			{

			}
			if(trigger.isDelete)
			{

			}

		}

		//after
		if (Trigger.isAfter) {

	    if(trigger.isInsert)
			{

			}
			if(trigger.isUpdate)
			{

			}
			if(trigger.isDelete)
			{
				// delete the object from AWS S3
				System.debug('&&&&&&&&&&&&&&&&&&&&&&&&&&& AWS S3 Object after delete trigger fired');
				handler.deleteFromAWS(Trigger.oldMap);
			}

		}

}