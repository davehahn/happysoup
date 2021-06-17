@isTest(SeeAllData=TRUE)
private class gcTest_Product{

	static testMethod void test1()
	{
		//gc
		// Product.coverage();
		//gcProduct_UpdateMRPQty.coverage();
	}

	/*static testMethod void test2()
	{
		gcProduct.disableTrigger = true;
		gcProduct.disableTrigger = false;
		gcProduct.disableTrigger = null;
		Boolean bool = gcProduct.disableTrigger;

		map<Id,String> mapRecordType = new map<Id,String>();
		for(RecordType rt : [SELECT Id, Name FROM RecordType WHERE sObjectType = 'Product2'])
		{
			mapRecordType.put(rt.Id,rt.Name);
		}

		//Id idGL = [SELECT Id FROM AcctSeed__GL_Account__c WHERE AcctSeed__Type__c = 'Expense' AND AcctSeed__Active__c = true LIMIT 1][0].Id;

		list<Product2> listP = new list<Product2>();
		for(Id idRecordType : mapRecordType.keySet())
		{
			Product2 p = new Product2();
			p.Name = 'Test Product';
			p.RecordTypeId = idRecordType;
			p.AcctSeed__Unit_Cost__c = null;
			listP.add(p);
		}

		insert listP;
		update listP;
		delete listP;
	}*/
}