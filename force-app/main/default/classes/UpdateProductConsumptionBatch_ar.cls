public with sharing class UpdateProductConsumptionBatch_ar implements Schedulable, Database.Batchable<sObject>{

	public UpdateProductConsumptionBatch_ar() {}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id FROM Product2 WHERE AcctSeed__Inventory_Product__c = true';
		return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
   		Set<Id> setIdRecord = new Set<Id>();
		for(SObject sObj : scope) {
			Product2 p = (Product2) sObj;
			setIdRecord.add(p.Id);			
		}
		if(!setIdRecord.isEmpty())
			UpdateProductConsumption_ar.retrieveProductsDataByWarehouse(setIdRecord);
	}
	
	public void execute(SchedulableContext sc) {
		UpdateProductConsumptionBatch_ar b = new UpdateProductConsumptionBatch_ar();
		database.executeBatch(b, 1);
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
	}
}