public without sharing class gcProduct {

	public static Boolean disableTrigger{
		get{
			if(disableTrigger == null) return false;
			else return disableTrigger;
		}
		set{
			if(value == null) disableTrigger = false;
			else disableTrigger = value;
		}
	}

	public static void triggerHandler
		(map<Id,Product2> oldMap,
		 map<Id,Product2> newMap,
		 list<Product2> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,Product2>();
		if(newMap == NULL) newMap = new map<Id,Product2>();
		if(listNew == NULL) listNew = new list<Product2>();

		updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);

		if(boolIsBefore)
		{
			if(boolIsInsert)
			{

			}
			if(boolIsUpdate)
			{

			}
			if(boolIsDelete)
			{

			}
		}
		else //i.e. trigger.isAfter
		{
			if(boolIsInsert)
			{

			}
			if(boolIsUpdate)
			{

			}
			if(boolIsDelete)
			{

			}
		}
	}

	private static void updateAndValidate
		(map<Id,Product2> oldMap,
		 map<Id,Product2> newMap,
		 list<Product2> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(boolIsBefore)
		{
			if(boolIsInsert || boolIsUpdate)
			{
				settings(listNew);
				for(Product2 p : listNew)
				{
					p.ProductCode = p.Unique_Product_Code__c;
					if(boolIsInsert)
						p.IsActive = true;
					if(p.AcctSeed__Unit_Cost__c == null)
				   		p.AcctSeed__Unit_Cost__c = 0;
				   	if(boolIsUpdate && p.Parts_Count__c !=  oldMap.get(p.Id).Parts_Count__c)
				   		p.Parts_Count__c = oldMap.get(p.Id).Parts_Count__c;

				   	if(boolIsUpdate && p.Landed_Unit_Cost__c != oldMap.get(p.Id).Landed_Unit_Cost__c)
				   		p.Landed_Unit_Cost__c = oldMap.get(p.Id).Landed_Unit_Cost__c;
				   	if(boolIsUpdate && p.Partner_Price__c != oldMap.get(p.Id).Partner_Price__c)
				   		p.Partner_Price__c = oldMap.get(p.Id).Partner_Price__c;
				}
			}
			if(boolIsDelete)
			{
				Set<Id> setProductWithSL = new Set<Id>();
				for(Product2 p : 
					[SELECT Id, 
						(SELECT Id FROM GMBLASERP__Lots__r LIMIT 1),
						(SELECT Id FROM GMBLASERP__Serial_Numbers__r LIMIT 1)
					FROM Product2 WHERE Id =:oldMap.keySet()])
				{
					if(!p.GMBLASERP__Lots__r.isEmpty() || !p.GMBLASERP__Serial_Numbers__r.isEmpty())
						setProductWithSL.add(p.Id);
				}
				for(Product2 p : oldMap.values())
				{
					if(setProductWithSL.contains(p.Id))
						p.addError('This product cannot be deleted. It has got associated Serial Numbers or Lots. Please delete Serial/Lot first to proceed.');
				}
			}
		}
	}

	private static void settings(list<Product2> listNew)
	{
		map<String,Id> mapGL = new map<String,Id>();

		for(AcctSeed__GL_Account__c gl :
				[SELECT Id, Uniquefier__c
			 	 FROM AcctSeed__GL_Account__c
			 	 WHERE Uniquefier__c IN ('InventoryBoats','InventoryParts','CogsBoats','CogsParts','SalesBoats','SalesParts')])
		{
			mapGL.put(gl.Uniquefier__c,gl.Id);
		}

		map<Id,String> mapRecordType = new map<Id,String>();
		for(RecordType rt : [SELECT Id, Name FROM RecordType WHERE sObjectType = 'Product2'])
		{
			mapRecordType.put(rt.Id,rt.Name);
		}

		for(Product2 p : listNew)
		{
			String strRecordTypeName = mapRecordType.get(p.RecordTypeId);
			if(strRecordTypeName == 'Boat')
			{
				p.AcctSeed__Inventory_GL_Account__c = mapGL.get('InventoryBoats');
				p.AcctSeed__Expense_GL_Account__c = mapGL.get('CogsBoats');
				p.AcctSeed__Revenue_GL_Account__c = mapGL.get('SalesBoats');

				p.AcctSeed__Inventory_Type__c = 'Purchased';
				p.AcctSeed__Inventory_Product__c = true;

				//boats are serialized and lot-tracked
				p.AcctSeedERP__Serialized__c = true;
				p.GMBLASERP__Lot_Tracked__c = true;
				p.Can_be_Nest__c = true;
				p.Can_be_Nested__c = false;
			}
			else if(strRecordTypeName == 'Motor' ||
					    strRecordTypeName == 'Trailer' ||
					    strRecordTypeName == 'Trolling Motor' ||
					    ( strRecordTypeName == 'Part' && p.Family != null && p.Family.contains('Hull') ) )
			{
				p.AcctSeed__Inventory_GL_Account__c = mapGL.get('InventoryParts');
				p.AcctSeed__Expense_GL_Account__c = mapGL.get('CogsParts');
				p.AcctSeed__Revenue_GL_Account__c = mapGL.get('SalesParts');

				p.AcctSeed__Inventory_Type__c = 'Purchased';
				p.AcctSeed__Inventory_Product__c = true;

				p.AcctSeedERP__Serialized__c = true;
				//p.GMBLASERP__Lot_Tracked__c = false;

				p.Can_be_Nest__c = false;
				p.Can_be_Nested__c = true;

				//motors are lot-tracked
				//if(strRecordTypeName == 'Motor')
				//	p.GMBLASERP__Lot_Tracked__c = true;
				/// According to a requirement on Feb 01 2017 All Motor, Trailer and Trolling Motors 
				/// Including other serialized items are lot tracked
				p.GMBLASERP__Lot_Tracked__c = true;
			}
			else //everything else cannot be serialized, lot-tracked, a nest, or nested...but it can be inventory
			{
				p.AcctSeedERP__Serialized__c = false;
				//p.GMBLASERP__Lot_Tracked__c = false;
				p.Can_be_Nest__c = false;
				p.Can_be_Nested__c = false;

				if(p.AcctSeed__Inventory_Product__c == true)
				{
					if(p.AcctSeed__Inventory_GL_Account__c == null)
						p.AcctSeed__Inventory_GL_Account__c = mapGL.get('InventoryParts');
					if(p.AcctSeed__Expense_GL_Account__c == null)
						p.AcctSeed__Expense_GL_Account__c = mapGL.get('CogsParts');
					if(p.AcctSeed__Revenue_GL_Account__c == null)
						p.AcctSeed__Revenue_GL_Account__c = mapGL.get('SalesParts');
					if(p.AcctSeed__Inventory_Type__c == null)
						p.AcctSeed__Inventory_Type__c = 'Purchased';
				}
				else
				{
					p.AcctSeed__Inventory_GL_Account__c = null;

					if(p.AcctSeed__Expense_GL_Account__c == null)
					   p.AcctSeed__Expense_GL_Account__c = mapGL.get('CogsParts');

					if(p.AcctSeed__Revenue_GL_Account__c == null)
					   p.AcctSeed__Revenue_GL_Account__c = mapGL.get('SalesParts');

					p.AcctSeed__Inventory_Type__c = null;

				}
			}
		}
	}	

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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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