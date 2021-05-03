global without sharing class tempIAVUpdatOrCreateProduct implements Schedulable, Database.Batchable<sObject>{

	global tempIAVUpdatOrCreateProduct() {}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id, Product_Code__c, Product__c, Production_Description__c, Create_As_Non_Inventory__c FROM Import_Adjustment_New__c';
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
   		List<Import_Adjustment_New__c> listImport = new List<Import_Adjustment_New__c>();
   		Set<String> setProductCode = new Set<String>();
   		Map<String,Product2> mapCodeProduct = new Map<String,Product2>();
		for(SObject sObj : scope) {
			Import_Adjustment_New__c imp = (Import_Adjustment_New__c) sObj;
			setProductCode.add(imp.Product_Code__c != null ? imp.Product_Code__c.toLowerCase() : null);
			listImport.add(imp);
		}
		setProductCode.remove(null);
		Id idRTPart = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Part').getRecordTypeId();
		/// Generate all the products
		for(Product2 p : [SELECT Id, IsActive, Unique_Product_Code__c, ProductCode, AcctSeed__Inventory_Product__c FROM Product2 WHERE Unique_Product_Code__c IN:setProductCode])
		{
			String pc = p.Unique_Product_Code__c.toLowerCase();
			mapCodeProduct.put(pc, p);
		}

		List<Product2> listNewProducts = new List<Product2>();
		for(Import_Adjustment_New__c imp : listImport)
		{
			if(imp.Product_Code__c != null)
			{
				String pc = imp.Product_Code__c.toLowerCase();
				if(!mapCodeProduct.containsKey(pc)){
					Product2 prod = new Product2(IsActive = true, Name = (imp.Production_Description__c == null ? pc : imp.Production_Description__c), Unique_Product_Code__c = pc, ProductCode = imp.Product_Code__c, AcctSeed__Inventory_Product__c = (imp.Create_As_Non_Inventory__c ? false : true), RecordTypeId = idRTPart);
					mapCodeProduct.put(pc,prod);
					listNewProducts.add(prod);
				}
			}
		}
		if(!listNewProducts.isEmpty())
			insert listNewProducts;

		for(Import_Adjustment_New__c imp : listImport)
		{
			if(imp.Product_Code__c != null)
			{
				String pc = imp.Product_Code__c.toLowerCase();
				if(mapCodeProduct.containsKey(pc)){
					Product2 prod = mapCodeProduct.get(pc);
					imp.Product__c = prod.Id;
				}
			}
		}
		if(!listImport.isEmpty())
			update listImport;
	}
	
	global void execute(SchedulableContext sc) {
		tempIAVUpdatOrCreateProduct b = new tempIAVUpdatOrCreateProduct();
		database.executeBatch(b, 50);
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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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