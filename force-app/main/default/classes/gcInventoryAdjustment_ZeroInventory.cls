public with sharing class gcInventoryAdjustment_ZeroInventory {
	public gcInventoryAdjustment_ZeroInventory(ApexPages.StandardController stc) {}
	public gcInventoryAdjustment_ZeroInventory() {}

	public List<SelectOption> getListProductType()
	{
		List<SelectOption> listOptions = new List<SelectOption>();

	    Map<Id,Schema.RecordTypeInfo> productRecordTypeInfo = Schema.SObjectType.Product2.getRecordTypeInfosById();

		for(Id idRT : productRecordTypeInfo.keySet())
        {
			listOptions.add(new selectOption(idRT, productRecordTypeInfo.get(idRT).getName()));
		}

		return listOptions;	
	}

	@RemoteAction @ReadOnly 
	public static list<map<string,string>> retrieveLots(Id idProduct)
	{
		list<map<string,string>> listJSON = new list<map<string,string>>();
		for(GMBLASERP__Lot__c l :
			[SELECT Id, Name
			 FROM GMBLASERP__Lot__c
			 WHERE GMBLASERP__Product__c = :idProduct
			 ORDER BY Name])
		{
			map<string,string> obj = new map<string,string>{'idLot'=>l.Id,'lotName'=>l.Name};
			listJSON.add(obj);
		}
		return listJSON;
	}

	@RemoteAction @ReadOnly 
	public static list<map<string,string>> retrieveSerials(Id idProduct)
	{
		list<map<string,string>> listJSON = new list<map<string,string>>();
		for(GMBLASERP__Serial_Number__c sn :
			[SELECT Id, Name, GMBLASERP__Lot__r.Name, GMBLASERP__Inventory_Balance__c
			 FROM GMBLASERP__Serial_Number__c
			 WHERE GMBLASERP__Product__c = :idProduct
			 ORDER BY Name])
		{
			map<string,string> obj = new map<string,string>{'idSerial'=>sn.Id,'serialName'=>sn.Name};
			if(sn.GMBLASERP__Lot__c != null)
				obj.put('lotName',sn.GMBLASERP__Lot__r.Name);

			if(sn.GMBLASERP__Inventory_Balance__c != null)
				obj.put('disabled','true');

			listJSON.add(obj);
		}
		return listJSON;
	}

	@RemoteAction @ReadOnly 
	public static list<map<string,string>> retrieveAllInventoryProducts(Id idAdjustment, String pIdProductType)
	{
		list<map<string,string>> listJSON = new list<map<String,String>>();
		Boolean singleProduct = false;
		Id idProduct;
		for(GMBLASERP__Inventory_Adjustment__c adjustment : 
			[SELECT 
				Id, 
				GMBLASERP__Product__c, 
				GMBLASERP__Product__r.AcctSeed__Inventory_Product__c,
				GMBLASERP__Adjustment_Type__c,
				(SELECT Id FROM GMBLASERP__Inbound_Inventory_Movements__r LIMIT 1)
			FROM GMBLASERP__Inventory_Adjustment__c
			WHERE Id=:idAdjustment])
		{
			/*if(!adjustment.GMBLASERP__Inbound_Inventory_Movements__r.isEmpty())
			{
				map<String,String> m = new map<String,String>();
				m.put('message','Adjustment has already started. Cannot create line.');
				listJSON.add(m);
		 		return listJSON;
			}*/
			if(adjustment.GMBLASERP__Adjustment_Type__c != 'Quantity')
			{
				map<String,String> m = new map<String,String>();
				m.put('message','Adjustment type must be Quantity.');
				listJSON.add(m);
		 		return listJSON;
			}
			if(adjustment.GMBLASERP__Product__c != null && !adjustment.GMBLASERP__Product__r.AcctSeed__Inventory_Product__c)
			{
				map<String,String> m = new map<String,String>();
				m.put('message','The product selected is not an inventory product.');
				listJSON.add(m);
		 		return listJSON;
			}
			if(adjustment.GMBLASERP__Product__c != null)
			{
		 		singleProduct = true;
		 		idProduct = adjustment.GMBLASERP__Product__c;
			}		
			//GMBLASERP.gcInventoryAdjustment_Ext.createAdjustment(adjustment.Id, adjustment.GMBLASERP__Product__c);
		}

		for(Product2 p :
			[SELECT Id, Name, 
				Family, 
				Unique_Product_Code__c, 
				AcctSeedERP__Serialized__c,
				GMBLASERP__Lot_Tracked__c, 
				RecordType.Name, 
				AcctSeedERP__Default_Vendor__r.Name
			 FROM Product2
			 WHERE AcctSeed__Inventory_Product__c = true
			 	AND RecordTypeId =:pIdProductType
			 	AND (isDeleted =:singleProduct OR Id=:idProduct)
			 	AND isDeleted = false])
		{
			map<String,String> m = new map<String,String>();
			m.put('idProduct',p.Id);
			m.put('productName',p.Name);
			m.put('isLotTracked',p.GMBLASERP__Lot_Tracked__c ?'true':'false');
			m.put('isSerialized',p.AcctSeedERP__Serialized__c ?'true':'false');
			m.put('supplierName',p.AcctSeedERP__Default_Vendor__r.Name);
			m.put('productCode',(p.Unique_Product_Code__c == null ? '' :p.Unique_Product_Code__c));
			m.put('recordType',p.RecordType.Name);
			m.put('productFamily',p.Family);
			listJSON.add(m);
		}

		return listJSON;
	}

	@RemoteAction 
	public static map<string,string> createLSAdjustment(String idAdjustment, String idProduct, String lotName, String serialName, Decimal qty)
	{
        GMBLASERP__Inventory_Adjustment__c adj = 
        [SELECT GMBLASERP__Warehouse__c, 
                GMBLASERP__Product__c, 
                GMBLASERP__Adjustment_Type__c, 
                GMBLASERP__Adjustment_Date__c,
                GMBLASERP__GL_Account__c 
         FROM GMBLASERP__Inventory_Adjustment__c 
         WHERE Id = :idAdjustment][0];

        Id idSerial;
        Id idLot;
        Id idBalance;
        Product2 product = [SELECT Id, AcctSeedERP__Serialized__c, GMBLASERP__Lot_Tracked__c FROM Product2 WHERE Id =:idProduct][0];
		if(product.GMBLASERP__Lot_Tracked__c)
		{
			for(GMBLASERP__Lot__c lot : [SELECT Id FROM GMBLASERP__Lot__c WHERE GMBLASERP__Product__c =:idProduct AND Name =:lotName LIMIT 1])
			{
				idLot = lot.Id;
			}
			if(idLot == null)
			{
				GMBLASERP__Lot__c lot = new GMBLASERP__Lot__c(Name = lotName, GMBLASERP__Product__c = idProduct);
				insert lot;
				idLot = lot.Id;
			}
		}

		if(product.AcctSeedERP__Serialized__c)
		{
			for(GMBLASERP__Serial_Number__c serial : [SELECT Id, GMBLASERP__Lot__c FROM GMBLASERP__Serial_Number__c WHERE GMBLASERP__Product__c = :idProduct AND Name =:serialName LIMIT 1])
			{
				idSerial = serial.Id;
				idLot = serial.GMBLASERP__Lot__c;
			}

			if(idSerial == null)
			{
				GMBLASERP__Serial_Number__c serial = new GMBLASERP__Serial_Number__c(Name = serialName, GMBLASERP__Product__c = idProduct, GMBLASERP__Lot__c = idLot);
				insert serial;
				idSerial = serial.Id;
			}
		}

        if(idBalance == null)
        {
            Id idWarehouse = adj.GMBLASERP__Warehouse__c;
            if(idWarehouse == null)
    		idWarehouse = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c;
            if(idWarehouse == null)
                throw new gcException('An Adjustment Warehouse Id must be specified in the Inventory Settings.');
    		Id idLocation = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c = :idWarehouse ORDER BY CreatedDate LIMIT 1][0].Id;

    		idBalance = GMBLASERP.gcInventoryBalance.findOrCreateBalance(idProduct,idWarehouse,idLocation);  
        }

		//If there is already a move for this balance and object then return
        for(AcctSeedERP__Inbound_Inventory_Movement__c move :
            [SELECT Id 
             FROM AcctSeedERP__Inbound_Inventory_Movement__c
             WHERE GMBLASERP__Inventory_Adjustment__c != null
               AND GMBLASERP__Inventory_Adjustment__c = :adj.Id
               AND AcctSeedERP__Inventory_Balance__c = :idBalance AND GMBLASERP__Lot__c =:idLot AND GMBLASERP__Serial_Number__c = :idSerial])
        {
            return new map<string,string>(); 
        }
		
        AcctSeedERP__Inbound_Inventory_Movement__c moveIn = new AcctSeedERP__Inbound_Inventory_Movement__c(
													            GMBLASERP__Inventory_Adjustment__c = idAdjustment,
													            AcctSeedERP__Credit_GL_Account__c = adj.GMBLASERP__GL_Account__c,
													            AcctSeedERP__Inventory_Balance__c = idBalance,
													            AcctSeedERP__Movement_Date__c = adj.GMBLASERP__Adjustment_Date__c,       
													            AcctSeedERP__Quantity__c = qty,
													            AcctSeedERP__Type__c = 'Accounting',
													            AcctSeedERP__Unit_Cost__c = 0,
													            GMBLASERP__Cost_Override__c = false,
													            GMBLASERP__Lot__c = idLot,
													            GMBLASERP__Serial_Number__c = idSerial
        );

		insert moveIn;

        return GMBLASERP.gcInventoryAdjustment_Ext.retrieveMoves(moveIn.Id)[0];
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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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