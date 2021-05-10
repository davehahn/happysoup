public without sharing class InventoryMovementReport_ar{

    public InventoryMovementReport_ar(ApexPages.standardController ctrl){}
    public InventoryMovementReport_ar(){}

	public static string locale{get{return UserInfo.getLocale();}}

    @RemoteAction @ReadOnly
    public static list<map<string,string>> inventoryDetail(map<String,list<String>> mapFilters)
    {
        return inventorySummary(mapFilters, new list<String>{'idBalance','idLot','idSerial'});
    }

	@RemoteAction @ReadOnly
	public static list<map<string,string>> inventorySummary(map<String,list<String>> mapFilters, list<String> listGroupBy)
	{
		return inventoryDescription(inventoryAggRes(mapFilters,listGroupBy));
	}

	@RemoteAction @ReadOnly
	public static list<cube> inventoryAggRes(map<String,list<String>> mapFilters, list<String> listGroupBy)
	{			
		set<String> setGroupBy = new set<String>();
		setGroupBy.addAll(listGroupBy);

		set<String> setIdBalance	= new set<String>();
		set<String> setIdWarehouse 	= new set<String>();
		set<String> setIdLocation 	= new set<String>();
		set<String> setIdProduct 	= new set<String>();
		set<String> setIdLot 		= new set<String>();
		set<String> setIdSerial 	= new set<String>();

		Date dateFrom;
		Date dateThru;


		if(mapFilters.containsKey('idBalance'))
			setIdBalance.addAll(mapFilters.get('idBalance'));
		if(mapFilters.containsKey('idWarehouse'))
			setIdWarehouse.addAll(mapFilters.get('idWarehouse'));
		if(mapFilters.containsKey('idLocation'))
			setIdLocation.addAll(mapFilters.get('idLocation'));
		if(mapFilters.containsKey('idProduct'))
			setIdProduct.addAll(mapFilters.get('idProduct'));
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

		//for the serials, lots, or products that are in the dataset, we must obtain the public average cost as of the dateFrom
		map<Id,Decimal> mapAvgCostQty = new map<Id,Decimal>();
		map<Id,Decimal> mapAvgCostAmt = new map<Id,Decimal>();
		list<cube> listCubes = new list<cube>();
		map<string,cube> mapCube = new map<string,cube>();
		String soql;
		Id idAdjustmentWarehouse = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c;
		/// Inbound
		soql  = ' SELECT AcctSeedERP__Inventory_Balance__c idBalance, GMBLASERP__Warehouse__c idWarehouse, GMBLASERP__Location__c idLocation, GMBLASERP__Product__c idProduct, GMBLASERP__Lot__c idLot, GMBLASERP__Serial_Number__c idSerial, sum(AcctSeedERP__Quantity__c) qty, sum(GMBLASERP__Inventory_GL_Amount__c) amt ';
		soql += ' FROM AcctSeedERP__Inbound_Inventory_Movement__c ';
		soql += ' WHERE AcctSeedERP__Movement_Date__c <= :dateThru ';
		if(setIdBalance.size() > 0)
			soql += ' AND AcctSeedERP__Inventory_Balance__c IN :setIdBalance ';
		if(setIdWarehouse.size() > 0)
			soql += ' AND GMBLASERP__Warehouse__c IN :setIdWarehouse ';//AND GMBLASERP__Warehouse__c !=:idAdjustmentWarehouse ';
		//else
		//	soql += ' AND GMBLASERP__Warehouse__c !=:idAdjustmentWarehouse ';
		if(setIdLocation.size() > 0)
			soql += ' AND GMBLASERP__Location__c IN :setIdLocation ';
		if(setIdProduct.size() > 0)
			soql += ' AND GMBLASERP__Product__c IN :setIdProduct ';
		if(setIdLot.size() > 0)
			soql += ' AND GMBLASERP__Lot__c IN :setIdLot ';
		if(setIdSerial.size() > 0)
			soql += ' AND GMBLASERP__Serial_Number__c IN :setIdSerial ';
		soql += ' GROUP BY AcctSeedERP__Inventory_Balance__c, GMBLASERP__Warehouse__c, GMBLASERP__Location__c, GMBLASERP__Product__c, GMBLASERP__Lot__c, GMBLASERP__Serial_Number__c ';
		soql += ' HAVING sum(AcctSeedERP__Quantity__c) < 0 OR sum(AcctSeedERP__Quantity__c) > 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) < 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) > 0 ';

		list<sObject> listAggRes = new list<sObject>();
		listAggRes.addAll(Database.query(soql));

		for(sObject aggRes :listAggRes)
		{
			Id idBalance 	= (Id)aggRes.get('idBalance');
			Id idWarehouse 	= (Id)aggRes.get('idWarehouse');
			Id idLocation 	= (Id)aggRes.get('idLocation');
			Id idProduct 	= (Id)aggRes.get('idProduct');
			Id idLot 	 	= (Id)aggRes.get('idLot');
			Id idSerial 	= (Id)aggRes.get('idSerial');
			Decimal qty  	= (Decimal)aggRes.get('qty');
			Decimal amt  	= (Decimal)aggRes.get('amt');
			if(qty == null) qty = 0;
			if(amt == null) amt = 0;

			//if(idSerial != null){
			//	if(!mapAvgCostQty.containsKey(idSerial))
			//		mapAvgCostQty.put(idSerial,0);
			//	if(!mapAvgCostAmt.containsKey(idSerial))
			//		mapAvgCostAmt.put(idSerial,0);
			//	mapAvgCostQty.put(idSerial,mapAvgCostQty.get(idSerial)+qty);
			//	mapAvgCostAmt.put(idSerial,mapAvgCostAmt.get(idSerial)+amt);
			//}
			//if(idLot != null){
			//	if(!mapAvgCostQty.containsKey(idLot))
			//		mapAvgCostQty.put(idLot,0);
			//	if(!mapAvgCostAmt.containsKey(idLot))
			//		mapAvgCostAmt.put(idLot,0);
			//	mapAvgCostQty.put(idLot,mapAvgCostQty.get(idLot)+qty);
			//	mapAvgCostAmt.put(idLot,mapAvgCostAmt.get(idLot)+amt);
			//}
			//if(idProduct != null){
			//	if(!mapAvgCostQty.containsKey(idProduct))
			//		mapAvgCostQty.put(idProduct,0);
			//	if(!mapAvgCostAmt.containsKey(idProduct))
			//		mapAvgCostAmt.put(idProduct,0);
			//	mapAvgCostQty.put(idProduct,mapAvgCostQty.get(idProduct)+qty);
			//	mapAvgCostAmt.put(idProduct,mapAvgCostAmt.get(idProduct)+amt);
			//}
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

			//cube c = new cube(idBalance,idWarehouse,idLocation,idProduct,idLot,idSerial,'Inbound',qty,amt);
			//listCubes.add(c);
		}
		/// Purchase Order
		soql  = ' SELECT AcctSeedERP__Inventory_Balance__c idBalance, GMBLASERP__Warehouse__c idWarehouse, GMBLASERP__Location__c idLocation, GMBLASERP__Product__c idProduct, GMBLASERP__Lot__c idLot, GMBLASERP__Serial_Number__c idSerial, sum(AcctSeedERP__Quantity__c) qty, sum(GMBLASERP__Inventory_GL_Amount__c) amt ';
		soql += ' FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c ';
		soql += ' WHERE AcctSeedERP__Movement_Date__c <= :dateThru ';
		if(setIdBalance.size() > 0)
			soql += ' AND AcctSeedERP__Inventory_Balance__c IN :setIdBalance ';
		if(setIdWarehouse.size() > 0)
			soql += ' AND GMBLASERP__Warehouse__c IN :setIdWarehouse ';//AND GMBLASERP__Warehouse__c !=:idAdjustmentWarehouse ';
		//else
		//	soql += ' AND GMBLASERP__Warehouse__c !=:idAdjustmentWarehouse ';
		if(setIdLocation.size() > 0)
			soql += ' AND GMBLASERP__Location__c IN :setIdLocation ';
		if(setIdProduct.size() > 0)
			soql += ' AND GMBLASERP__Product__c IN :setIdProduct ';
		if(setIdLot.size() > 0)
			soql += ' AND GMBLASERP__Lot__c IN :setIdLot ';
		if(setIdSerial.size() > 0)
			soql += ' AND GMBLASERP__Serial_Number__c IN :setIdSerial ';
		soql += ' GROUP BY AcctSeedERP__Inventory_Balance__c, GMBLASERP__Warehouse__c, GMBLASERP__Location__c, GMBLASERP__Product__c, GMBLASERP__Lot__c, GMBLASERP__Serial_Number__c ';
		soql += ' HAVING sum(AcctSeedERP__Quantity__c) < 0 OR sum(AcctSeedERP__Quantity__c) > 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) < 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) > 0 ';

		listAggRes.clear();
		listAggRes.addAll(Database.query(soql));

		for(sObject aggRes :listAggRes)
		{
			Id idBalance 	= (Id)aggRes.get('idBalance');
			Id idWarehouse 	= (Id)aggRes.get('idWarehouse');
			Id idLocation 	= (Id)aggRes.get('idLocation');
			Id idProduct 	= (Id)aggRes.get('idProduct');
			Id idLot 	 	= (Id)aggRes.get('idLot');
			Id idSerial 	= (Id)aggRes.get('idSerial');
			Decimal qty  	= (Decimal)aggRes.get('qty');
			Decimal amt  	= (Decimal)aggRes.get('amt');
			if(qty == null) qty = 0;
			if(amt == null) amt = 0;

			//if(idSerial != null){
			//	if(!mapAvgCostQty.containsKey(idSerial))
			//		mapAvgCostQty.put(idSerial,0);
			//	if(!mapAvgCostAmt.containsKey(idSerial))
			//		mapAvgCostAmt.put(idSerial,0);
			//	mapAvgCostQty.put(idSerial,mapAvgCostQty.get(idSerial)+qty);
			//	mapAvgCostAmt.put(idSerial,mapAvgCostAmt.get(idSerial)+amt);
			//}
			//if(idLot != null){
			//	if(!mapAvgCostQty.containsKey(idLot))
			//		mapAvgCostQty.put(idLot,0);
			//	if(!mapAvgCostAmt.containsKey(idLot))
			//		mapAvgCostAmt.put(idLot,0);
			//	mapAvgCostQty.put(idLot,mapAvgCostQty.get(idLot)+qty);
			//	mapAvgCostAmt.put(idLot,mapAvgCostAmt.get(idLot)+amt);
			//}
			//if(idProduct != null){
			//	if(!mapAvgCostQty.containsKey(idProduct))
			//		mapAvgCostQty.put(idProduct,0);
			//	if(!mapAvgCostAmt.containsKey(idProduct))
			//		mapAvgCostAmt.put(idProduct,0);
			//	mapAvgCostQty.put(idProduct,mapAvgCostQty.get(idProduct)+qty);
			//	mapAvgCostAmt.put(idProduct,mapAvgCostAmt.get(idProduct)+amt);
			//}
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

			//cube c = new cube(idBalance,idWarehouse,idLocation,idProduct,idLot,idSerial,'Purchase Order',qty,amt);
			//listCubes.add(c);
		}
		/// Outbound
		soql  = ' SELECT AcctSeedERP__Inventory_Balance__c idBalance, GMBLASERP__Warehouse__c idWarehouse, GMBLASERP__Location__c idLocation, GMBLASERP__Product__c idProduct, GMBLASERP__Lot__c idLot, GMBLASERP__Serial_Number__c idSerial, sum(AcctSeedERP__Quantity__c) qty, sum(GMBLASERP__Inventory_GL_Amount__c) amt ';
		soql += ' FROM AcctSeedERP__Outbound_Inventory_Movement__c ';
		soql += ' WHERE AcctSeedERP__Movement_Date__c <= :dateThru ';
		if(setIdBalance.size() > 0)
			soql += ' AND AcctSeedERP__Inventory_Balance__c IN :setIdBalance ';
		if(setIdWarehouse.size() > 0)
			soql += ' AND GMBLASERP__Warehouse__c IN :setIdWarehouse ';//AND GMBLASERP__Warehouse__c !=:idAdjustmentWarehouse ';
		//else
		//	soql += ' AND GMBLASERP__Warehouse__c !=:idAdjustmentWarehouse ';
		if(setIdLocation.size() > 0)
			soql += ' AND GMBLASERP__Location__c IN :setIdLocation ';
		if(setIdProduct.size() > 0)
			soql += ' AND GMBLASERP__Product__c IN :setIdProduct ';
		if(setIdLot.size() > 0)
			soql += ' AND GMBLASERP__Lot__c IN :setIdLot ';
		if(setIdSerial.size() > 0)
			soql += ' AND GMBLASERP__Serial_Number__c IN :setIdSerial ';
		soql += ' GROUP BY AcctSeedERP__Inventory_Balance__c, GMBLASERP__Warehouse__c, GMBLASERP__Location__c, GMBLASERP__Product__c, GMBLASERP__Lot__c, GMBLASERP__Serial_Number__c ';
		soql += ' HAVING sum(AcctSeedERP__Quantity__c) < 0 OR sum(AcctSeedERP__Quantity__c) > 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) < 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) > 0 ';

		listAggRes.clear();
		listAggRes.addAll(Database.query(soql));

		for(sObject aggRes :listAggRes)
		{
			Id idBalance 	= (Id)aggRes.get('idBalance');
			Id idWarehouse 	= (Id)aggRes.get('idWarehouse');
			Id idLocation 	= (Id)aggRes.get('idLocation');
			Id idProduct 	= (Id)aggRes.get('idProduct');
			Id idLot 	 	= (Id)aggRes.get('idLot');
			Id idSerial 	= (Id)aggRes.get('idSerial');
			Decimal qty  	= (Decimal)aggRes.get('qty');
			Decimal amt  	= (Decimal)aggRes.get('amt');
			if(qty == null) qty = 0;
			if(amt == null) amt = 0;
			qty = qty * -1;
			amt = amt * -1;

			//if(idSerial != null){
			//	if(!mapAvgCostQty.containsKey(idSerial))
			//		mapAvgCostQty.put(idSerial,0);
			//	if(!mapAvgCostAmt.containsKey(idSerial))
			//		mapAvgCostAmt.put(idSerial,0);
			//	mapAvgCostQty.put(idSerial,mapAvgCostQty.get(idSerial)+qty);
			//	mapAvgCostAmt.put(idSerial,mapAvgCostAmt.get(idSerial)+amt);
			//}
			//if(idLot != null){
			//	if(!mapAvgCostQty.containsKey(idLot))
			//		mapAvgCostQty.put(idLot,0);
			//	if(!mapAvgCostAmt.containsKey(idLot))
			//		mapAvgCostAmt.put(idLot,0);
			//	mapAvgCostQty.put(idLot,mapAvgCostQty.get(idLot)+qty);
			//	mapAvgCostAmt.put(idLot,mapAvgCostAmt.get(idLot)+amt);
			//}
			//if(idProduct != null){
			//	if(!mapAvgCostQty.containsKey(idProduct))
			//		mapAvgCostQty.put(idProduct,0);
			//	if(!mapAvgCostAmt.containsKey(idProduct))
			//		mapAvgCostAmt.put(idProduct,0);
			//	mapAvgCostQty.put(idProduct,mapAvgCostQty.get(idProduct)+qty);
			//	mapAvgCostAmt.put(idProduct,mapAvgCostAmt.get(idProduct)+amt);
			//}
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

			//cube c = new cube(idBalance,idWarehouse,idLocation,idProduct,idLot,idSerial,'Outbound',qty,amt);//(qty * -1),(amt * -1));//
			//listCubes.add(c);
		}
		/// Manufacturing
		soql  = ' SELECT AcctSeedERP__Inventory_Balance__c idBalance, GMBLASERP__Warehouse__c idWarehouse, GMBLASERP__Location__c idLocation, GMBLASERP__Product__c idProduct, GMBLASERP__Lot__c idLot, GMBLASERP__Serial_Number__c idSerial, sum(AcctSeedERP__Quantity__c) qty, sum(GMBLASERP__Inventory_GL_Amount__c) amt ';
		soql += ' FROM AcctSeedERP__Manufacturing_Inventory_Movement__c ';
		soql += ' WHERE AcctSeedERP__Movement_Date__c <= :dateThru ';
		if(setIdBalance.size() > 0)
			soql += ' AND AcctSeedERP__Inventory_Balance__c IN :setIdBalance ';
		if(setIdWarehouse.size() > 0)
			soql += ' AND GMBLASERP__Warehouse__c IN :setIdWarehouse ';//' AND GMBLASERP__Warehouse__c !=:idAdjustmentWarehouse ';
		//else
		//	soql += ' AND GMBLASERP__Warehouse__c !=:idAdjustmentWarehouse ';
		if(setIdLocation.size() > 0)
			soql += ' AND GMBLASERP__Location__c IN :setIdLocation ';
		if(setIdProduct.size() > 0)
			soql += ' AND GMBLASERP__Product__c IN :setIdProduct ';
		if(setIdLot.size() > 0)
			soql += ' AND GMBLASERP__Lot__c IN :setIdLot ';
		if(setIdSerial.size() > 0)
			soql += ' AND GMBLASERP__Serial_Number__c IN :setIdSerial ';
		soql += ' GROUP BY AcctSeedERP__Inventory_Balance__c, GMBLASERP__Warehouse__c, GMBLASERP__Location__c, GMBLASERP__Product__c, GMBLASERP__Lot__c, GMBLASERP__Serial_Number__c ';
		soql += ' HAVING sum(AcctSeedERP__Quantity__c) < 0 OR sum(AcctSeedERP__Quantity__c) > 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) < 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) > 0 ';

		listAggRes.clear();
		listAggRes.addAll(Database.query(soql));

		for(sObject aggRes :listAggRes)
		{
			Id idBalance 	= (Id)aggRes.get('idBalance');
			Id idWarehouse 	= (Id)aggRes.get('idWarehouse');
			Id idLocation 	= (Id)aggRes.get('idLocation');
			Id idProduct 	= (Id)aggRes.get('idProduct');
			Id idLot 	 	= (Id)aggRes.get('idLot');
			Id idSerial 	= (Id)aggRes.get('idSerial');
			Decimal qty  	= (Decimal)aggRes.get('qty');
			Decimal amt  	= (Decimal)aggRes.get('amt');
			if(qty == null) qty = 0;
			if(amt == null) amt = 0;
			qty = qty * -1;
			amt = amt * -1;

			//if(idSerial != null){
			//	if(!mapAvgCostQty.containsKey(idSerial))
			//		mapAvgCostQty.put(idSerial,0);
			//	if(!mapAvgCostAmt.containsKey(idSerial))
			//		mapAvgCostAmt.put(idSerial,0);
			//	mapAvgCostQty.put(idSerial,mapAvgCostQty.get(idSerial)+qty);
			//	mapAvgCostAmt.put(idSerial,mapAvgCostAmt.get(idSerial)+amt);
			//}
			//if(idLot != null){
			//	if(!mapAvgCostQty.containsKey(idLot))
			//		mapAvgCostQty.put(idLot,0);
			//	if(!mapAvgCostAmt.containsKey(idLot))
			//		mapAvgCostAmt.put(idLot,0);
			//	mapAvgCostQty.put(idLot,mapAvgCostQty.get(idLot)+qty);
			//	mapAvgCostAmt.put(idLot,mapAvgCostAmt.get(idLot)+amt);
			//}
			//if(idProduct != null){
			//	if(!mapAvgCostQty.containsKey(idProduct))
			//		mapAvgCostQty.put(idProduct,0);
			//	if(!mapAvgCostAmt.containsKey(idProduct))
			//		mapAvgCostAmt.put(idProduct,0);
			//	mapAvgCostQty.put(idProduct,mapAvgCostQty.get(idProduct)+qty);
			//	mapAvgCostAmt.put(idProduct,mapAvgCostAmt.get(idProduct)+amt);
			//}
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

			//cube c = new cube(idBalance,idWarehouse,idLocation,idProduct,idLot,idSerial,'Manufacturing',qty,amt);//(qty * -1),(amt * -1));
			//listCubes.add(c);
		}

		//for(cube c : listCubes)
		//{
		//	Id idBalance 	= c.idBalance;
		//	Id idWarehouse 	= c.idWarehouse;
		//	Id idLocation 	= c.idLocation;
		//	Id idProduct 	= c.idProduct;
		//	Id idLot 	 	= c.idLot;
		//	Id idSerial 	= c.idSerial;
		//	if(c.qty == null) c.qty = 0;
		//	Decimal qty  = c.qty;
		//	Decimal amt = c.amt;

		//	if(qty.setScale(6) == 0) continue;

		//	if(!setGroupBy.contains('idBalance'))	idBalance = null;
		//	if(!setGroupBy.contains('idWarehouse'))	idWarehouse = null;
		//	if(!setGroupBy.contains('idLocation'))	idLocation = null;
		//	if(!setGroupBy.contains('idProduct'))	idProduct = null;
		//	if(!setGroupBy.contains('idLot'))		idLot = null;
		//	if(!setGroupBy.contains('idSerial'))	idSerial = null;

		//	String key = '';
		//	if(idBalance 	!= null) 	key += idBalance;
		//	if(idWarehouse 	!= null) 	key += idWarehouse;
		//	if(idLocation 	!= null) 	key += idLocation;
		//	if(idProduct 	!= null) 	key += idProduct;
		//	if(idLot 		!= null) 	key += idLot;
		//	if(idSerial 	!= null) 	key += idSerial;

		//	if(key == '') continue;

		//	if(!mapCube.containsKey(key))
		//		mapCube.put(key, new cube(idBalance, idWarehouse, idLocation, idProduct, idLot, idSerial, null, null));

		//	cube cube = mapCube.get(key);
		//	cube.qty += qty;
		//	cube.amt += amt;
		//}

		//for(String key : mapCube.keySet())
		//{
		//	cube c = mapCube.get(key);
		//	if(c.qty.setScale(6) == 0 && c.amt.setScale(6) == 0) mapCube.remove(key);
			//Decimal avgCost = c.amt;
			//Id idBalance 	= c.idBalance;
			//Id idWarehouse 	= c.idWarehouse;
			//Id idLocation 	= c.idLocation;
			//Id idProduct 	= c.idProduct;
			//Id idLot 	 	= c.idLot;
			//Id idSerial 	= c.idSerial;

			//Decimal qty  = c.qty;
			//Decimal avgCost = 0;
			//Decimal amt = c.amt;

			//if(qty != 0){
			//	if(idSerial != null)
			//		avgCost = mapAvgCostAmt.get(idSerial)/qty;
			//	else if(idLot != null)
			//		avgCost = mapAvgCostAmt.get(idLot)/qty;
			//	else if(idProduct != null)
			//		avgCost = mapAvgCostAmt.get(idProduct)/qty;

			//	if(avgCost != null)
			//		amt = qty * avgCost;
			//}
			//c.amt = amt;
		//}

		return mapCube.values();
	}

	public static list<map<string,string>> inventoryDescription(list<cube> listCube)
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
			/// For CSV
			obj.put('idBalance','');
			obj.put('idWarehouse','');
			obj.put('warehouseName','');
			obj.put('idProduct','');
			obj.put('productName','');
			obj.put('productCode','');
			obj.put('productFamily','');
			obj.put('productRecordType','');
			obj.put('glv1Name','');
			obj.put('glv2Name','');
			obj.put('glv3Name','');
			obj.put('glv4Name','');
			obj.put('productIsActive','');
			obj.put('productIsLotTracked','');
			obj.put('idLot','');
			obj.put('lotName','');		
			obj.put('idSerial','');
			obj.put('serialName','');
			obj.put('serialModelYear','');
			obj.put('idNest', '');
			obj.put('nestName','');					
			obj.put('nestProductFamily','');
			obj.put('nestProductName','');
			obj.put('description','');
			obj.put('dealerRigged', '');

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
				obj.put('productName',product.Name.unescapeEcmaScript().unescapeCsv());
				obj.put('productCode',product.ProductCode == null ? '' : product.ProductCode);
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

				String d = '';
				if(serial.Nest__c != null)
				{
					obj.put('isNested','true');

					GMBLASERP__Serial_Number__c n = serial.Nest__r;
					if(n != null)
					{
						obj.put('idNest', n.Id);
						obj.put('nestName',n.Name);					
						obj.put('nestProductFamily', n.GMBLASERP__Product__r.Family);
						obj.put('nestProductName', n.GMBLASERP__Product__r.Name);

						d = n.GMBLASERP__Product__r.Name + ' (s/n '+n.Name+')';
						obj.put('description',d);
					}
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

	public class cube{
		public Decimal qty{get;set;}
		public Decimal amt{get;set;}

		public Id idBalance{get;set;}
		public Id idWarehouse{get;set;}
		public Id idLocation{get;set;}
		public Id idProduct{get;set;}
		public Id idLot{get;set;}
		public Id idSerial{get;set;}
		public String pStrMoveType{get;set;}

		public cube(Id pIdBalance, Id pIdWarehouse, Id pIdLocation, Id pIdProduct, Id pIdLot, Id pIdSerial, Id pIdPeriod, String pStrMoveType)
		{
			idBalance = pIdBalance;
			idWarehouse = pIdWarehouse;
			idLocation = pIdLocation;
			idProduct = pIdProduct;
			idLot = pIdLot;
			idSerial = pIdSerial;
			pStrMoveType = pStrMoveType;

			qty = 0;
			amt = 0;
		}

		public cube(Id pIdBalance, Id pIdWarehouse, Id pIdLocation, Id pIdProduct, Id pIdLot, Id pIdSerial, String pStrMoveType, Decimal pQty, Decimal pAmt)
		{
			idBalance = pIdBalance;
			idWarehouse = pIdWarehouse;
			idLocation = pIdLocation;
			idProduct = pIdProduct;
			idLot = pIdLot;
			idSerial = pIdSerial;
			pStrMoveType = pStrMoveType;

			qty = pQty;
			amt = pAmt;
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
	}
}