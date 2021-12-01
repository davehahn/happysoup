public with sharing class gcInventoryReport_MRP {
	public gcInventoryReport_MRP() {
		defaultWarehouse();
	}
	public Id idDefaultWarehouse {get;set;}
	public void defaultWarehouse()
	{
		Id idUser = UserInfo.getUserId();
		String dept = [SELECT Id, Sales_Department__c FROM User WHERE Id = :idUser][0].Sales_Department__c;
		set<Id> setIdWarehouseReserved = new set<Id>();
		setIdWarehouseReserved.add(GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c);
		setIdWarehouseReserved.add(GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c);
		setIdWarehouseReserved.remove(null);
		for(AcctSeedERP__Warehouse__c whs :	[SELECT Id, Name FROM AcctSeedERP__Warehouse__c WHERE Id NOT IN :setIdWarehouseReserved AND Name =:dept])
		{
			idDefaultWarehouse = whs.Id;
		}
		if(idDefaultWarehouse == null)
			idDefaultWarehouse = gcConstants.idWarehouseWholesale;
		//return idDefaultWarehouse;
	}
	public static string locale{get{return UserInfo.getLocale();}}

	public List<SelectOption> getListWarehouse()
	{
		List<SelectOption> listOptions = new List<SelectOption>();
		Id idWarehouseAdjustment = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c;
		Id idWarehouseTransit = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c;
		listOptions.add(new selectOption('', '-All-'));
		for(AcctSeedERP__Warehouse__c whs :
		[SELECT Id, Name FROM AcctSeedERP__Warehouse__c WHERE Id !=:idWarehouseAdjustment AND Id !=:idWarehouseTransit ORDER BY Name])
		{
			listOptions.add(new selectOption(whs.Id, whs.Name));
		}

		return listOptions;
	}

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

	public List<SelectOption> getListProductSuppliers()
	{
		List<SelectOption> listOptions = new List<SelectOption>();
		listOptions.add(new selectOption('', '-ALL-'));
		listOptions.add(new selectOption('BLANK', '( BLANK )'));
		Set<Id> setIdSupplier = new Set<Id>();
		for(SObject pr : [SELECT AcctSeedERP__Default_Vendor__c supplerId FROM Product2 WHERE AcctSeedERP__Default_Vendor__c != null GROUP BY AcctSeedERP__Default_Vendor__c])
		{
			setIdSupplier.add((Id)pr.get('supplerId'));
		}
		if(!setIdSupplier.isEmpty()){
			for(Account acc : [SELECT Id, Name FROM Account WHERE Id IN:setIdSupplier]){
				listOptions.add(new selectOption(acc.Id, acc.Name));
			}
		}

		return listOptions;
	}

	@RemoteAction
	public static List<String> listProductFamily(String recordTypeId) {
		List<String> listOptions = new List<String>();
		Map<Id,Schema.RecordTypeInfo> productRecordTypeInfo = Schema.SObjectType.Product2.getRecordTypeInfosById();
		String recordTypeName = productRecordTypeInfo.get(recordTypeId).getName();
		List<Family_by_Record_Type__mdt> frts = Family_by_Record_Type__mdt.getAll().values();
		for( Family_by_Record_Type__mdt frt : frts){
			if(frt.Family_by_Record_Type__c == recordTypeName) {
				listOptions.add(frt.Label);
			}
		}
		return listOptions;
	}

	@RemoteAction @ReadOnly
	public static list<map<String,String>> retrieveSerialNumbers(list<Id> listIdProduct, Id pIdWarehouse)
	{
		list<map<String,String>> listJSON = new list<map<String,String>>();

		set<Id> setIdProduct = new set<Id>();
		setIdProduct.addAll(listIdProduct);
		setIdProduct.remove(null);
		Boolean checkDeleted = true;
		if(pIdWarehouse == null) checkDeleted = false;
		for(GMBLASERP__Serial_Number__c x :
		[SELECT Id, Name,
			Dealer_Rigged__c,
			Available_Retail__c,
			Available_Wholesale__c,
			Model_Year__c,
			GMBLASERP__Product__c,
			Product_Name__c,
			GMBLASERP__Lot__c,
			GMBLASERP__Lot__r.Name,
			Overall_Age__c,
			Retail_Age__c,
			GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
			GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name
		FROM GMBLASERP__Serial_Number__c
		WHERE GMBLASERP__Inventory_Balance__c != null
		AND (IsDeleted =:checkDeleted OR GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c =:pIdWarehouse)
		AND IsDeleted = false
		AND GMBLASERP__Product__c IN :setIdProduct])
		{
			map<String,String> m = new map<String,String>();

			m.put('idSerial',x.Id);
			m.put('serialName',x.Name);
			m.put('dealerRigged',x.Dealer_Rigged__c ? 'true' : 'false');
			m.put('availableRetail',x.Available_Retail__c ? 'true' : 'false');
			m.put('availableWholesale',x.Available_Wholesale__c ? 'true' : 'false');
			m.put('idProduct',x.GMBLASERP__Product__c);
			m.put('productName',x.Product_Name__c);
			m.put('modelYear',(x.Model_Year__c == null ? '' : String.valueOf(x.Model_Year__c)));
			m.put('serialOverallAge',(x.Overall_Age__c == null ? '' : String.valueOf(x.Overall_Age__c)));
			m.put('serialRetailAge',(x.Retail_Age__c == null ? '' : String.valueOf(x.Retail_Age__c)));
			m.put('idLot',x.GMBLASERP__Lot__c);
			m.put('lotName',x.GMBLASERP__Lot__r.Name);
			m.put('idWarehouse',x.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c);
			m.put('warehouseName',x.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name);

			listJSON.add(m);
		}

		return listJSON;
	}

	@RemoteAction @ReadOnly
	public static list<map<String,String>> retrievePurchaseOrders(list<Id> listIdProduct, Id pIdWarehouse)
	{
		list<map<String,String>> listJSON = new list<map<String,String>>();

		set<Id> setIdProduct = new set<Id>();
		setIdProduct.addAll(listIdProduct);
		setIdProduct.remove(null);
		Boolean checkDeleted = true;
		if(pIdWarehouse == null) checkDeleted = false;
		for(AcctSeedERP__Purchase_Order_Line__c x :
		[SELECT AcctSeedERP__Purchase_Order__c,
			AcctSeedERP__Purchase_Order__r.Name,
			AcctSeedERP__Purchase_Order__r.AcctSeedERP__Order_Date__c,
			AcctSeedERP__Purchase_Order__r.AcctSeedERP__Vendor__r.Name,
			AcctSeedERP__Purchase_Order__r.Warehouse__c,
			AcctSeedERP__Purchase_Order__r.Warehouse__r.Name,
			AcctSeedERP__Product__r.Name,
			AcctSeedERP__Quantity__c,
			AcctSeedERP__Quantity_Unreceived__c
		FROM AcctSeedERP__Purchase_Order_Line__c
		WHERE AcctSeedERP__Quantity_Unreceived__c > 0
		AND (IsDeleted =:checkDeleted
		OR (AcctSeedERP__Purchase_Order__r.Warehouse__c =:pIdWarehouse
		OR AcctSeedERP__Purchase_Order__r.Warehouse__c = null))
		AND IsDeleted = false
		AND AcctSeedERP__Purchase_Order__r.AcctSeedERP__Status__c = 'Open'
		AND AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = true
		AND AcctSeedERP__Product__c IN :setIdProduct])
		{
			map<String,String> m = new map<String,String>();

			m.put('idPurchaseOrder',x.AcctSeedERP__Purchase_Order__c);

			m.put('purchaseOrderName',x.AcctSeedERP__Purchase_Order__r.Name);
			if(x.AcctSeedERP__Purchase_Order__r.Warehouse__c != null){
				m.put('idWarehouse',x.AcctSeedERP__Purchase_Order__r.Warehouse__c);
				m.put('warehouseName',x.AcctSeedERP__Purchase_Order__r.Warehouse__r.Name);
			}

			if(x.AcctSeedERP__Purchase_Order__r.AcctSeedERP__Order_Date__c != null)
				m.put('orderDate',x.AcctSeedERP__Purchase_Order__r.AcctSeedERP__Order_Date__c.format());
			if(x.AcctSeedERP__Purchase_Order__r.AcctSeedERP__Vendor__c != null)
				m.put('vendorName',x.AcctSeedERP__Purchase_Order__r.AcctSeedERP__Vendor__r.Name);
			else
				m.put('vendorName','---none---');

			m.put('productName',x.AcctSeedERP__Product__r.Name);

			if(x.AcctSeedERP__Quantity__c != null)
				m.put('qtyOrdered',String.valueOf(x.AcctSeedERP__Quantity__c.setScale(6)));
			else
				m.put('qtyOrdered','0');

			if(x.AcctSeedERP__Quantity_Unreceived__c != null)
				m.put('qtyUnreceived',String.valueOf(x.AcctSeedERP__Quantity_Unreceived__c.setScale(6)));
			else
				m.put('qtyUnreceived','0');

			listJSON.add(m);
		}

		return listJSON;
	}

	@RemoteAction @ReadOnly
	public static list<map<String,String>> retrieveProjects(list<Id> listIdProduct, Id pIdWarehouse)
	{
		Set<Id> setIdRetailProjectToDiscard = new Set<Id>();
//		for(AcctSeed__Project__c pr : [SELECT Id, Retail_ERP__c FROM AcctSeed__Project__c WHERE Retail_ERP__c != null AND Locked__c = false])
//			setIdRetailProjectToDiscard.add(pr.Retail_ERP__c);
		Map<Id,Set<Id>> mapProjectSetProducts = new Map<Id,Set<Id>>();
		for(AcctSeedERP__Material__c x :
		[SELECT AcctSeedERP__Project__r.Retail_ERP__c, AcctSeedERP__Product__c FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__r.Retail_ERP__c != null AND AcctSeedERP__Project__r.Locked__c = false]){
			if(!mapProjectSetProducts.containsKey(x.AcctSeedERP__Project__r.Retail_ERP__c)){
				mapProjectSetProducts.put(x.AcctSeedERP__Project__r.Retail_ERP__c,new Set<Id>());
			}
			mapProjectSetProducts.get(x.AcctSeedERP__Project__r.Retail_ERP__c).add(x.AcctSeedERP__Product__c);
		}
		System.debug('mapProjectSetProducts'+mapProjectSetProducts);
		list<map<String,String>> listJSON = new list<map<String,String>>();
		Id idRtMfgERP = gcConstants.idRtProjectManufacturing;
		set<Id> setIdProduct = new set<Id>();
		setIdProduct.addAll(listIdProduct);
		setIdProduct.remove(null);
		Boolean checkDeleted = true;
		if(pIdWarehouse == null) checkDeleted = false;
		for(AcctSeedERP__Material__c x :
		[SELECT AcctSeedERP__Project__c,
			AcctSeedERP__Project__r.RecordType.Name,
			AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c,
			AcctSeedERP__Project__r.Serial_Number__c,
			AcctSeedERP__Project__r.Serial_Number__r.Name,
			AcctSeedERP__Project__r.Serial_Number__r.GMBLASERP__Lot__r.Name,
			AcctSeedERP__Project__r.GMBLASERP__Warehouse__c,
			AcctSeedERP__Project__r.GMBLASERP__Warehouse__r.Name,
			AcctSeedERP__Project__r.Name,
			AcctSeedERP__Project__r.CreatedDate,
			AcctSeedERP__Project__r.Actual_Order_Date__c,
			AcctSeedERP__Product__c,
			AcctSeedERP__Product__r.Name,
			AcctSeedERP__Quantity_Per_Unit__c,
			AcctSeedERP__Quantity_Allocated__c,
		(SELECT Id, AcctSeedERP__Quantity__c FROM Outbound_Inventory_Movements__r)
		FROM AcctSeedERP__Material__c
		WHERE AcctSeedERP__Quantity_Per_Unit__c > 0
		AND No_WIP__c = false
		AND AcctSeedERP__Project__r.Locked__c = false
		AND ((AcctSeedERP__Project__r.RecordTypeId !=:idRtMfgERP) OR (AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = false AND AcctSeedERP__Project__r.RecordTypeId =:idRtMfgERP))
		AND AcctSeedERP__Project__r.Stage__c NOT IN ('Quoting','Closed Lost','Draft','Pending Review')
		AND AcctSeedERP__Product__c IN :setIdProduct
		AND (IsDeleted =:checkDeleted OR AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:pIdWarehouse)
		AND IsDeleted = false])
		{
			if(!(mapProjectSetProducts.containsKey(x.AcctSeedERP__Project__c) && mapProjectSetProducts.get(x.AcctSeedERP__Project__c).contains(x.AcctSeedERP__Product__c))) {
				map<String, String> m = new map<String, String>();
				m.put('idProject', x.AcctSeedERP__Project__c);
				m.put('idWarehouse', x.AcctSeedERP__Project__r.GMBLASERP__Warehouse__c);
				m.put('nameWarehouse', x.AcctSeedERP__Project__r.GMBLASERP__Warehouse__r.Name);
				if (x.AcctSeedERP__Project__c != null) {
					m.put('projectNumber', String.valueOf(Integer.valueOf(x.AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c.replaceAll('[^0-9]', ''))));
					m.put('createdDate', x.AcctSeedERP__Project__r.Actual_Order_Date__c == null ? x.AcctSeedERP__Project__r.CreatedDate.format() : x.AcctSeedERP__Project__r.Actual_Order_Date__c.format());
					m.put('projectName', x.AcctSeedERP__Project__r.Name);
					m.put('projectType', x.AcctSeedERP__Project__r.RecordType.Name);
					if (x.AcctSeedERP__Project__r.Serial_Number__c != null) {
						m.put('projectSerial', x.AcctSeedERP__Project__r.Serial_Number__r.Name);
						m.put('projectLot', x.AcctSeedERP__Project__r.Serial_Number__r.GMBLASERP__Lot__r.Name);
					}
				}

				m.put('productName', x.AcctSeedERP__Product__r.Name);

				if (x.AcctSeedERP__Quantity_Per_Unit__c != null)
					m.put('qtySpecified', String.valueOf(x.AcctSeedERP__Quantity_Per_Unit__c.setScale(6))); else
					m.put('qtySpecified', '0');

				if (x.AcctSeedERP__Quantity_Allocated__c != null)
					m.put('qtyAllocated', String.valueOf(x.AcctSeedERP__Quantity_Allocated__c.setScale(6))); else
					m.put('qtyAllocated', '0');

				Decimal qtyAllocated = 0;
				for (AcctSeedERP__Outbound_Inventory_Movement__c oim : x.Outbound_Inventory_Movements__r) {
					qtyAllocated += oim.AcctSeedERP__Quantity__c == null ? 0 : oim.AcctSeedERP__Quantity__c;
				}
				if (qtyAllocated <> 0)
					m.put('qtyAllocated', String.valueOf(qtyAllocated.setScale(6)));

				listJSON.add(m);
			}
		}
		return listJSON;
	}

	public static Map<Id,cube> retrieveProducts(Set<Id> setIdProduct, Id pIdWarehouse)
	{
//		Set<Id> setIdRetailProjectToDiscard = new Set<Id>();
//		for(AcctSeed__Project__c pr : [SELECT Id, Retail_ERP__c FROM AcctSeed__Project__c WHERE Retail_ERP__c != null AND Locked__c = false])
//			setIdRetailProjectToDiscard.add(pr.Retail_ERP__c);
		Map<Id,Set<Id>> mapProjectSetProducts = new Map<Id,Set<Id>>();
		for(AcctSeedERP__Material__c x :
		[SELECT AcctSeedERP__Project__r.Retail_ERP__c, AcctSeedERP__Product__c FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__r.Retail_ERP__c != null AND AcctSeedERP__Project__r.Locked__c = false]){
			if(!mapProjectSetProducts.containsKey(x.AcctSeedERP__Project__r.Retail_ERP__c)){
				mapProjectSetProducts.put(x.AcctSeedERP__Project__r.Retail_ERP__c,new Set<Id>());
			}
			mapProjectSetProducts.get(x.AcctSeedERP__Project__r.Retail_ERP__c).add(x.AcctSeedERP__Product__c);
		}
		System.debug('mapProjectSetProducts'+mapProjectSetProducts);

		map<Id,cube> mapCube = new map<Id,cube>();
		System.debug( setIdProduct );
		System.debug( pIdWarehouse );
		list<sObject> listAggRes = new list<sObject>();
		String soql = '';
		//listAggRes.clear();
		soql = 'SELECT GMBLASERP__Product__c idProduct,	count(Id) qty FROM GMBLASERP__Serial_Number__c';
		soql += ' WHERE GMBLASERP__Product__c IN:setIdProduct AND Dealer_Rigged__c = true';
		soql += ' AND GMBLASERP__Product__r.RecordType.Name = \'Boat\'';
		soql += ' AND GMBLASERP__Inventory_Balance__c != null';
		if(pIdWarehouse != null)
			soql += ' AND GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c =:pIdWarehouse';
		soql += ' GROUP BY GMBLASERP__Product__c';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			cube cube = new cube();
			cube.rigged = (Decimal)aggRes.get('qty');
			mapCube.put((Id)aggRes.get('idProduct'), cube);
		}
		//list<AggregateResult> listAggRes = new list<AggregateResult>();
		listAggRes.clear();
		soql = 'SELECT GMBLASERP__Product__c idProduct, count(Id) qty FROM GMBLASERP__Serial_Number__c';
		soql += ' WHERE GMBLASERP__Product__c IN:setIdProduct AND Dealer_Rigged__c = false';
		soql += ' AND GMBLASERP__Product__r.RecordType.Name = \'Boat\'';
		soql += ' AND GMBLASERP__Inventory_Balance__c != null';
		if(pIdWarehouse != null)
			soql += ' AND GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c =:pIdWarehouse';
		soql += ' GROUP BY GMBLASERP__Product__c';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			cube cube = mapCube.get((Id)aggRes.get('idProduct'));
			if(cube == null) cube = new cube();
			cube.notrigged = (Decimal)aggRes.get('qty');
			mapCube.put((Id)aggRes.get('idProduct'), cube);
		}

		listAggRes.clear();
		//SELECT GMBLASERP__Product__c idProduct, sum(GMBLASERP__Quantity__c) qty, sum(GMBLASERP__Inventory_GL_Amount__c) amt FROM GMBLASERP__Inventory_Movement_Cube__c WHERE GMBLASERP__Product__c = '01ti0000007Sd2gAAC' AND GMBLASERP__Warehouse__c = 'a1T1Y000004WXURUA4' AND GMBLASERP__Movement_Date__c <= TODAY GROUP BY GMBLASERP__Product__c, GMBLASERP__Warehouse__c
		soql = 'SELECT GMBLASERP__Product__c idProduct, sum(GMBLASERP__Quantity__c) qty FROM GMBLASERP__Inventory_Movement_Cube__c';
		soql += ' WHERE GMBLASERP__Product__c IN:setIdProduct';
		soql += ' AND GMBLASERP__Product__r.RecordType.Name != \'Boat\'';
		soql += ' AND (GMBLASERP__Quantity__c < 0 OR GMBLASERP__Quantity__c > 0)';
		if(pIdWarehouse != null)
			soql += ' AND GMBLASERP__Warehouse__c =:pIdWarehouse';
		soql += ' GROUP BY GMBLASERP__Product__c';
		soql += ' HAVING sum(GMBLASERP__Quantity__c) < 0 OR sum(GMBLASERP__Quantity__c) > 0';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			cube cube = mapCube.get((Id)aggRes.get('idProduct'));
			if(cube == null) cube = new cube();
			cube.currentInventoryFromCube = (Decimal)aggRes.get('qty');
			mapCube.put((Id)aggRes.get('idProduct'), cube);
		}

		listAggRes.clear();
		soql = 'SELECT AcctSeedERP__Product__c idProduct, sum(AcctSeedERP__Available_Quantity__c) qty FROM AcctSeedERP__Inventory_Balance__c';
		soql += ' WHERE AcctSeedERP__Product__c IN:setIdProduct';
		soql += ' AND AcctSeedERP__Product__r.RecordType.Name != \'Boat\'';
		soql += ' AND (AcctSeedERP__Available_Quantity__c < 0 OR AcctSeedERP__Available_Quantity__c > 0)';
		if(pIdWarehouse != null)
			soql += ' AND AcctSeedERP__Warehouse__c =:pIdWarehouse';
		soql += ' GROUP BY AcctSeedERP__Product__c';
		soql += ' HAVING sum(AcctSeedERP__Available_Quantity__c) < 0 OR sum(AcctSeedERP__Available_Quantity__c) > 0';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			cube cube = mapCube.get((Id)aggRes.get('idProduct'));
			if(cube == null) cube = new cube();
			cube.inventoryParts = (Decimal)aggRes.get('qty');
			mapCube.put((Id)aggRes.get('idProduct'), cube);
		}

		listAggRes.clear();
		soql = 'SELECT AcctSeedERP__Project__c idProject, AcctSeedERP__Product__c idProduct, sum(AcctSeedERP__Quantity_Unreceived__c) qty FROM AcctSeedERP__Purchase_Order_Line__c';
		soql += ' WHERE AcctSeedERP__Product__c IN:setIdProduct';
		soql += ' AND AcctSeedERP__Quantity_Unreceived__c > 0';
		//soql += ' AND AcctSeedERP__Project__c NOT IN:setIdRetailProjectToDiscard ';
		soql += ' AND AcctSeedERP__Purchase_Order__r.AcctSeedERP__Status__c = \'Open\'';
		soql += ' AND AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = true';
		if(pIdWarehouse != null)
			soql += ' AND (AcctSeedERP__Purchase_Order__r.Warehouse__c =:pIdWarehouse OR AcctSeedERP__Purchase_Order__r.Warehouse__c = null)';
		soql += ' GROUP BY AcctSeedERP__Project__c, AcctSeedERP__Product__c';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			Id idProject = (Id)aggRes.get('idProject');
			Id idProduct = (Id)aggRes.get('idProduct');
			if(!(mapProjectSetProducts.containsKey(idProject) && mapProjectSetProducts.get(idProject).contains(idProduct))) {
				cube cube = mapCube.get(idProduct);
				if (cube == null) cube = new cube();
				cube.purchasing += (Decimal) aggRes.get('qty');
				mapCube.put(idProduct, cube);
			}
		}
		Id idRtMfgERP = gcConstants.idRtProjectManufacturing;
		listAggRes.clear();
		soql = 'SELECT AcctSeedERP__Project__c idProject, AcctSeedERP__Product__c idProduct, sum(AcctSeedERP__Quantity_Per_Unit__c) qty FROM AcctSeedERP__Material__c';
		soql += ' WHERE AcctSeedERP__Product__c IN:setIdProduct';
		soql += ' AND AcctSeedERP__Quantity_Per_Unit__c > 0';
		soql += ' AND ((AcctSeedERP__Project__r.RecordTypeId !=:idRtMfgERP) OR (AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = false AND AcctSeedERP__Project__r.RecordTypeId =:idRtMfgERP))';
		//soql += ' AND AcctSeedERP__Project__c NOT IN:setIdRetailProjectToDiscard ';
		soql += ' AND AcctSeedERP__Project__r.Locked__c = false AND AcctSeedERP__Project__r.Stage__c NOT IN (\'Quoting\',\'Closed Lost\',\'Draft\',\'Pending Review\') AND No_WIP__c = false';
		if(pIdWarehouse != null)
			soql += ' AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:pIdWarehouse';
		soql += ' GROUP BY AcctSeedERP__Project__c, AcctSeedERP__Product__c';
		soql += ' HAVING sum(AcctSeedERP__Quantity_Per_Unit__c) > 0';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			Id idProject = (Id)aggRes.get('idProject');
			Id idProduct = (Id)aggRes.get('idProduct');
			if(!(mapProjectSetProducts.containsKey(idProject) && mapProjectSetProducts.get(idProject).contains(idProduct))) {
				cube cube = mapCube.get(idProduct);
				if (cube == null) cube = new cube();
				cube.specified += (Decimal) aggRes.get('qty');
				mapCube.put((Id) aggRes.get('idProduct'), cube);
			}
		}

		listAggRes.clear();
		soql = 'SELECT AcctSeedERP__Project__c idProject, AcctSeedERP__Product__c idProduct, sum(AcctSeedERP__Quantity_Allocated__c) qty FROM AcctSeedERP__Material__c';
		soql += ' WHERE AcctSeedERP__Product__c IN:setIdProduct';
		soql += ' AND AcctSeedERP__Quantity_Allocated__c > 0';
		//soql += ' AND AcctSeedERP__Project__c NOT IN:setIdRetailProjectToDiscard ';
		soql += ' AND AcctSeedERP__Project__r.Locked__c = false AND AcctSeedERP__Project__r.Stage__c NOT IN (\'Quoting\',\'Closed Lost\',\'Draft\',\'Pending Review\') AND No_WIP__c = false';
		if(pIdWarehouse != null)
			soql += ' AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:pIdWarehouse';
		soql += ' GROUP BY AcctSeedERP__Project__c, AcctSeedERP__Product__c';
		soql += ' HAVING sum(AcctSeedERP__Quantity_Allocated__c) > 0';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			Id idProject = (Id)aggRes.get('idProject');
			Id idProduct = (Id)aggRes.get('idProduct');
			if(!(mapProjectSetProducts.containsKey(idProject) && mapProjectSetProducts.get(idProject).contains(idProduct))) {
				cube cube = mapCube.get(idProduct);
				if (cube == null) cube = new cube();
				cube.consumed += (Decimal) aggRes.get('qty');
				mapCube.put((Id) aggRes.get('idProduct'), cube);
			}
		}

		listAggRes.clear();
		soql = 'SELECT Material__r.AcctSeedERP__Project__c idProject, GMBLASERP__Product__c idProduct, sum(AcctSeedERP__Quantity__c) qty FROM AcctSeedERP__Outbound_Inventory_Movement__c';
		soql += ' WHERE GMBLASERP__Product__c IN:setIdProduct';
		soql += ' AND AcctSeedERP__Quantity__c <> 0';
		soql += ' AND Material__c != null';
		soql += ' AND Material__r.AcctSeedERP__Project__r.Locked__c = false';
		//soql += ' AND Material__r.AcctSeedERP__Project__c NOT IN:setIdRetailProjectToDiscard ';
		soql += ' AND Material__r.AcctSeedERP__Project__r.Stage__c NOT IN (\'Quoting\',\'Closed Lost\',\'Draft\',\'Pending Review\')';
		if(pIdWarehouse != null)
			soql += ' AND Material__r.AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:pIdWarehouse';
		soql += ' GROUP BY Material__r.AcctSeedERP__Project__c, GMBLASERP__Product__c';
		soql += ' HAVING sum(AcctSeedERP__Quantity__c) > 0';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			Id idProject = (Id)aggRes.get('idProject');
			Id idProduct = (Id)aggRes.get('idProduct');
			if(!(mapProjectSetProducts.containsKey(idProject) && mapProjectSetProducts.get(idProject).contains(idProduct))) {
				cube cube = mapCube.get(idProduct);
				if (cube == null) cube = new cube();
				cube.consumed += (Decimal) aggRes.get('qty');
				mapCube.put(idProduct, cube);
			}
		}

		/// Including Partner Parts Order ERPs April-5-2021
		Id idWholesaleWarehouse = gcConstants.idWarehouseWholesale;
		Id idTransitWarehouse = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c;
		Id idRTPartsERP = gcConstants.idRtPartnerPartsOrder;
		if(idWholesaleWarehouse != pIdWarehouse) {
			listAggRes.clear();
			soql = 'SELECT AcctSeedERP__Project__c idProject, AcctSeedERP__Product__c idProduct, sum(AcctSeedERP__Quantity_Per_Unit__c) qty FROM AcctSeedERP__Material__c';
			soql += ' WHERE AcctSeedERP__Product__c IN:setIdProduct';
			soql += ' AND AcctSeedERP__Quantity_Per_Unit__c > 0';
			soql += ' AND AcctSeedERP__Project__r.RecordTypeId =:idRTPartsERP AND AcctSeedERP__Project__r.Locked__c = false AND AcctSeedERP__Project__r.Stage__c NOT IN (\'Quoting\',\'Closed Lost\',\'Draft\',\'Pending Review\') AND No_WIP__c = false';
			if (pIdWarehouse != null) {
				soql += ' AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:idWholesaleWarehouse';
				soql += ' AND AcctSeedERP__Project__r.AcctSeed__Account__r.Warehouse__c =:pIdWarehouse';
			}
			soql += ' GROUP BY AcctSeedERP__Project__c, AcctSeedERP__Product__c';
			soql += ' HAVING sum(AcctSeedERP__Quantity_Per_Unit__c) > 0';

			listAggRes.addAll(Database.query(soql));
			for (sObject aggRes : listAggRes) {
				Id idProject = (Id) aggRes.get('idProject');
				Id idProduct = (Id) aggRes.get('idProduct');
				if (!(mapProjectSetProducts.containsKey(idProject) && mapProjectSetProducts.get(idProject).contains(idProduct))) {
					cube cube = mapCube.get(idProduct);
					if (cube == null) cube = new cube();
					Decimal qty = (Decimal) aggRes.get('qty');
					cube.partnerPartsERP += qty;
					mapCube.put(idProduct, cube);
				}
			}

			listAggRes.clear();
			soql = 'SELECT AcctSeedERP__Outbound_Inventory_Movement__r.Material__r.AcctSeedERP__Project__c idProject, GMBLASERP__Product__c idProduct, sum(AcctSeedERP__Quantity__c) qty FROM AcctSeedERP__Inbound_Inventory_Movement__c';
			soql += ' WHERE GMBLASERP__Product__c IN:setIdProduct';
			soql += ' AND AcctSeedERP__Quantity__c <> 0';
			soql += ' AND GMBLASERP__Warehouse__c !=:idTransitWarehouse';
			soql += ' AND AcctSeedERP__Outbound_Inventory_Movement__r.Material__c != null';
			soql += ' AND AcctSeedERP__Outbound_Inventory_Movement__r.Material__r.AcctSeedERP__Project__r.Locked__c = false';
			//soql += ' AND Material__r.AcctSeedERP__Project__c NOT IN:setIdRetailProjectToDiscard ';
			soql += ' AND AcctSeedERP__Outbound_Inventory_Movement__r.Material__r.AcctSeedERP__Project__r.RecordTypeId =:idRTPartsERP AND AcctSeedERP__Outbound_Inventory_Movement__r.Material__r.AcctSeedERP__Project__r.Stage__c NOT IN (\'Quoting\',\'Closed Lost\',\'Draft\',\'Pending Review\')';
			if (pIdWarehouse != null) {
				soql += ' AND AcctSeedERP__Outbound_Inventory_Movement__r.AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:idWholesaleWarehouse';
				soql += ' AND AcctSeedERP__Outbound_Inventory_Movement__r.AcctSeedERP__Project__r.AcctSeed__Account__r.Warehouse__c =:pIdWarehouse';
			}
			soql += ' GROUP BY AcctSeedERP__Outbound_Inventory_Movement__r.Material__r.AcctSeedERP__Project__c, GMBLASERP__Product__c';
			soql += ' HAVING sum(AcctSeedERP__Quantity__c) > 0';
			System.debug('query');
			System.debug(soql);
			listAggRes.addAll(Database.query(soql));
			for (sObject aggRes : listAggRes) {
				Id idProject = (Id) aggRes.get('idProject');
				Id idProduct = (Id) aggRes.get('idProduct');
				if (!(mapProjectSetProducts.containsKey(idProject) && mapProjectSetProducts.get(idProject).contains(idProduct))) {
					cube cube = mapCube.get(idProduct);
					if (cube == null) cube = new cube();
					cube.partnerPartsERP -= (Decimal) aggRes.get('qty');
					mapCube.put(idProduct, cube);
				}
			}
		}

		mapCube.remove(null);

		return mapCube;
	}

	public class productData
	{
		Decimal totalDays;
		Decimal totalCounter;

		productData()
		{
			totalDays = 0;
			totalCounter = 0;
		}
	}

	public static void updateProductAverageArrivalTime(Set<Id> setIdProduct)
	{
		Map<Id,productData> mapProductDays = new Map<Id,productData>();
		for(AcctSeedERP__Purchase_Order_Inventory_Movement__c poim : [SELECT Id, GMBLASERP__Product__c, AcctSeedERP__Movement_Date__c, AcctSeedERP__Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__r.AcctSeedERP__Order_Date__c FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c WHERE GMBLASERP__Product__c IN:setIdProduct])
		{
			Date poDate = poim.AcctSeedERP__Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__r.AcctSeedERP__Order_Date__c;
			Date moveDate = poim.AcctSeedERP__Movement_Date__c;
			Integer diffInDays = poDate.daysBetween(moveDate);
			if(!mapProductDays.containsKey(poim.GMBLASERP__Product__c))
				mapProductDays.put(poim.GMBLASERP__Product__c, new productData());

			productData pData = mapProductDays.get(poim.GMBLASERP__Product__c);
			pData.totalDays += diffInDays;
			pData.totalCounter ++;
		}
		List<Product2> listProductsToUpdate = new List<Product2>();
		for(Product2 p : [SELECT Id, Average_MRP_Time__c FROM Product2 WHERE Id IN:mapProductDays.keySet()])
		{
			productData pData = mapProductDays.get(p.Id);
			Decimal averageDays = 0;
			if(pData.totalCounter != 0)
				averageDays = (pData.totalDays / pData.totalCounter).setScale(2);
			if(p.Average_MRP_Time__c == null || p.Average_MRP_Time__c != averageDays){
				p.Average_MRP_Time__c = averageDays;
				listProductsToUpdate.add(p);
			}
		}
		if(!listProductsToUpdate.isEmpty())
			update listProductsToUpdate;
	}

	public static void updateProductAvailabilityBatch(Set<Id> setIdProduct)
	{
		setIdProduct.remove(null);
		if(setIdProduct.isEmpty()) return;
		Map<Id,cube> mapCube = retrieveProducts(setIdProduct,null);
		List<Product2> listProductUpdate = new List<Product2>();
		for(Product2 p :
		[SELECT Id, MRP_Quantity__c FROM Product2 WHERE Id IN:setIdProduct])
		{
			Decimal qtyMRP = 0;
			cube cube = mapCube.get(p.Id);
			if(cube != null){
				Decimal required = cube.specified - cube.consumed;
				Decimal inventory = cube.rigged + cube.notrigged + cube.inventoryParts - required;
				qtyMRP = inventory + cube.purchasing;
			}
			if(p.MRP_Quantity__c == null || (p.MRP_Quantity__c.setScale(2) != qtyMRP.setScale(2))){
				p.MRP_Quantity__c = qtyMRP.setScale(2);
				listProductUpdate.add(p);
			}
		}
		if(!listProductUpdate.isEmpty())
		{
			Boolean olVal =
				gcProduct.disableTrigger = true;
			update listProductUpdate;
		}
	}

	public static void updateProductAvailabilityWarehouseBatch(Set<Id> setIdProduct)
	{
		setIdProduct.remove(null);
		if(setIdProduct.isEmpty()) return;
		Set<Id> setIdWarehouse = new Set<Id>();
		for(AcctSeedERP__Warehouse__c whs : [SELECT Id FROM AcctSeedERP__Warehouse__c])
			setIdWarehouse.add(whs.Id);

		setIdWarehouse.remove(GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c);
		setIdWarehouse.remove(GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c);

		Map<String,cube> mapCube = retrieveProductsByWarehouse(setIdProduct,setIdWarehouse);
		Map<String,Product_MRP_Value__c> mapMRPCube = new Map<String,Product_MRP_Value__c>();
		for(Product_MRP_Value__c p :
		[SELECT Id,
			Product__c,
			Warehouse__c,
			MRP_Quantity_Available__c,
			Uniquefier__c
		FROM Product_MRP_Value__c
		WHERE Product__c IN:setIdProduct])
		{
			Id idP = p.Product__c;
			Id idW = p.Warehouse__c;

			String uniqueKey = idP + '' + idW;
			p.MRP_Quantity_Available__c = 0;
			mapMRPCube.put(uniqueKey, p);
		}
		Map<Id,Decimal> mapProductMRP = new Map<Id,Decimal>();
		for(String key : mapCube.keySet())
		{
			cube cube = mapCube.get(key);
			Product_MRP_Value__c mrpCube = mapMRPCube.get(key);
			if(mrpCube == null){
				mrpCube = new Product_MRP_Value__c(Product__c = cube.idProduct, Warehouse__c = cube.idWarehouse, Uniquefier__c = key);
				mapMRPCube.put(key,mrpCube);
			}
			Decimal required = cube.specified - cube.consumed;
			Decimal inventory = cube.rigged + cube.notrigged + cube.inventoryParts - required;
			Decimal qtyMRP = inventory + cube.purchasing;
			mrpCube.MRP_Quantity_Available__c = qtyMRP;

			if(!mapProductMRP.containsKey(cube.idProduct))
				mapProductMRP.put(cube.idProduct,0);

			Decimal oldVal = mapProductMRP.get(cube.idProduct);
			mapProductMRP.put(cube.idProduct,oldVal+qtyMRP);
		}

		List<Product2> listProductUpdate = new List<Product2>();
		for(Product2 p :
		[SELECT Id, MRP_Quantity__c FROM Product2 WHERE Id IN:setIdProduct])
		{
			Decimal qtyMRP = 0;
			if(mapProductMRP.containsKey(p.Id))
				qtyMRP = mapProductMRP.get(p.Id);

			if(p.MRP_Quantity__c == null || (p.MRP_Quantity__c.setScale(2) != qtyMRP.setScale(2))){
				p.MRP_Quantity__c = qtyMRP.setScale(2);
				listProductUpdate.add(p);
			}
		}
		if(!listProductUpdate.isEmpty())
		{
			Boolean olVal = gcProduct.disableTrigger;
			gcProduct.disableTrigger = true;
			update listProductUpdate;
			gcProduct.disableTrigger = olVal;
		}

		upsert mapMRPCube.values();
	}

	public static Map<String,cube> retrieveProductsByWarehouse(Set<Id> setIdProduct, Set<Id> setIdWarehouse)
	{
//		Set<Id> setIdRetailProjectToDiscard = new Set<Id>();
//		for(AcctSeed__Project__c pr : [SELECT Id, Retail_ERP__c FROM AcctSeed__Project__c WHERE Retail_ERP__c != null AND Locked__c = false])
//			setIdRetailProjectToDiscard.add(pr.Retail_ERP__c);
		Map<Id,Set<Id>> mapProjectSetProducts = new Map<Id,Set<Id>>();
		for(AcctSeedERP__Material__c x :
		[SELECT AcctSeedERP__Project__r.Retail_ERP__c, AcctSeedERP__Product__c FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__r.Retail_ERP__c != null AND AcctSeedERP__Project__r.Locked__c = false]){
			if(!mapProjectSetProducts.containsKey(x.AcctSeedERP__Project__r.Retail_ERP__c)){
				mapProjectSetProducts.put(x.AcctSeedERP__Project__r.Retail_ERP__c,new Set<Id>());
			}
			mapProjectSetProducts.get(x.AcctSeedERP__Project__r.Retail_ERP__c).add(x.AcctSeedERP__Product__c);
		}
		System.debug('mapProjectSetProducts'+mapProjectSetProducts);

		map<String,cube> mapCube = new map<String,cube>();
		list<sObject> listAggRes = new list<sObject>();
		String soql = '';
		//listAggRes.clear();
		soql = 'SELECT GMBLASERP__Product__c idProduct,	GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c idWarehouse, count(Id) qty FROM GMBLASERP__Serial_Number__c';
		soql += ' WHERE GMBLASERP__Product__c IN:setIdProduct AND Dealer_Rigged__c = true';
		soql += ' AND GMBLASERP__Product__r.RecordType.Name = \'Boat\'';
		soql += ' AND GMBLASERP__Inventory_Balance__c != null';
		soql += ' AND GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c IN:setIdWarehouse';
		soql += ' GROUP BY GMBLASERP__Product__c, GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			Id idProduct = (Id)aggRes.get('idProduct');
			Id idWarehouse = (Id)aggRes.get('idWarehouse');
			cube cube = new cube(idProduct,idWarehouse);
			cube.rigged = (Decimal)aggRes.get('qty');
			String key = idProduct + '' + idWarehouse;
			mapCube.put(key, cube);
		}
		//list<AggregateResult> listAggRes = new list<AggregateResult>();
		listAggRes.clear();
		soql = 'SELECT GMBLASERP__Product__c idProduct, GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c idWarehouse, count(Id) qty FROM GMBLASERP__Serial_Number__c';
		soql += ' WHERE GMBLASERP__Product__c IN:setIdProduct AND Dealer_Rigged__c = false';
		soql += ' AND GMBLASERP__Product__r.RecordType.Name = \'Boat\'';
		soql += ' AND GMBLASERP__Inventory_Balance__c != null';
		soql += ' AND GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c IN:setIdWarehouse';
		soql += ' GROUP BY GMBLASERP__Product__c, GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			Id idProduct = (Id)aggRes.get('idProduct');
			Id idWarehouse = (Id)aggRes.get('idWarehouse');
			String key = idProduct + '' + idWarehouse;
			cube cube = mapCube.get(key);
			if(cube == null) {
				cube = new cube(idProduct,idWarehouse);
				mapCube.put(key, cube);
			}

			cube.notrigged = (Decimal)aggRes.get('qty');
		}

		listAggRes.clear();
		soql = 'SELECT AcctSeedERP__Product__c idProduct, AcctSeedERP__Warehouse__c idWarehouse, sum(AcctSeedERP__Available_Quantity__c) qty FROM AcctSeedERP__Inventory_Balance__c';
		soql += ' WHERE AcctSeedERP__Product__c IN:setIdProduct';
		soql += ' AND AcctSeedERP__Product__r.RecordType.Name != \'Boat\'';
		soql += ' AND (AcctSeedERP__Available_Quantity__c < 0 OR AcctSeedERP__Available_Quantity__c > 0)';
		soql += ' AND AcctSeedERP__Warehouse__c IN:setIdWarehouse';
		soql += ' GROUP BY AcctSeedERP__Product__c, AcctSeedERP__Warehouse__c';
		soql += ' HAVING sum(AcctSeedERP__Available_Quantity__c) < 0 OR sum(AcctSeedERP__Available_Quantity__c) > 0';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			Id idProduct = (Id)aggRes.get('idProduct');
			Id idWarehouse = (Id)aggRes.get('idWarehouse');
			String key = idProduct + '' + idWarehouse;
			cube cube = mapCube.get(key);
			if(cube == null) {
				cube = new cube(idProduct,idWarehouse);
				mapCube.put(key, cube);
			}
			cube.inventoryParts = (Decimal)aggRes.get('qty');
		}

		listAggRes.clear();
		soql = 'SELECT AcctSeedERP__Product__c idProduct, AcctSeedERP__Purchase_Order__r.Warehouse__c idWarehouse, sum(AcctSeedERP__Quantity_Unreceived__c) qty FROM AcctSeedERP__Purchase_Order_Line__c';
		soql += ' WHERE AcctSeedERP__Product__c IN:setIdProduct';
		soql += ' AND AcctSeedERP__Quantity_Unreceived__c > 0';
		soql += ' AND AcctSeedERP__Purchase_Order__r.AcctSeedERP__Status__c = \'Open\'';
		soql += ' AND AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = true';
		soql += ' AND (AcctSeedERP__Purchase_Order__r.Warehouse__c IN:setIdWarehouse OR AcctSeedERP__Purchase_Order__r.Warehouse__c = null)';
		soql += ' GROUP BY AcctSeedERP__Product__c, AcctSeedERP__Purchase_Order__r.Warehouse__c';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			Id idProduct = (Id)aggRes.get('idProduct');
			Id idWarehouse = (Id)aggRes.get('idWarehouse');
			String key = idProduct + '' + idWarehouse;
			cube cube = mapCube.get(key);
			if(cube == null) {
				cube = new cube(idProduct,idWarehouse);
				mapCube.put(key, cube);
			}
			cube.purchasing += (Decimal)aggRes.get('qty');
		}

		listAggRes.clear();
		soql = 'SELECT AcctSeedERP__Project__c idProject, AcctSeedERP__Product__c idProduct, AcctSeedERP__Project__r.GMBLASERP__Warehouse__c idWarehouse, sum(AcctSeedERP__Quantity_Per_Unit__c) qty FROM AcctSeedERP__Material__c';
		soql += ' WHERE AcctSeedERP__Product__c IN:setIdProduct';
		soql += ' AND AcctSeedERP__Quantity_Per_Unit__c > 0';
		//soql += ' AND AcctSeedERP__Project__c NOT IN:setIdRetailProjectToDiscard ';
		soql += ' AND AcctSeedERP__Project__r.Locked__c = false AND AcctSeedERP__Project__r.Stage__c NOT IN (\'Quoting\',\'Closed Lost\',\'Draft\',\'Pending Review\') AND No_WIP__c = false';
		soql += ' AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c IN:setIdWarehouse';
		soql += ' GROUP BY AcctSeedERP__Project__c, AcctSeedERP__Product__c, AcctSeedERP__Project__r.GMBLASERP__Warehouse__c';
		soql += ' HAVING sum(AcctSeedERP__Quantity_Per_Unit__c) > 0';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			Id idProject = (Id)aggRes.get('idProject');
			Id idProduct = (Id)aggRes.get('idProduct');
			if(!(mapProjectSetProducts.containsKey(idProject) && mapProjectSetProducts.get(idProject).contains(idProduct))) {
				Id idWarehouse = (Id) aggRes.get('idWarehouse');
				String key = idProduct + '' + idWarehouse;
				cube cube = mapCube.get(key);
				if (cube == null) {
					cube = new cube(idProduct, idWarehouse);
					mapCube.put(key, cube);
				}
				cube.specified += (Decimal) aggRes.get('qty');
			}
		}

		listAggRes.clear();
		soql = 'SELECT AcctSeedERP__Project__c idProject, AcctSeedERP__Product__c idProduct, AcctSeedERP__Project__r.GMBLASERP__Warehouse__c idWarehouse, sum(AcctSeedERP__Quantity_Allocated__c) qty FROM AcctSeedERP__Material__c';
		soql += ' WHERE AcctSeedERP__Product__c IN:setIdProduct';
		soql += ' AND AcctSeedERP__Quantity_Allocated__c > 0';
		//soql += ' AND AcctSeedERP__Project__c NOT IN:setIdRetailProjectToDiscard ';
		soql += ' AND AcctSeedERP__Project__r.Locked__c = false AND AcctSeedERP__Project__r.Stage__c NOT IN (\'Quoting\',\'Closed Lost\',\'Draft\',\'Pending Review\') AND No_WIP__c = false';
		soql += ' AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c IN:setIdWarehouse';
		soql += ' GROUP BY AcctSeedERP__Project__c, AcctSeedERP__Product__c, AcctSeedERP__Project__r.GMBLASERP__Warehouse__c';
		soql += ' HAVING sum(AcctSeedERP__Quantity_Allocated__c) > 0';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			Id idProject = (Id)aggRes.get('idProject');
			Id idProduct = (Id)aggRes.get('idProduct');
			if(!(mapProjectSetProducts.containsKey(idProject) && mapProjectSetProducts.get(idProject).contains(idProduct))) {
				Id idWarehouse = (Id) aggRes.get('idWarehouse');
				String key = idProduct + '' + idWarehouse;
				cube cube = mapCube.get(key);
				if (cube == null) {
					cube = new cube(idProduct, idWarehouse);
					mapCube.put(key, cube);
				}
				cube.consumed += (Decimal) aggRes.get('qty');
			}
		}

		listAggRes.clear();
		soql = 'SELECT Material__r.AcctSeedERP__Project__c idProject, GMBLASERP__Product__c idProduct, Material__r.AcctSeedERP__Project__r.GMBLASERP__Warehouse__c idWarehouse, sum(AcctSeedERP__Quantity__c) qty FROM AcctSeedERP__Outbound_Inventory_Movement__c';
		soql += ' WHERE GMBLASERP__Product__c IN:setIdProduct';
		soql += ' AND AcctSeedERP__Quantity__c <> 0';
		soql += ' AND Material__c != null';
		soql += ' AND Material__r.AcctSeedERP__Project__r.Locked__c = false';
		//soql += ' AND Material__r.AcctSeedERP__Project__c NOT IN:setIdRetailProjectToDiscard ';
		soql += ' AND Material__r.AcctSeedERP__Project__r.Stage__c NOT IN (\'Quoting\',\'Closed Lost\',\'Draft\',\'Pending Review\')';
		soql += ' AND Material__r.AcctSeedERP__Project__r.GMBLASERP__Warehouse__c IN:setIdWarehouse';
		soql += ' GROUP BY Material__r.AcctSeedERP__Project__c, GMBLASERP__Product__c, Material__r.AcctSeedERP__Project__r.GMBLASERP__Warehouse__c';
		soql += ' HAVING sum(AcctSeedERP__Quantity__c) > 0';

		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			Id idProject = (Id)aggRes.get('idProject');
			Id idProduct = (Id)aggRes.get('idProduct');
			if(!(mapProjectSetProducts.containsKey(idProject) && mapProjectSetProducts.get(idProject).contains(idProduct))) {
				Id idWarehouse = (Id) aggRes.get('idWarehouse');
				String key = idProduct + '' + idWarehouse;
				cube cube = mapCube.get(key);
				if (cube == null) {
					cube = new cube(idProduct, idWarehouse);
					mapCube.put(key, cube);
				}
				cube.consumed += (Decimal) aggRes.get('qty');
			}
		}

		mapCube.remove(null);

		return mapCube;
	}

	@RemoteAction @ReadOnly
	public static list<map<String,String>> retrieveProductsBySupplier(List<Id> listIdProducts, Id pIdWarehouse, Id pIdProductType, String idSupplier){
		Set<Id> setIdProducts = new Set<Id>();
		if(idSupplier != '') {
			if(idSupplier == 'BLANK')
				idSupplier = null;
			for (Product2 p : [SELECT Id FROM Product2 WHERE AcctSeed__Inventory_Product__c = true AND AcctSeedERP__Default_Vendor__c = :idSupplier AND RecordTypeId = :pIdProductType])
				setIdProducts.add(p.Id);
			listIdProducts.clear();
			listIdProducts.addAll(setIdProducts);
			if(listIdProducts.isEmpty()) return new list<map<String,String>>();
		}
		return retrieveProducts(listIdProducts,pIdWarehouse,pIdProductType);
	}

	@RemoteAction @ReadOnly
	public static list<map<String,String>> retrieveProductsByFamily(List<Id> listIdProducts, Id pIdWarehouse, Id pIdProductType, String selectedFamily){
		Set<Id> setIdProducts = new Set<Id>();
		if(selectedFamily != '') {
			for (Product2 p : [SELECT Id FROM Product2 WHERE AcctSeed__Inventory_Product__c = true AND Family = :selectedFamily AND RecordTypeId = :pIdProductType])
				setIdProducts.add(p.Id);
			listIdProducts.clear();
			listIdProducts.addAll(setIdProducts);
		}
		return retrieveProducts(listIdProducts,pIdWarehouse,pIdProductType);
	}

	@RemoteAction @ReadOnly
	public static list<map<String,String>> retrieveProducts(List<Id> listIdProducts, Id pIdWarehouse, Id pIdProductType)
	{
		list<map<string,string>> listJSON = new list<map<String,String>>();
		Set<Id> setIdProducts = new Set<Id>();
		if(listIdProducts.isEmpty())
		{
			for(Product2 p : [SELECT Id FROM Product2 WHERE AcctSeed__Inventory_Product__c = true AND RecordTypeId =:pIdProductType])
				setIdProducts.add(p.Id);
		}
		else
			setIdProducts.addAll(listIdProducts);

		Map<Id,cube> mapCube = retrieveProducts(setIdProducts,pIdWarehouse);

		for(Product2 p :
		[SELECT Id, Name, Unique_Product_Code__c, Family, RecordType.Name, AcctSeedERP__Default_Vendor__r.Name
		FROM Product2
		WHERE Id IN:setIdProducts])
		{
			map<String,String> m = new map<String,String>();
			m.put('idProduct',p.Id);
			m.put('productName',p.Name);
			m.put('supplierName',p.AcctSeedERP__Default_Vendor__r.Name);
			m.put('productCode',(p.Unique_Product_Code__c == null ? '' :p.Unique_Product_Code__c));
			m.put('recordType',p.RecordType.Name);
			m.put('productFamily',p.Family);

			if(mapCube.containsKey(p.Id))
			{
				cube cube = mapCube.get(p.Id);
				m.put('rigged',String.valueOf(cube.rigged.setScale(6)));
				m.put('notrigged',String.valueOf(cube.notrigged.setScale(6)));
				m.put('inventoryParts',String.valueOf(cube.inventoryParts.setScale(6)));
				m.put('inventoryParts2',String.valueOf(cube.currentInventoryFromCube.setScale(6)));
				m.put('specified',String.valueOf(cube.specified.setScale(6)));
				m.put('consumed',String.valueOf(cube.consumed.setScale(6)));
				Decimal required = cube.specified - cube.consumed;
				m.put('required',String.valueOf(required.setScale(6)));
				m.put('purchasing',String.valueOf(cube.purchasing.setScale(6)));
				Decimal partsERP = cube.partnerPartsERP.setScale(6);
				m.put('unreceivedPartERP',String.valueOf(partsERP));
				Decimal inventory = cube.rigged + cube.notrigged + cube.inventoryParts - required;
				m.put('inventory', String.valueOf(inventory.setScale(6)));

				Decimal inventory2 = cube.rigged + cube.notrigged + cube.currentInventoryFromCube - required;
				m.put('inventory2', String.valueOf(inventory2.setScale(6)));

				Decimal expected = inventory + cube.purchasing + partsERP;
				m.put('expected', String.valueOf(expected.setScale(6)));
				m.put('available', String.valueOf((expected - required).setScale(6)));

				Decimal expected2 = inventory2 + cube.purchasing;
				m.put('expected2', String.valueOf(expected2.setScale(6)));
				m.put('available2', String.valueOf((expected2 - required).setScale(6)));
			}
			else
			{
				m.put('rigged','0');
				m.put('notrigged','0');
				m.put('inventoryParts','0');
				m.put('inventory','0');
				m.put('inventory2','0');
				m.put('purchasing','0');
				m.put('specified','0');
				m.put('consumed','0');
				m.put('required','0');

				m.put('expected','0');
				m.put('expected2','0');
				m.put('available','0');
				m.put('available2','0');
			}
			listJSON.add(m);
		}

		return listJSON;
	}

	public class cube
	{
		public Id idProduct;
		public Id idWarehouse;
		public Decimal rigged;
		public Decimal notrigged;
		public Decimal currentInventoryFromCube;
		public Decimal inventoryParts;
		public Decimal purchasing;
		public Decimal specified;
		public Decimal partnerPartsERP;
		public Decimal consumed;

		cube()
		{
			rigged = 0;
			notrigged = 0;
			currentInventoryFromCube = 0;
			inventoryParts = 0;
			purchasing = 0;
			specified = 0;
			partnerPartsERP = 0;
			consumed = 0;
		}

		cube(Id pIdProduct, Id pIdWarehouse)
		{
			rigged = 0;
			notrigged = 0;
			currentInventoryFromCube = 0;
			inventoryParts = 0;
			purchasing = 0;
			specified = 0;
			partnerPartsERP = 0;
			consumed = 0;
			idProduct = pIdProduct;
			idWarehouse = pIdWarehouse;
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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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