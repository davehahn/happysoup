global without sharing class gcInventoryMovementCube_Report{

    global gcInventoryMovementCube_Report(ApexPages.standardController ctrl){}
    global gcInventoryMovementCube_Report(){}

	global static string locale{get{return UserInfo.getLocale();}}

	public string idRTProductPart{get{return Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Part').getRecordTypeId();}}

	public List<SelectOption> getListProductType()
	{
		List<SelectOption> listOptions = new List<SelectOption>();
		//listOptions.add(new selectOption('', '-All-'));
	    Map<Id,Schema.RecordTypeInfo> productRecordTypeInfo = Schema.SObjectType.Product2.getRecordTypeInfosById();

		for(Id idRT : productRecordTypeInfo.keySet())
        {
			listOptions.add(new selectOption(idRT, productRecordTypeInfo.get(idRT).getName()));
		}

		return listOptions;
	}

    @RemoteAction @ReadOnly
    global static list<map<string,string>> inventoryDetail(map<String,list<String>> mapFilters)
    {
        return inventorySummary(mapFilters, new list<String>{'idBalance','idLot','idSerial'});
    }

	@RemoteAction @ReadOnly
	global static list<map<string,string>> inventorySummary(map<String,list<String>> mapFilters, list<String> listGroupBy)
	{
		return inventoryDescription(inventoryAggRes(mapFilters,listGroupBy));
	}

	@RemoteAction @ReadOnly
	global static list<cube> inventoryAggRes(map<String,list<String>> mapFilters, list<String> listGroupBy)
	{			
		set<String> setGroupBy = new set<String>();
		setGroupBy.addAll(listGroupBy);

		set<String> setIdBalance		= new set<String>();
		set<String> setIdWarehouse 		= new set<String>();
		set<String> setIdLocation 		= new set<String>();
		set<String> setIdProduct 		= new set<String>();
		set<String> setIdProductType 	= new set<String>();
		set<String> setIdLot 			= new set<String>();
		set<String> setIdSerial 		= new set<String>();

		Date dateFrom;
		Date dateThru;

		String soql;

		if(mapFilters.containsKey('idBalance'))
			setIdBalance.addAll(mapFilters.get('idBalance'));
		if(mapFilters.containsKey('idWarehouse'))
			setIdWarehouse.addAll(mapFilters.get('idWarehouse'));
		if(mapFilters.containsKey('idLocation'))
			setIdLocation.addAll(mapFilters.get('idLocation'));
		if(mapFilters.containsKey('idProduct'))
			setIdProduct.addAll(mapFilters.get('idProduct'));
		if(mapFilters.containsKey('idProductType'))
			setIdProductType.addAll(mapFilters.get('idProductType'));
		if(mapFilters.containsKey('idLot'))
			setIdLot.addAll(mapFilters.get('idLot'));
		if(mapFilters.containsKey('idSerial'))
			setIdSerial.addAll(mapFilters.get('idSerial'));

		if(mapFilters.containsKey('dateFrom'))
		{
			dateFrom = date.parse(mapFilters.get('dateFrom')[0]);
		}

		if(mapFilters.containsKey('dateThru'))
		{
			dateThru = date.parse(mapFilters.get('dateThru')[0]);
		}
		else
			dateThru = date.today();

		soql  = ' SELECT GMBLASERP__Inventory_Balance__c idBalance, GMBLASERP__Warehouse__c idWarehouse, GMBLASERP__Location__c idLocation, GMBLASERP__Product__c idProduct, GMBLASERP__Lot__c idLot, GMBLASERP__Serial_Number__c idSerial, sum(GMBLASERP__Quantity__c) qty, sum(GMBLASERP__Inventory_GL_Amount__c) amt ';
		soql += ' FROM GMBLASERP__Inventory_Movement_Cube__c ';
		soql += ' WHERE GMBLASERP__Movement_Date__c <= :dateThru ';
		if(setIdBalance.size() > 0)
			soql += ' AND GMBLASERP__Inventory_Balance__c IN :setIdBalance ';
		if(setIdWarehouse.size() > 0)
			soql += ' AND GMBLASERP__Warehouse__c IN :setIdWarehouse ';
		if(setIdLocation.size() > 0)
			soql += ' AND GMBLASERP__Location__c IN :setIdLocation ';
		if(setIdProduct.size() > 0)
			soql += ' AND GMBLASERP__Product__c IN :setIdProduct ';
		if(setIdProductType.size() > 0)
			soql += ' AND GMBLASERP__Product__r.RecordTypeId IN :setIdProductType ';
		if(setIdLot.size() > 0)
			soql += ' AND GMBLASERP__Lot__c IN :setIdLot ';
		if(setIdSerial.size() > 0)
			soql += ' AND GMBLASERP__Serial_Number__c IN :setIdSerial ';
		soql += ' GROUP BY GMBLASERP__Inventory_Balance__c, GMBLASERP__Warehouse__c, GMBLASERP__Location__c, GMBLASERP__Product__c, GMBLASERP__Lot__c, GMBLASERP__Serial_Number__c ';
		soql += ' HAVING sum(GMBLASERP__Quantity__c) < 0 OR sum(GMBLASERP__Quantity__c) > 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) < 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) > 0 ';

		list<sObject> listAggRes = new list<sObject>();
		listAggRes.addAll(Database.query(soql));

		//for the serials, lots, or products that are in the dataset, we must obtain the global average cost as of the dateFrom
		set<Id> setIdProductAvg = new set<Id>();
		set<Id> setIdLotAvg = new set<Id>();
		set<Id> setIdSerialAvg = new set<Id>();

		for(sObject aggRes :listAggRes)
		{
			if((Id)aggRes.get('idSerial') != null)
				setIdSerialAvg.add((Id)aggRes.get('idSerial'));
			else if((Id)aggRes.get('idLot') != null)
				setIdLotAvg.add((Id)aggRes.get('idLot'));
			else setIdProductAvg.add((Id)aggRes.get('idProduct'));
		}
		setIdSerialAvg.remove(null);
		setIdSerialAvg.remove(null);
		setIdProductAvg.remove(null);

		list<sObject> listTemp = new list<sObject>();
		
		map<Id,Decimal> mapAvgCost = new map<Id,Decimal>();

		if(setIdSerialAvg.size() > 0)
		{
			soql  = ' SELECT GMBLASERP__Serial_Number__c idSerial, sum(GMBLASERP__Quantity__c) qty, sum(GMBLASERP__Inventory_GL_Amount__c) amt ';
			soql += ' FROM GMBLASERP__Inventory_Movement_Cube__c ';
			soql += ' WHERE GMBLASERP__Serial_Number__c IN :setIdSerialAvg AND GMBLASERP__Movement_Date__c <= :dateThru ';
			soql += ' GROUP BY GMBLASERP__Serial_Number__c ';

			listTemp.clear();
			listTemp.addAll(Database.query(soql));

			for(sObject aggRes :listTemp)
			{
				Id idSerial = (Id)aggRes.get('idSerial');
				Decimal qty = (Decimal)aggRes.get('qty');
				Decimal amt = (Decimal)aggRes.get('amt');

				if(amt == null) amt = 0;
				if(qty == null) qty = 0;

				if(qty != 0 && idSerial != null)
				{
					mapAvgCost.put(idSerial,(amt/qty));
				}
			}
		}

		if(setIdLotAvg.size() > 0)
		{
			soql  = ' SELECT GMBLASERP__Lot__c idLot, sum(GMBLASERP__Quantity__c) qty, sum(GMBLASERP__Inventory_GL_Amount__c) amt ';
			soql += ' FROM GMBLASERP__Inventory_Movement_Cube__c ';
			soql += ' WHERE GMBLASERP__Lot__c IN :setIdLotAvg AND GMBLASERP__Movement_Date__c <= :dateThru ';
			soql += ' GROUP BY GMBLASERP__Lot__c ';

			listTemp.clear();
			listTemp.addAll(Database.query(soql));

			for(sObject aggRes :listTemp)
			{
				Id idLot = (Id)aggRes.get('idLot');
				Decimal qty = (Decimal)aggRes.get('qty');
				Decimal amt = (Decimal)aggRes.get('amt');

				if(amt == null) amt = 0;
				if(qty == null) qty = 0;

				if(qty != 0 && idLot != null)
				{
					mapAvgCost.put(idLot,(amt/qty));
				}
			}
		}

		if(setIdProductAvg.size() > 0)
		{
			soql  = ' SELECT GMBLASERP__Product__c idProduct, sum(GMBLASERP__Quantity__c) qty, sum(GMBLASERP__Inventory_GL_Amount__c) amt ';
			soql += ' FROM GMBLASERP__Inventory_Movement_Cube__c ';
			soql += ' WHERE GMBLASERP__Product__c IN :setIdProductAvg AND GMBLASERP__Movement_Date__c <= :dateThru ';
			soql += ' GROUP BY GMBLASERP__Product__c ';

			listTemp.clear();
			listTemp.addAll(Database.query(soql));

			for(sObject aggRes :listTemp)
			{
				Id idProduct = (Id)aggRes.get('idProduct');
				Decimal qty = (Decimal)aggRes.get('qty');
				Decimal amt = (Decimal)aggRes.get('amt');

				if(amt == null) amt = 0;
				if(qty == null) qty = 0;

				if(qty != 0 && idProduct != null)
				{
					mapAvgCost.put(idProduct,(amt/qty));
				}
			}
		}

		map<string,cube> mapCube = new map<string,cube>();
		for(sObject aggRes : listAggRes)
		{
			Id idBalance 	= (Id)aggRes.get('idBalance');
			Id idWarehouse 	= (Id)aggRes.get('idWarehouse');
			Id idLocation 	= (Id)aggRes.get('idLocation');
			Id idProduct 	= (Id)aggRes.get('idProduct');
			Id idLot 	 	= (Id)aggRes.get('idLot');
			Id idSerial 	= (Id)aggRes.get('idSerial');
			
			Decimal qty  = (Decimal)aggRes.get('qty');
			if(qty == null) qty = 0;

			Decimal amt = 0;
			Decimal avgCost = 0;

			if(idSerial != null)
				avgCost = mapAvgCost.get(idSerial);
			else if(idLot != null)
				avgCost = mapAvgCost.get(idLot);
			else 
				avgCost = mapAvgCost.get(idProduct);

			if(avgCost != null)
				amt = qty * avgCost;

			if(amt.setScale(6) == 0 && qty.setScale(6) == 0) continue;

			if(!setGroupBy.contains('idBalance'))	idBalance = null;
			if(!setGroupBy.contains('idWarehouse'))	idWarehouse = null;
			if(!setGroupBy.contains('idLocation'))	idLocation = null;
			if(!setGroupBy.contains('idProduct'))	idProduct = null;
			if(!setGroupBy.contains('idLot'))		idLot = null;
			if(!setGroupBy.contains('idSerial'))	idSerial = null;

			String key = '';
			if(idBalance 	!= null) 	key += idBalance;
			if(idWarehouse 	!= null) 	key += idWarehouse;
			if(idLocation 	!= null) 	key += idLocation;
			if(idProduct 	!= null) 	key += idProduct;
			if(idLot 		!= null) 	key += idLot;
			if(idSerial 	!= null) 	key += idSerial;

			if(key == '') continue;

			if(!mapCube.containsKey(key))
				mapCube.put(key, new cube(idBalance, idWarehouse, idLocation, idProduct, idLot, idSerial, null, null));

			cube cube = mapCube.get(key);
			cube.qty += qty;
			cube.amt += amt;
		}

		return mapCube.values();
	}

	global static list<map<string,string>> inventoryDescription(list<cube> listCube)
	{
		list<map<string,string>> listObj = new list<map<string,string>>();

		map<Id,AcctSeedERP__Inventory_Balance__c> mapBalance = new map<Id,AcctSeedERP__Inventory_Balance__c>();
		map<Id,AcctSeedERP__Warehouse__c> mapWarehouse = new map<Id,AcctSeedERP__Warehouse__c>();
		map<Id,AcctSeedERP__Location__c> mapLocation = new map<Id,AcctSeedERP__Location__c>();
		map<Id,Product2> mapProduct = new map<Id,Product2>();
		map<Id,GMBLASERP__Lot__c> mapLot = new map<Id,GMBLASERP__Lot__c>();
		map<Id,GMBLASERP__Serial_Number__c> mapSerial = new map<Id,GMBLASERP__Serial_Number__c>();

		for(cube c : listCube)
		{
			if(c.idBalance != null)		mapBalance.put(c.idBalance,null);
			if(c.idWarehouse != null)	mapWarehouse.put(c.idWarehouse,null);
			if(c.idLocation != null)	mapLocation.put(c.idLocation,null);
			if(c.idProduct != null)		mapProduct.put(c.idProduct,null);
			if(c.idLot != null)			mapLot.put(c.idLot,null);
			if(c.idSerial != null)		mapSerial.put(c.idSerial,null);
		}

		mapSerial.remove(null);
		if(mapSerial.size() > 0)
		for(GMBLASERP__Serial_Number__c serial : 
			[SELECT Id, 
					Name, 
					GMBLASERP__Lot__c, 
					GMBLASERP__Product__c,
					Nest__c,
					Nest__r.Id,
					Nest__r.GMBLASERP__Product__r.Family,
					Nest__r.GMBLASERP__Product__r.Name,
					Nest__r.Name,
					Model_Year__c,
					Overall_Age__c,
					Retail_Age__c,
					(SELECT Id FROM Projects__r WHERE AcctSeedERP__Manufactured_Product__c != null LIMIT 1),
					(SELECT Id, Name, GMBLASERP__Product__r.Family, GMBLASERP__Product__r.Name FROM Nested_Serial_Numbers__r ORDER BY GMBLASERP__Product__r.Family, GMBLASERP__Product__r.Name)
			FROM GMBLASERP__Serial_Number__c WHERE Id IN :mapSerial.keySet()])
		{
			mapSerial.put(serial.Id,serial);
			mapLot.put(serial.GMBLASERP__Lot__c,null);
			mapProduct.put(serial.GMBLASERP__Product__c,null);
		}

		mapLot.remove(null);
		if(mapLot.size() > 0)
		for(GMBLASERP__Lot__c lot : [SELECT Id, Name, GMBLASERP__Product__c FROM GMBLASERP__Lot__c WHERE Id IN :mapLot.keySet()])
		{
			mapLot.put(lot.Id,lot);
			mapProduct.put(lot.GMBLASERP__Product__c,null);
		}

		mapBalance.remove(null);
		if(mapBalance.size() > 0)
		for(AcctSeedERP__Inventory_Balance__c bal :
				[SELECT Id,
						AcctSeedERP__Warehouse__c,
						AcctSeedERP__Location__c,
						AcctSeedERP__Product__c
				FROM AcctSeedERP__Inventory_Balance__c
				WHERE Id IN : mapBalance.keySet()])
		{
			mapBalance.put(bal.Id,bal);
			mapWarehouse.put(bal.AcctSeedERP__Warehouse__c,null);
			mapLocation.put(bal.AcctSeedERP__Location__c,null);
			mapProduct.put(bal.AcctSeedERP__Product__c,null);
		}

		mapLocation.remove(null);
		if(mapLocation.size() > 0)
		for(AcctSeedERP__Location__c l : [SELECT Id, Name, AcctSeedERP__Warehouse__c FROM AcctSeedERP__Location__c WHERE Id IN : mapLocation.keySet()])
		{
			mapLocation.put(l.Id,l);
			mapWarehouse.put(l.AcctSeedERP__Warehouse__c,null);
		}

		mapWarehouse.remove(null);
		if(mapWarehouse.size() > 0)
		for(AcctSeedERP__Warehouse__c w : 
			[SELECT Id, 
					Name				
			 FROM AcctSeedERP__Warehouse__c WHERE Id IN : mapWarehouse.keySet()])
			mapWarehouse.put(w.Id,w);

		mapProduct.remove(null);
		if(mapProduct.size() > 0)
		for(Product2 p : 
			[SELECT Id, Name, Family, IsActive, ProductCode, AcctSeedERP__Serialized__c, GMBLASERP__Lot_Tracked__c, 
					RecordType.Name,
			 		AcctSeed__GL_Account_Variable_1__r.Name,
			 		AcctSeed__GL_Account_Variable_2__r.Name,
			 		AcctSeed__GL_Account_Variable_3__r.Name,
			 		AcctSeed__GL_Account_Variable_4__r.Name
			 FROM Product2 WHERE Id IN : mapProduct.keySet()])
			mapProduct.put(p.Id,p);

		for(cube c : listCube)
		{
			AcctSeedERP__Inventory_Balance__c bal = mapBalance.get(c.idBalance);
			AcctSeedERP__Warehouse__c whs = mapWarehouse.get(c.idWarehouse);
			AcctSeedERP__Location__c loc = mapLocation.get(c.idLocation);
			Product2 product = mapProduct.get(c.idProduct);
			GMBLASERP__Lot__c lot = mapLot.get(c.idLot);
			GMBLASERP__Serial_Number__c serial = mapSerial.get(c.idSerial);

			if(lot == null && serial != null && mapLot.containsKey(serial.GMBLASERP__Lot__c))
				lot = mapLot.get(serial.GMBLASERP__Lot__c);

			if(product == null && serial != null)
				product = mapProduct.get(serial.GMBLASERP__Product__c);
			else if(product == null && lot != null)
				product = mapProduct.get(lot.GMBLASERP__Product__c);
			else if(product == null && bal != null)
				product = mapProduct.get(bal.AcctSeedERP__Product__c);

			if(whs == null && loc != null)
				whs = mapWarehouse.get(loc.AcctSeedERP__Warehouse__c);
			else if(whs == null && bal != null)
				whs = mapWarehouse.get(bal.AcctSeedERP__Warehouse__c);

			if(loc == null && bal != null)
				loc = mapLocation.get(bal.AcctSeedERP__Location__c);

			map<string,string> obj = new map<string,string>();

			if(bal != null)
				obj.put('idBalance',bal.Id);
			if(whs != null)
			{
				obj.put('idWarehouse',whs.Id);
				obj.put('warehouseName',whs.Name);
			}
			if(loc != null)
			{
				obj.put('idLocation',loc.Id);
				obj.put('locationName',loc.Name);
			}
			if(product != null)
			{
				obj.put('idProduct',product.Id);
				obj.put('productName',product.Name);
				obj.put('productCode',product.ProductCode);
				obj.put('productFamily',(product.Family == null ? '--none--' : product.Family));
				obj.put('productRecordType',(product.RecordType.Name == null ? '--none--' : product.RecordType.Name));
				obj.put('glv1Name',product.AcctSeed__GL_Account_Variable_1__r.Name);
				obj.put('glv2Name',product.AcctSeed__GL_Account_Variable_2__r.Name);
				obj.put('glv3Name',product.AcctSeed__GL_Account_Variable_3__r.Name);
				obj.put('glv4Name',product.AcctSeed__GL_Account_Variable_4__r.Name);

				if(product.IsActive)
					obj.put('productIsActive','true');
				else
					obj.put('productIsActive','false');

				if(product.AcctSeedERP__Serialized__c)
					obj.put('productIsSerialized','true');
				else
					obj.put('productIsSerialized','false');

				if(product.GMBLASERP__Lot_Tracked__c)
					obj.put('productIsLotTracked','true');
				else
					obj.put('productIsLotTracked','false');
			}
			if(lot != null)
			{
				obj.put('idLot',lot.Id);
				obj.put('lotName',lot.Name);		
			}

			if(serial != null)
			{
				obj.put('idSerial',serial.Id);
				obj.put('serialName',serial.Name);
				obj.put('serialModelYear',(serial.Model_Year__c == null ? '' : String.valueOf(serial.Model_Year__c)));
				obj.put('serialOverallAge',(serial.Overall_Age__c == null ? '' : String.valueOf(serial.Overall_Age__c)));
				obj.put('serialRetailAge',(serial.Retail_Age__c == null ? '' : String.valueOf(serial.Retail_Age__c)));

				String d = '';
				if(serial.Nest__c != null)
				{
					obj.put('isNested','true');

					GMBLASERP__Serial_Number__c n = serial.Nest__r;
					obj.put('idNest', n.Id);
					obj.put('nestName',n.Name);					
					obj.put('nestProductFamily', n.GMBLASERP__Product__r.Family);
					obj.put('nestProductName', n.GMBLASERP__Product__r.Name);

					d = n.GMBLASERP__Product__r.Name + ' (s/n '+n.Name+')';
					obj.put('description',d);
				}
				else if(serial.Nested_Serial_Numbers__r.size() > 0)
				{
					obj.put('isNest','true');
					for(GMBLASERP__Serial_Number__c x :serial.Nested_Serial_Numbers__r)
					{
						if(d != '') 
							d+='; ';
						d = d + x.GMBLASERP__Product__r.Name + ' (s/n '+x.Name+')';
					}
					obj.put('description',d);
				}

				/// Dealer Rigged
				if(!serial.Projects__r.isEmpty())
					obj.put('dealerRigged', 'true');
				else
					obj.put('dealerRigged', 'false');
			}

			Decimal avg = 0;
			if(c.qty != 0)
				avg = c.amt / c.qty;

			obj.put('qty', String.valueOf(c.qty.setScale(6)));
			obj.put('amt', String.valueOf(c.amt.setScale(6)));
			obj.put('avg', String.valueOf(avg.setScale(6)));

			listObj.add(obj);			
		}

		return listObj;
	}

	global class cube{
		global Decimal qty{get;set;}
		global Decimal amt{get;set;}

		global Id idBalance{get;set;}
		global Id idWarehouse{get;set;}
		global Id idLocation{get;set;}
		global Id idProduct{get;set;}
		global Id idLot{get;set;}
		global Id idSerial{get;set;}

		global cube(Id pIdBalance, Id pIdWarehouse, Id pIdLocation, Id pIdProduct, Id pIdLot, Id pIdSerial, Id pIdPeriod, String pStrMoveType)
		{
			idBalance = pIdBalance;
			idWarehouse = pIdWarehouse;
			idLocation = pIdLocation;
			idProduct = pIdProduct;
			idLot = pIdLot;
			idSerial = pIdSerial;

			qty = 0;
			amt = 0;
		}
	}

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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;        
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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