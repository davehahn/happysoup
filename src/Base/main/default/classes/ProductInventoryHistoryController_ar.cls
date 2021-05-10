public without sharing class ProductInventoryHistoryController_ar {

	public class cubeData {
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

	/*
		[SELECT Id,
			GMBLASERP__Inventory_Balance__c,
			GMBLASERP__Inventory_GL_Amount__c,
			GMBLASERP__Lot__c,
			GMBLASERP__Lot__r.Name,
			GMBLASERP__Movement_Date__c,
			GMBLASERP__Movement_Type__c,
			GMBLASERP__Product__c,
			GMBLASERP__Product__r.Name,
			GMBLASERP__Quantity__c,
			GMBLASERP__Serial_Number__c,
			GMBLASERP__Serial_Number__r.Name,
			GMBLASERP__Warehouse__c, 
			GMBLASERP__Warehouse__r.Name 
		FROM GMBLASERP__Inventory_Movement_Cube__c 
		WHERE (GMBLASERP__Product__c =:idFilter 
			OR GMBLASERP__Serial_Number__c =:idFilter)
		ORDER BY GMBLASERP__Movement_Date__c DESC]

	*/

	@AuraEnabled
	public static String retrieveHistoryDetails(Map<String,String> mapFilter)
	{
		String idFilter = mapFilter.get('idFilter');
		String idWarehouse = mapFilter.get('idWarehouse');
		String query = 'SELECT Id, GMBLASERP__Inventory_Balance__c, GMBLASERP__Inventory_GL_Amount__c, GMBLASERP__Lot__c, GMBLASERP__Lot__r.Name, GMBLASERP__Movement_Date__c, GMBLASERP__Movement_Type__c, ';
			  query += ' GMBLASERP__Product__c, GMBLASERP__Product__r.Name, GMBLASERP__Quantity__c, GMBLASERP__Serial_Number__c, GMBLASERP__Serial_Number__r.Name, GMBLASERP__Warehouse__c, GMBLASERP__Warehouse__r.Name FROM GMBLASERP__Inventory_Movement_Cube__c ';
			  query += ' WHERE (GMBLASERP__Product__c =:idFilter OR GMBLASERP__Serial_Number__c =:idFilter) ';
		String orderBy = ' ORDER BY GMBLASERP__Movement_Date__c DESC, GMBLASERP__Movement_Type__c ';
		if(idWarehouse != null && idWarehouse != '')
			query += ' AND GMBLASERP__Warehouse__c=:idWarehouse ';

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
	}

	private static String sanitizeType(String moveType)
	{
		return moveType != null ? moveType.replaceAll('AcctSeedERP__', '').replaceAll('AcctSeed__','').replaceAll('__c','').replaceAll('_',' ').replaceAll('Inventory Movement','') : '';
	}
}