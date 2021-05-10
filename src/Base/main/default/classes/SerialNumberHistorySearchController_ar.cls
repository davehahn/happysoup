public without sharing class SerialNumberHistorySearchController_ar {

	public class cubeData implements Comparable{
		public String productName{get;set;}
		public Id idProduct { get; set; }
		public Id idBalance { get; set; }
		public String warehouseName { get; set; }
		public Id idWarehouse { get; set; }
		public String serialName { get; set; }
		public Id idSerial { get; set; }
		public Decimal quantity { get; set; }
		public String moveType { get; set; }
		public Date moveDate { get; set; }
		public String lotName { get; set; }
		public Id idLot { get; set; }
		public Decimal inventoryGLAmount { get; set; }
		public Id idERP { get; set; }
		public String erpName { get; set; }
		public Id idERPTask { get; set; }
		public String erpTaskName { get; set; }
		public Id idTransfer { get; set; }
		public String transferName { get; set; }
		public Id idAdjustment { get; set; }
		public String adjustmentName { get; set; }
		public String seeGLAmount { get; set; }
		public List<erpOrderItems> listERPItems { get; set; }
		
		public cubeData(){}
		
		public cubeData(AcctSeedERP__Purchase_Order_Inventory_Movement__c move){
			String objectName = move.getSObjectType().getDescribe().getName();
			this.idProduct = move.GMBLASERP__Product__c;
			this.productName = move.GMBLASERP__Product__r.Name;
			this.idWarehouse = move.GMBLASERP__Warehouse__c;
			this.warehouseName = move.GMBLASERP__Warehouse__r.Name;
			this.idSerial = move.GMBLASERP__Serial_Number__c;
			this.serialName = move.GMBLASERP__Serial_Number__r.Name;
			this.idLot = move.GMBLASERP__Lot__c;
			this.lotName = move.GMBLASERP__Lot__r.Name;
			this.moveType = sanitizeType(objectName);
			this.moveDate = move.AcctSeedERP__Movement_Date__c;
			this.inventoryGLAmount = move.GMBLASERP__Inventory_GL_Amount__c;
			this.quantity = move.AcctSeedERP__Quantity__c;

			if(move.AcctSeedERP__Project__c != null){
				this.idERP = move.AcctSeedERP__Project__c;
				this.erpName = move.AcctSeedERP__Project__r.Name;
			}
			if(move.AcctSeedERP__Project_Task__c != null){
				this.idERPTask = move.AcctSeedERP__Project_Task__c;
				this.erpTaskName = move.AcctSeedERP__Project_Task__r.Name;
			}
		}

		public cubeData(AcctSeedERP__Inbound_Inventory_Movement__c move){
			String objectName = move.getSObjectType().getDescribe().getName();
			this.idProduct = move.GMBLASERP__Product__c;
			this.productName = move.GMBLASERP__Product__r.Name;
			this.idWarehouse = move.GMBLASERP__Warehouse__c;
			this.warehouseName = move.GMBLASERP__Warehouse__r.Name;
			this.idSerial = move.GMBLASERP__Serial_Number__c;
			this.serialName = move.GMBLASERP__Serial_Number__r.Name;
			this.idLot = move.GMBLASERP__Lot__c;
			this.lotName = move.GMBLASERP__Lot__r.Name;
			this.moveType = sanitizeType(objectName);
			this.moveDate = move.AcctSeedERP__Movement_Date__c;
			this.inventoryGLAmount = move.GMBLASERP__Inventory_GL_Amount__c;
			this.quantity = move.AcctSeedERP__Quantity__c;

			if(move.GMBLASERP__Inventory_Transfer__c != null){
				this.idTransfer = move.GMBLASERP__Inventory_Transfer__c;
				this.transferName = move.GMBLASERP__Inventory_Transfer__r.Name;
			}
			if(move.GMBLASERP__Inventory_Adjustment__c != null){
				this.idAdjustment = move.GMBLASERP__Inventory_Adjustment__c;
				this.adjustmentName = move.GMBLASERP__Inventory_Adjustment__r.Name;
			}
			if(move.AcctSeedERP__Project__c != null){
				this.idERP = move.AcctSeedERP__Project__c;
				this.erpName = move.AcctSeedERP__Project__r.Name;
			}
			if(move.AcctSeedERP__Project_Task__c != null){
				this.idERPTask = move.AcctSeedERP__Project_Task__c;
				this.erpTaskName = move.AcctSeedERP__Project_Task__r.Name;
			}
		}

		public cubeData(AcctSeedERP__Outbound_Inventory_Movement__c move){
			String objectName = move.getSObjectType().getDescribe().getName();
			this.idProduct = move.GMBLASERP__Product__c;
			this.productName = move.GMBLASERP__Product__r.Name;
			this.idWarehouse = move.GMBLASERP__Warehouse__c;
			this.warehouseName = move.GMBLASERP__Warehouse__r.Name;
			this.idSerial = move.GMBLASERP__Serial_Number__c;
			this.serialName = move.GMBLASERP__Serial_Number__r.Name;
			this.idLot = move.GMBLASERP__Lot__c;
			this.lotName = move.GMBLASERP__Lot__r.Name;
			this.moveType = sanitizeType(objectName);
			this.moveDate = move.AcctSeedERP__Movement_Date__c;
			this.inventoryGLAmount = move.GMBLASERP__Inventory_GL_Amount__c;
			this.quantity = move.AcctSeedERP__Quantity__c * -1;

			if(move.GMBLASERP__Inventory_Transfer__c != null){
				this.idTransfer = move.GMBLASERP__Inventory_Transfer__c;
				this.transferName = move.GMBLASERP__Inventory_Transfer__r.Name;
			}
			if(move.AcctSeedERP__Project__c != null){
				this.idERP = move.AcctSeedERP__Project__c;
				this.erpName = move.AcctSeedERP__Project__r.Name;
			}
			if(move.AcctSeedERP__Project_Task__c != null){
				this.idERPTask = move.AcctSeedERP__Project_Task__c;
				this.erpTaskName = move.AcctSeedERP__Project_Task__r.Name;
			}
		}

		public cubeData(AcctSeedERP__Manufacturing_Inventory_Movement__c move){
			String objectName = move.getSObjectType().getDescribe().getName();
			this.idProduct = move.GMBLASERP__Product__c;
			this.productName = move.GMBLASERP__Product__r.Name;
			this.idWarehouse = move.GMBLASERP__Warehouse__c;
			this.warehouseName = move.GMBLASERP__Warehouse__r.Name;
			this.idSerial = move.GMBLASERP__Serial_Number__c;
			this.serialName = move.GMBLASERP__Serial_Number__r.Name;
			this.idLot = move.GMBLASERP__Lot__c;
			this.lotName = move.GMBLASERP__Lot__r.Name;
			this.moveType = sanitizeType(objectName);
			this.moveDate = move.AcctSeedERP__Movement_Date__c;
			this.inventoryGLAmount = move.GMBLASERP__Inventory_GL_Amount__c;
			this.quantity = move.AcctSeedERP__Quantity__c * -1;

			if(move.GMBLASERP__Project__c != null){
				this.idERP = move.GMBLASERP__Project__c;
				this.erpName = move.GMBLASERP__Project__r.Name;
			}
			if(move.GMBLASERP__Project_Task__c != null){
				this.idERPTask = move.GMBLASERP__Project_Task__c;
				this.erpTaskName = move.GMBLASERP__Project_Task__r.Name;
			}
		}

		public Integer compareTo(Object compareTo) {
			cubeData c = (cubeData)compareTo;
			if( this.moveDate == c.moveDate )
				return 0;
			if( this.moveDate > c.moveDate )
				return -1;
		  
		  return 1;
		}
	}

	public class erpOrderItems{
		public String productName;
		public String serialName;
		public Decimal quantity;
		public Decimal amount;
	}

	@AuraEnabled
	public static String yearStartDate()
	{
		return Date.today().addYears(-1).format();
	}

	@AuraEnabled
	public static list<map<string,string>> listWarehouses()
	{
		list<map<string,string>> listJSON = new list<map<string,string>>();

		Id idWarehouseTransit = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c;
		Id idWarehouseAdjustment = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c;
		for(AcctSeedERP__Warehouse__c whs :
			[SELECT Id, Name 
			 FROM AcctSeedERP__Warehouse__c 
			 WHERE Id != :idWarehouseTransit 
				 AND Id != :idWarehouseAdjustment 
				 ORDER BY Name])
		{
			map<string,string> obj = new map<string,string>{'idWarehouse'=>whs.Id,'warehouseName'=>whs.Name};
			listJSON.add(obj);
		}
		return listJSON;
	}

	@AuraEnabled
	public static String retrieveHistoryDetails(Map<String,String> mapFilter)
	{
		Id idFilter = mapFilter.get('idFilter');
		String objectName = idFilter.getSObjectType().getDescribe().getName();
		return retrieveHistoryDetails_Serial(mapFilter);
	}

	@AuraEnabled
	public static String retrieveHistoryDetails_Serial(Map<String,String> mapFilter)
	{
		String idFilter = mapFilter.get('idFilter');
		String idWarehouse = mapFilter.get('idWarehouse');
		String idProduct = mapFilter.get('idProduct');
		String idSerial = mapFilter.get('idSerial');
		String startDate = mapFilter.get('startDate');
		System.debug('mapFilter');
		System.debug(mapFilter);
		Date filterStart;
		if(startDate != null) {
			String[] dtSplit = startDate.split('-');
			try {
				filterStart = Date.newInstance(Integer.valueOf(dtSplit[0]), Integer.valueOf(dtSplit[1]), Integer.valueOf(dtSplit[2]));
			}catch(Exception e){
				filterStart = Date.parse(startDate);
			}
		}
		System.debug('filterStart');
		System.debug(filterStart);

		String query = 'SELECT Id, GMBLASERP__Warehouse__c, GMBLASERP__Warehouse__r.Name, GMBLASERP__Product__c, GMBLASERP__Product__r.Name, ';
			   query += ' GMBLASERP__Lot__c, GMBLASERP__Lot__r.Name, GMBLASERP__Serial_Number__c, GMBLASERP__Serial_Number__r.Name, ';
			   query += ' AcctSeedERP__Movement_Date__c, AcctSeedERP__Quantity__c, GMBLASERP__Inventory_GL_Amount__c, ';
		String query2  = ' AcctSeedERP__Project__c, AcctSeedERP__Project__r.Name, AcctSeedERP__Project_Task__c, AcctSeedERP__Project_Task__r.Name ';

		String filter = ' WHERE ';
			if(idSerial != null && idSerial != '')
			   filter += ' GMBLASERP__Serial_Number__c =:idSerial';
			if(idProduct != null && idProduct != ''){
			   if(filter != ' WHERE ') filter += ' AND ';
			   filter += ' GMBLASERP__Product__c =:idProduct';
			}
			if(idWarehouse != null && idWarehouse != ''){
			   if(filter != ' WHERE ') filter += ' AND ';
			   filter += ' GMBLASERP__Warehouse__c =:idWarehouse';
			}
			if(filterStart != null){
			   if(filter != ' WHERE ') filter += ' AND ';
			   filter += ' AcctSeedERP__Movement_Date__c >=:filterStart';
			}

		filter += ' ORDER BY AcctSeedERP__Movement_Date__c DESC ';


		List<cubeData> listCubes = new List<cubeData>();
		String queryPurchase = query + query2 + ' FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c ' +filter;
		System.debug(queryPurchase);
		for(AcctSeedERP__Purchase_Order_Inventory_Movement__c pim : Database.query(queryPurchase))
		{
			listCubes.add(new cubeData(pim));
		}
		String queryInbound = query + query2 + ', GMBLASERP__Inventory_Transfer__c, GMBLASERP__Inventory_Transfer__r.Name, GMBLASERP__Inventory_Adjustment__c, GMBLASERP__Inventory_Adjustment__r.Name FROM AcctSeedERP__Inbound_Inventory_Movement__c ' + filter;
		for(AcctSeedERP__Inbound_Inventory_Movement__c pim : Database.query(queryInbound))
		{
			listCubes.add(new cubeData(pim));
		}

		String queryOutbound = query + query2 + ', GMBLASERP__Inventory_Transfer__c, GMBLASERP__Inventory_Transfer__r.Name FROM AcctSeedERP__Outbound_Inventory_Movement__c ' + filter;
		for(AcctSeedERP__Outbound_Inventory_Movement__c pim : Database.query(queryOutbound))
		{
			listCubes.add(new cubeData(pim));
		}

		String queryMfg = query + ' GMBLASERP__Project__c, GMBLASERP__Project__r.Name, GMBLASERP__Project_Task__c, GMBLASERP__Project_Task__r.Name FROM AcctSeedERP__Manufacturing_Inventory_Movement__c ' + filter;
		for(AcctSeedERP__Manufacturing_Inventory_Movement__c pim : Database.query(queryMfg))
		{
			listCubes.add(new cubeData(pim));
		}

		listCubes.sort();

		Set<Id> setIdERP = new Set<Id>();
		for(cubeData cube : listCubes){
			if(cube.idERP != null)
				setIdERP.add(cube.idERP);
		}
		setIdERP.remove(null);
		Map<Id,List<erpOrderItems>> mapListSObject = new Map<Id,List<erpOrderItems>>();
		//for(AcctSeedERP__Manufacturing_Inventory_Movement__c mfg : 
		//	[SELECT Id, 
		//		GMBLASERP__Project__c,
		//		AcctSeedERP__Product__c, 
		//		AcctSeedERP__Quantity__c, 
		//		GMBLASERP__Inventory_GL_Amount__c 
		//	FROM AcctSeedERP__Manufacturing_Inventory_Movement__c 
		//	WHERE GMBLASERP__Project__c IN:setIdERP])
		//{
		//	erpOrderItems erpitem = new erpOrderItems();
		//	erpitem.productName = mfg.AcctSeedERP__Product__c;
		//	erpitem.quantity = mfg.AcctSeedERP__Quantity__c;
		//	erpitem.amount = mfg.GMBLASERP__Inventory_GL_Amount__c;
		//	if(!mapListSObject.containsKey(mfg.GMBLASERP__Project__c))
		//		mapListSObject.put(mfg.GMBLASERP__Project__c, new List<erpOrderItems>());

		//	mapListSObject.get(mfg.GMBLASERP__Project__c).add(erpitem);
		//}

		for(AcctSeedERP__Material__c matl : 
			[SELECT Id, 
				AcctSeedERP__Project__c,
				AcctSeedERP__Project__r.RecordTypeId,
				AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c,
				AcctSeedERP__Product__c, 
				AcctSeedERP__Product__r.Name, 
				AcctSeedERP__Product__r.RecordType.Name, 
				AcctSeedERP__Product__r.AcctSeedERP__Serialized__c, 
				AcctSeedERP__Quantity_per_Unit__c, 
				GMBLASERP__Unit_Price__c,
				(SELECT Id, GMBLASERP__Inventory_GL_Amount__c FROM AcctSeedERP__Manufacturing_Inventory_Movements__r) 
			FROM AcctSeedERP__Material__c 
			WHERE AcctSeedERP__Project__c IN:setIdERP ])
		{
			if(matl.AcctSeedERP__Product__r.RecordType.Name != 'Boat' && matl.AcctSeedERP__Product__r.AcctSeedERP__Serialized__c) continue;
			erpOrderItems erpitem = new erpOrderItems();
			erpitem.productName = matl.AcctSeedERP__Product__r.Name;
			erpitem.quantity = matl.AcctSeedERP__Quantity_per_Unit__c;
			erpitem.amount = matl.GMBLASERP__Unit_Price__c == null ? 0 : matl.GMBLASERP__Unit_Price__c.setScale(2);
			if(!matl.AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c){
				erpitem.amount = 0;
				for(AcctSeedERP__Manufacturing_Inventory_Movement__c mfg : matl.AcctSeedERP__Manufacturing_Inventory_Movements__r){
					erpitem.amount += mfg.GMBLASERP__Inventory_GL_Amount__c;
				}
			}
			if(!mapListSObject.containsKey(matl.AcctSeedERP__Project__c))
				mapListSObject.put(matl.AcctSeedERP__Project__c, new List<erpOrderItems>());

			mapListSObject.get(matl.AcctSeedERP__Project__c).add(erpitem);
		}

		for(cubeData cube : listCubes){
			if(cube.idERP != null && mapListSObject.containsKey(cube.idERP))
				cube.listERPItems = mapListSObject.get(cube.idERP);
		}

		return JSON.serialize(listCubes);
	}

	/*@AuraEnabled
	public static String retrieveHistoryDetails_Product(Map<String,String> mapFilter)
	{
		String idFilter = mapFilter.get('idFilter');
		String idWarehouse = mapFilter.get('idWarehouse');
		String idProduct = mapFilter.get('idProduct');
		String idSerial = mapFilter.get('idSerial');
		String query = 'SELECT Id, GMBLASERP__Inventory_Balance__c, GMBLASERP__Inventory_GL_Amount__c, GMBLASERP__Lot__c, GMBLASERP__Lot__r.Name, GMBLASERP__Movement_Date__c, GMBLASERP__Movement_Type__c, ';
			  query += ' GMBLASERP__Product__c, GMBLASERP__Product__r.Name, GMBLASERP__Quantity__c, GMBLASERP__Serial_Number__c, GMBLASERP__Serial_Number__r.Name, GMBLASERP__Warehouse__c, GMBLASERP__Warehouse__r.Name FROM GMBLASERP__Inventory_Movement_Cube__c ';
			  query += ' WHERE (GMBLASERP__Product__c =:idFilter OR GMBLASERP__Serial_Number__c =:idFilter) ';
		String orderBy = ' ORDER BY GMBLASERP__Movement_Date__c DESC, GMBLASERP__Movement_Type__c ';
		if(idWarehouse != null && idWarehouse != '')
			query += ' AND GMBLASERP__Warehouse__c=:idWarehouse ';
		if(idProduct != null && idProduct != '')
			query += ' AND GMBLASERP__Product__c=:idProduct ';
		if(idSerial != null && idSerial != '')
			query += ' AND GMBLASERP__Serial_Number__c=:idSerial ';

		List<cubeData> listCubes = new List<cubeData>();
		for(GMBLASERP__Inventory_Movement_Cube__c cube : Database.query(query + orderBy))
		{
			cubeData c = new cubeData();
			c.productName = cube.GMBLASERP__Product__r.Name;
			c.idProduct = cube.GMBLASERP__Product__c;
			c.idBalance = cube.GMBLASERP__Inventory_Balance__c;
			c.warehouseName = cube.GMBLASERP__Warehouse__r.Name;
			c.idWarehouse = cube.GMBLASERP__Warehouse__c;
			c.serialName = cube.GMBLASERP__Serial_Number__r.Name;
			c.idSerial = cube.GMBLASERP__Serial_Number__c;
			c.lotName = cube.GMBLASERP__Lot__r.Name;
			c.idLot = cube.GMBLASERP__Lot__c;
			c.moveType = sanitizeType(cube.GMBLASERP__Movement_Type__c);
			c.moveDate = cube.GMBLASERP__Movement_Date__c;
			c.inventoryGLAmount = cube.GMBLASERP__Inventory_GL_Amount__c;
			c.quantity = cube.GMBLASERP__Quantity__c;

			listCubes.add(c);
		}

		return JSON.serialize(listCubes);
	}*/

	@AuraEnabled
	public static Boolean checkCanSeeGLAmount()
	{
		CustomPermissionsReader cpr = new CustomPermissionsReader();
		Boolean canSeeGLAmount = false;
		if(cpr.hasPermission('CanSeeGLAmount'))
			canSeeGLAmount = true;

		return canSeeGLAmount;
	}

	private static String sanitizeType(String moveType)
	{
		return moveType != null ? moveType.replaceAll('AcctSeedERP__', '').replaceAll('AcctSeed__','').replaceAll('__c','').replaceAll('_',' ').replaceAll('Inventory Movement','').trim() : '';
	}
}