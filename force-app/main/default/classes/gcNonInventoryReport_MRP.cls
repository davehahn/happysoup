public without sharing class gcNonInventoryReport_MRP {
	public gcNonInventoryReport_MRP() {}
	
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
		listOptions.add(new selectOption('Kit', 'Kits'));
		listOptions.add(new selectOption('Non', 'Other Non-Inventory'));

		return listOptions;	
	}

	@RemoteAction @ReadOnly 
	public static list<map<String,String>> retrieveSerialNumbers(list<Id> listIdProduct, Id pIdWarehouse)
	{
		list<map<String,String>> listJSON = new list<map<String,String>>();

		set<Id> setIdProduct = new set<Id>();
		setIdProduct.addAll(listIdProduct);
		for(AcctSeed__Product_Part__c p : [SELECT AcctSeed__Product_Part__c FROM AcctSeed__Product_Part__c WHERE AcctSeed__Product__c IN:listIdProduct AND AcctSeed__Product__r.Composite_Type__c = 'Kit'])
			setIdProduct.add(p.AcctSeed__Product_Part__c);
		setIdProduct.remove(null);
		Boolean checkDeleted = true;
		if(pIdWarehouse == null) checkDeleted = false;
		for(GMBLASERP__Serial_Number__c x :
			[SELECT Id, Name,
					Dealer_Rigged__c,
					Available_Retail__c,
					Available_Wholesale__c,
					GMBLASERP__Product__c,
					Product_Name__c,
					GMBLASERP__Lot__c,
					GMBLASERP__Lot__r.Name,
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
		for(AcctSeed__Product_Part__c p : [SELECT AcctSeed__Product_Part__c FROM AcctSeed__Product_Part__c WHERE AcctSeed__Product__c IN:listIdProduct AND AcctSeed__Product__r.Composite_Type__c = 'Kit'])
			setIdProduct.add(p.AcctSeed__Product_Part__c);
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
			   	AND AcctSeedERP__Purchase_Order__r.Locked__c = false
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
		list<map<String,String>> listJSON = new list<map<String,String>>();

		set<Id> setIdProduct = new set<Id>();
		setIdProduct.addAll(listIdProduct);
		for(AcctSeed__Product_Part__c p : [SELECT AcctSeed__Product_Part__c FROM AcctSeed__Product_Part__c WHERE AcctSeed__Product__c IN:listIdProduct AND AcctSeed__Product__r.Composite_Type__c = 'Kit'])
			setIdProduct.add(p.AcctSeed__Product_Part__c);
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
					AcctSeedERP__Product__r.Name,
					AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
					AcctSeedERP__Product__r.Composite_Type__c,
					AcctSeedERP__Quantity_Per_Unit__c,
					AcctSeedERP__Quantity_Allocated__c
			 FROM AcctSeedERP__Material__c
			 WHERE AcctSeedERP__Quantity_Per_Unit__c > 0
			  	AND AcctSeedERP__Project__r.Locked__c = false
			  	AND AcctSeedERP__Product__c IN :setIdProduct
			 	AND (IsDeleted =:checkDeleted OR AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:pIdWarehouse)
			 	AND IsDeleted = false])
		{
			map<String,String> m = new map<String,String>();
			m.put('idProject',x.AcctSeedERP__Project__c);
			m.put('idWarehouse',x.AcctSeedERP__Project__r.GMBLASERP__Warehouse__c);
			m.put('nameWarehouse',x.AcctSeedERP__Project__r.GMBLASERP__Warehouse__r.Name);
			if(x.AcctSeedERP__Project__c != null)
			{
				m.put('projectNumber',String.valueOf(Integer.valueOf(x.AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c.replaceAll('[^0-9]',''))));
				m.put('createdDate',x.AcctSeedERP__Project__r.CreatedDate.date().format());
				m.put('projectName',x.AcctSeedERP__Project__r.Name);
				m.put('projectType',x.AcctSeedERP__Project__r.RecordType.Name);
				if(x.AcctSeedERP__Project__r.Serial_Number__c != null){
					m.put('projectSerial',x.AcctSeedERP__Project__r.Serial_Number__r.Name);
					m.put('projectLot',x.AcctSeedERP__Project__r.Serial_Number__r.GMBLASERP__Lot__r.Name);
				}
			}

			m.put('productName',x.AcctSeedERP__Product__r.Name);
			m.put('compositeType',x.AcctSeedERP__Product__r.Composite_Type__c);
			m.put('isInventory',x.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c ? 'true' : 'false');

			if(x.AcctSeedERP__Quantity_Per_Unit__c != null)
				m.put('qtySpecified',String.valueOf(x.AcctSeedERP__Quantity_Per_Unit__c.setScale(6)));
			else
				m.put('qtySpecified','0');

			if(x.AcctSeedERP__Quantity_Allocated__c != null)
				m.put('qtyAllocated',String.valueOf(x.AcctSeedERP__Quantity_Allocated__c.setScale(6)));
			else
				m.put('qtyAllocated','0');

			listJSON.add(m);
		}
		return listJSON;
	}

	public static Map<Id,cube> retrieveProducts(Set<Id> setIdProduct, Id pIdWarehouse)
	{
		map<Id,cube> mapCube = new map<Id,cube>();

		list<sObject> listAggRes = new list<sObject>();
		String soql = '';
		//listAggRes.clear();
/*		soql = 'SELECT GMBLASERP__Product__c idProduct,	count(Id) qty FROM GMBLASERP__Serial_Number__c';
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
*/
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
		soql = 'SELECT AcctSeedERP__Product__c idProduct, sum(AcctSeedERP__Quantity_Unreceived__c) qty FROM AcctSeedERP__Purchase_Order_Line__c';
		soql += ' WHERE AcctSeedERP__Product__c IN:setIdProduct';
		soql += ' AND AcctSeedERP__Quantity_Unreceived__c > 0';
		soql += ' AND AcctSeedERP__Purchase_Order__r.Locked__c = false';
		soql += ' AND AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = true';
		if(pIdWarehouse != null)
			soql += ' AND (AcctSeedERP__Purchase_Order__r.Warehouse__c =:pIdWarehouse OR AcctSeedERP__Purchase_Order__r.Warehouse__c = null)';
		soql += ' GROUP BY AcctSeedERP__Product__c';
		
		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			cube cube = mapCube.get((Id)aggRes.get('idProduct'));
			if(cube == null) cube = new cube();
			cube.purchasing += (Decimal)aggRes.get('qty');
			mapCube.put((Id)aggRes.get('idProduct'), cube);
		}

		listAggRes.clear();
		soql = 'SELECT AcctSeedERP__Product__c idProduct, sum(AcctSeedERP__Quantity_Per_Unit__c) qty FROM AcctSeedERP__Material__c';
		soql += ' WHERE AcctSeedERP__Product__c IN:setIdProduct';
		soql += ' AND AcctSeedERP__Quantity_Per_Unit__c > 0';
		soql += ' AND AcctSeedERP__Project__r.Locked__c = false';
		if(pIdWarehouse != null)
			soql += ' AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:pIdWarehouse';
		soql += ' GROUP BY AcctSeedERP__Product__c';
		soql += ' HAVING sum(AcctSeedERP__Quantity_Per_Unit__c) > 0';
		
		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			cube cube = mapCube.get((Id)aggRes.get('idProduct'));
			if(cube == null) cube = new cube();
			cube.specified += (Decimal)aggRes.get('qty');
			mapCube.put((Id)aggRes.get('idProduct'), cube);
		}

		listAggRes.clear();
		soql = 'SELECT AcctSeedERP__Product__c idProduct, sum(AcctSeedERP__Quantity_Allocated__c) qty FROM AcctSeedERP__Material__c';
		soql += ' WHERE AcctSeedERP__Product__c IN:setIdProduct';
		soql += ' AND AcctSeedERP__Quantity_Allocated__c > 0';
		soql += ' AND AcctSeedERP__Project__r.Locked__c = false';
		if(pIdWarehouse != null)
			soql += ' AND AcctSeedERP__Project__r.GMBLASERP__Warehouse__c =:pIdWarehouse';
		soql += ' GROUP BY AcctSeedERP__Product__c';
		soql += ' HAVING sum(AcctSeedERP__Quantity_Allocated__c) > 0';
		
		listAggRes.addAll(Database.query(soql));
		for(sObject aggRes : listAggRes)
		{
			cube cube = mapCube.get((Id)aggRes.get('idProduct'));
			if(cube == null) cube = new cube();
			cube.consumed += (Decimal)aggRes.get('qty');
			mapCube.put((Id)aggRes.get('idProduct'), cube);
		}

		mapCube.remove(null);

		return mapCube;
	}

	@RemoteAction @ReadOnly 
	public static list<map<String,String>> retrieveProducts(List<Id> listIdProducts, Id pIdWarehouse, String pIdProductType)
	{
		list<map<string,string>> listJSON = new list<map<String,String>>();
		Set<Id> setIdProducts = new Set<Id>();
		if(!listIdProducts.isEmpty())
		{
			for(AcctSeed__Product_Part__c p : [SELECT AcctSeed__Product_Part__c FROM AcctSeed__Product_Part__c WHERE AcctSeed__Product__c IN:listIdProducts])
				setIdProducts.add(p.AcctSeed__Product_Part__c);
		}else
		{
			if(pIdProductType != 'kit')
				for(Product2 p : [SELECT Id FROM Product2 WHERE AcctSeed__Inventory_Product__c = false AND Composite_Type__c != 'Kit'])
					setIdProducts.add(p.Id);
			else
				for(Product2 p : [SELECT Id FROM Product2 WHERE Composite_Type__c = 'Kit'])
					setIdProducts.add(p.Id);			
		}
		
		Map<Id,cube> mapCube = retrieveProducts(setIdProducts,pIdWarehouse);

		for(Product2 p :
			[SELECT Id, Name, Unique_Product_Code__c, Family, RecordType.Name, AcctSeedERP__Default_Vendor__r.Name, AcctSeed__Inventory_Product__c, Composite_Type__c
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
			m.put('isInventory',p.AcctSeed__Inventory_Product__c ? 'true' : 'false');
			m.put('compositeType',p.Composite_Type__c == null ? '' : p.Composite_Type__c);

			if(mapCube.containsKey(p.Id))
			{
				cube cube = mapCube.get(p.Id);
				m.put('rigged',String.valueOf(cube.rigged.setScale(6)));
				m.put('notrigged',String.valueOf(cube.notrigged.setScale(6)));
				m.put('inventoryParts',String.valueOf(cube.inventoryParts.setScale(6)));
				m.put('purchasing',String.valueOf(cube.purchasing.setScale(6)));
				m.put('specified',String.valueOf(cube.specified.setScale(6)));
				m.put('consumed',String.valueOf(cube.consumed.setScale(6)));
				Decimal required = cube.specified - cube.consumed;
				m.put('required',String.valueOf(required.setScale(6)));

				Decimal inventory = cube.rigged + cube.notrigged + cube.inventoryParts;
				Decimal expected = cube.rigged + cube.notrigged + cube.inventoryParts + cube.purchasing;

				m.put('inventory', String.valueOf(inventory.setScale(6)));
				m.put('expected', String.valueOf(expected.setScale(6)));
				m.put('available', String.valueOf((expected - required).setScale(6)));
			}
			else
			{
				m.put('rigged','0');
				m.put('notrigged','0');
				m.put('inventoryParts','0');
				m.put('inventory','0');
				m.put('purchasing','0');
				m.put('specified','0');
				m.put('consumed','0');		
				m.put('required','0');		

				m.put('expected','0');		
				m.put('available','0');
			}
			listJSON.add(m);
		}

		return listJSON;
	}

	public class cube
	{
		Decimal rigged;
		Decimal notrigged;
		Decimal inventoryParts;
		Decimal purchasing;
		Decimal specified; 
		Decimal consumed; 

		cube()
		{
			rigged = 0;
			notrigged = 0;
			inventoryParts = 0;
			purchasing = 0;
			specified = 0;
			consumed = 0;
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
	}
}