global class Batch_SandboxRefresh_Pricebooks implements Database.Batchable<sObject> {

	String query;

	global Batch_SandboxRefresh_Pricebooks() {
		Id supplierRtId = new Application_RecordType().getPricebookRecordTypes().getSupplierId();
		query = 'SELECT Id FROM Pricebook2 WHERE RecordTypeId <> \'' + String.valueOf(supplierRtId) + '\'';
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
		for( sObject obj : scope )
		{
			obj.put('Dump_Id__c', obj.Id );
		}
		update scope;
	}

	global void finish(Database.BatchableContext BC) {
		if( !Test.isRunningTest() )
		{
			Database.executeBatch( new Batch_SandboxRefresh_PricebookEntries() );
		}
	}

}