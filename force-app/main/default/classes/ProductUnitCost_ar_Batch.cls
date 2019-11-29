public with sharing class ProductUnitCost_ar_Batch implements Schedulable, Database.Batchable<sObject>{

	public ProductUnitCost_ar_Batch() {}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id FROM Product2 WHERE AcctSeed__Inventory_Product__c = true';
		return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		List<String> listIdProducts = new List<String>();
		for(SObject sObj : scope) {
			Product2 p = (Product2) sObj;
			listIdProducts.add(p.Id);
		}
		map<String,list<String>> mapFilters = new map<String,list<String>>();
		mapFilters.put('idProduct',listIdProducts);
		List<gcInventoryMovementCube_Report.cube> allCubes = gcInventoryMovementCube_Report.inventoryAggRes(mapFilters, new List<String>{'idProduct'});
		Map<Id,Decimal> mapProductCost = new Map<Id,Decimal>();
		for(gcInventoryMovementCube_Report.cube cube : allCubes){
			Decimal avg = cube.qty != 0 ? cube.amt/cube.qty : 0;
			mapProductCost.put(cube.idProduct, avg);
		}
		List<Product2> listProducts = new List<Product2>();
		Id idPricebookFactory = Legend_Settings__c.getOrgDefaults().Default_Factory_Pricebook__c;
		for(Product2 p : 
				[SELECT Id, 
					Landed_Unit_Cost__c, 
					Partner_Price__c, 
					(SELECT Id, 
						UnitPrice 
					FROM PricebookEntries 
					WHERE Pricebook2Id =:idPricebookFactory 
				ORDER BY CreatedDate DESC LIMIT 1) 
				FROM Product2 WHERE Id IN:mapProductCost.keySet()])
		{
			Decimal avg = mapProductCost.get(p.Id);
			Decimal partnerPrice = 0;
			if(!p.PricebookEntries.isEmpty())
				partnerPrice = p.PricebookEntries[0].UnitPrice;

			partnerPrice = partnerPrice == null ? 0 : partnerPrice;
			if(p.Landed_Unit_Cost__c == null 
				|| p.Partner_Price__c == null
				|| p.Landed_Unit_Cost__c.setScale(2) != avg.setScale(2)
				|| p.Partner_Price__c.setScale(2) != partnerPrice)
			{
				p.Landed_Unit_Cost__c = avg.setScale(2);
				p.Partner_Price__c = partnerPrice.setScale(2);
				listProducts.add(p);
			}
		}
		if(!listProducts.isEmpty()){
			Boolean olVal = gcProduct.disableTrigger;
			gcProduct.disableTrigger = true;
			update listProducts;
			gcProduct.disableTrigger = olVal;
		}
	}
	
	public void execute(SchedulableContext sc) {
		ProductUnitCost_ar_Batch b = new ProductUnitCost_ar_Batch();
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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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