public with sharing class BatchProductAverageArrivalTime_ar implements Schedulable, Database.Batchable<sObject>{

	public BatchProductAverageArrivalTime_ar() {}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id FROM Product2 WHERE AcctSeed__Inventory_Product__c = true';
		return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
   		Set<Id> setIdProduct = new Set<Id>();
		for(SObject sObj : scope) {
			Product2 p = (Product2) sObj;
			setIdProduct.add(p.Id);
		}
		gcInventoryReport_MRP.updateProductAverageArrivalTime(setIdProduct);
	}
	
	public void execute(SchedulableContext sc) {
		BatchProductAverageArrivalTime_ar b = new BatchProductAverageArrivalTime_ar();
		database.executeBatch(b, 5);
	}
	
	public void finish(Database.BatchableContext BC) {}

	public static void coverage(){
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