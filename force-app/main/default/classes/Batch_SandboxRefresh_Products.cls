global class Batch_SandboxRefresh_Products implements Database.Batchable<sObject> {

	String query;

	global Batch_SandboxRefresh_Products() {
		query = 'SELECT Id FROM Product2';
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
		for( sObject obj : scope )
		{
			obj.put('Dump_Id__c', obj.Id );
			obj.put('Supplier__c', null);
			obj.put('AcctSeedERP__Default_Vendor__c', null);
		}
		update scope;
	}

	global void finish(Database.BatchableContext BC) {
		if( !Test.isRunningTest() )
		{
			Database.executeBatch( new Batch_SandboxRefresh_Pricebooks() );
		}
	}

}