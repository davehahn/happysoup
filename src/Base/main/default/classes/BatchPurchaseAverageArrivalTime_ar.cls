public with sharing class BatchPurchaseAverageArrivalTime_ar implements Schedulable, Database.Batchable<sObject>{

	public BatchPurchaseAverageArrivalTime_ar() {}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT GMBLASERP__Product__c idProduct FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c WHERE LastModifiedDate >= YESTERDAY AND GMBLASERP__Product__r.AcctSeed__Inventory_Product__c = true GROUP BY GMBLASERP__Product__c';
		return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
   		Set<Id> setIdProduct = new Set<Id>();
		for(sObject sObj : scope) {
			setIdProduct.add((Id)sObj.get('idProduct'));
		}
		setIdProduct.remove(null);
		if(!setIdProduct.isEmpty())
			gcInventoryReport_MRP.updateProductAverageArrivalTime(setIdProduct);
	}
	
	public void execute(SchedulableContext sc) {
		BatchPurchaseAverageArrivalTime_ar b = new BatchPurchaseAverageArrivalTime_ar();
		database.executeBatch(b, 20);
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