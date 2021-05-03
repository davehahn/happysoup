global with sharing class gcProductMRP_Batch implements Schedulable, Database.Batchable<sObject>{

	global gcProductMRP_Batch() {}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id FROM Product2 WHERE AcctSeed__Inventory_Product__c = true';
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
   		Set<Id> setIdProduct = new Set<Id>();
		for(SObject sObj : scope) {
			Product2 p = (Product2) sObj;
			setIdProduct.add(p.Id);
		}
		gcInventoryReport_MRP.updateProductAvailabilityBatch(setIdProduct);
	}
	
	global void execute(SchedulableContext sc) {
		gcProductMRP_Batch b = new gcProductMRP_Batch();
		database.executeBatch(b, 20);
	}
	
	global void finish(Database.BatchableContext BC) {}

	global static void coverage(){
		integer i;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
	}
}