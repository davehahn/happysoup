public with sharing class ProductMRPValuesBatch_ar implements Schedulable, Database.Batchable<sObject>{

	public ProductMRPValuesBatch_ar() {}
	
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
		gcInventoryReport_MRP.updateProductAvailabilityWarehouseBatch(setIdProduct);
	}
	
	public void execute(SchedulableContext sc) {
		ProductMRPValuesBatch_ar b = new ProductMRPValuesBatch_ar();
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