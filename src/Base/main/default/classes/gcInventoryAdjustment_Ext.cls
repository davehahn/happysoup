global without sharing class gcInventoryAdjustment_Ext {

	global gcInventoryAdjustment_Ext(ApexPages.standardController c){
		defaultRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Boat').getRecordTypeId();
	}
	global gcInventoryAdjustment_Ext(){
		defaultRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Boat').getRecordTypeId();
	}

	global List<SelectOption> getListProductType()
	{
		List<SelectOption> listOptions = new List<SelectOption>();

		Map<Id,Schema.RecordTypeInfo> productRecordTypeInfo = Schema.SObjectType.Product2.getRecordTypeInfosById();
		listOptions.add(new selectOption('', '-- SELECT ALL --'));

		for(Id idRT : productRecordTypeInfo.keySet())
		{
			listOptions.add(new selectOption(idRT, productRecordTypeInfo.get(idRT).getName()));
		}

		return listOptions;
	}

	global static String defaultRecordId{get;set;}

	@RemoteAction @ReadOnly
	global static map<string,string> retrieveAdjustment(Id idAdjustment)
	{
		//return GMBLASERP.gcInventoryAdjustment_Ext.retrieveAdjustment(idAdjustment);
		map<string,string> m = new map<string,string>();
		for(GMBLASERP__Inventory_Adjustment__c adj :
		[SELECT Id, GMBLASERP__Adjustment_Type__c
		FROM GMBLASERP__Inventory_Adjustment__c
		WHERE Id = :idAdjustment
		LIMIT 1])
		{
			m.put('adjustmentType',adj.GMBLASERP__Adjustment_Type__c);
		}
		return m;
	}

	@RemoteAction @ReadOnly
	global static list<map<string,string>> retrieveMoves(string idFilter)
	{
		//return GMBLASERP.gcInventoryAdjustment_Ext.retrieveMoves(idFilter);
		list<map<string,string>> listJSON = new list<map<string,string>>();

		Date dateEarliestOpen = date.Today();
		for(AcctSeed__Accounting_Period__c period :
		[SELECT AcctSeed__Start_Date__c
		FROM AcctSeed__Accounting_Period__c
		WHERE AcctSeed__Status__c = 'Open'
		ORDER BY AcctSeed__Start_Date__c
		LIMIT 1])
		{
			if(period.AcctSeed__Start_Date__c < dateEarliestOpen)
				dateEarliestOpen = period.AcctSeed__Start_Date__c;
		}

		for(AcctSeedERP__Inbound_Inventory_Movement__c move :
		[SELECT Id, Name,
			AcctSeedERP__Inventory_Balance__c,
			AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c,
			AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r.Id,
			AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r.Name,
			AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r.ProductCode,
			AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r.Family,
			AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name,
			AcctSeedERP__Movement_Date__c,
			AcctSeedERP__Quantity__c,
			GMBLASERP__Inventory_GL_Amount__c,
			GMBLASERP__Lot__c,
			GMBLASERP__Lot__r.Name,
			GMBLASERP__Serial_Number__c,
			GMBLASERP__Serial_Number__r.Name,
		(SELECT
			AcctSeedERP__Inventory_Balance__c,
			AcctSeedERP__Quantity__c,
			GMBLASERP__Inventory_GL_Amount__c,
			GMBLASERP__Lot__c,
			GMBLASERP__Serial_Number__c
		FROM AcctSeedERP__Outbound_Inventory_Movements__r)
		FROM AcctSeedERP__Inbound_Inventory_Movement__c
		WHERE Id = :idFilter
		OR (GMBLASERP__Inventory_Adjustment__c = :idFilter AND GMBLASERP__Inventory_Adjustment__c != null)
		ORDER BY AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r.Name,
			AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r.ProductCode,
			GMBLASERP__Lot__r.Name,
			GMBLASERP__Serial_Number__r.Name,
			CreatedDate,
			Id])
		{
			map<string,string> m = new map<string,string>();

			Product2 p = move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r;

			Decimal qty = move.AcctSeedERP__Quantity__c;
			Decimal amt = move.GMBLASERP__Inventory_GL_Amount__c;
			if(qty == null) qty = 0;
			if(amt == null) amt = 0;

			for(AcctSeedERP__Outbound_Inventory_Movement__c moveOut : move.AcctSeedERP__Outbound_Inventory_Movements__r)
			{
				if(moveOut.AcctSeedERP__Quantity__c != null) qty -= moveOut.AcctSeedERP__Quantity__c;
				if(moveOut.GMBLASERP__Inventory_GL_Amount__c != null) amt -= moveOut.GMBLASERP__Inventory_GL_Amount__c;
			}

			Decimal avg = 0;
			if(qty != 0) avg = amt/qty;

			m.put('idMove',move.Id);
			m.put('moveNumber', String.valueOf(Integer.valueOf(move.Name.replaceAll('[^0-9]',''))));

			m.put('idBalance',move.AcctSeedERP__Inventory_Balance__c);
			m.put('warehouseName',move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name);

			m.put('idProduct', p.Id);
			m.put('productName',p.Name);
			m.put('productFamily',p.Family);
			m.put('productCode',p.ProductCode);

			if(move.GMBLASERP__Lot__c != null)
			{
				m.put('idLot',move.GMBLASERP__Lot__c);
				m.put('lotName',move.GMBLASERP__Lot__r.Name);
			}

			if(move.GMBLASERP__Serial_Number__c != null)
			{
				m.put('idSerial',move.GMBLASERP__Serial_Number__c);
				m.put('serialName',move.GMBLASERP__Serial_Number__r.Name);
			}

			m.put('avg',String.valueOf(avg.setScale(6)));
			m.put('amt',String.valueOf(amt.setScale(6)));
			m.put('qty',string.valueOf(qty.setScale(0)));

			m.put('periodIsOpen','false');
			if(move.AcctSeedERP__Movement_Date__c != null && move.AcctSeedERP__Movement_Date__c >= dateEarliestOpen)
				m.put('periodIsOpen','true');

			listJSON.add(m);
		}
		return listJSON;
	}

	@RemoteAction @ReadOnly
	global static list<map<string,string>> retrieveInventory(string idAdjustment, string idObject, String idType, String searchText)
	{
		GMBLASERP__Inventory_Adjustment__c adj =
		[SELECT GMBLASERP__Warehouse__c,
			GMBLASERP__Product__c,
			GMBLASERP__Adjustment_Type__c,
			GMBLASERP__Adjustment_Date__c
		FROM GMBLASERP__Inventory_Adjustment__c
		WHERE Id = :idAdjustment][0];

		map<string,list<string>> mapFilters = new map<string,list<string>>();
		Set<String> setIdProducts = new Set<String>();
		List<String> listIdProducts = new List<String>();
		mapFilters.put('dateThru', new list<string>{String.valueOf(adj.GMBLASERP__Adjustment_Date__c.format())});

		if(adj.GMBLASERP__Warehouse__c != null)
			mapFilters.put('idWarehouse', new list<string>{adj.GMBLASERP__Warehouse__c});
		if(adj.GMBLASERP__Product__c != null)
			mapFilters.put('idProduct', new list<string>{adj.GMBLASERP__Product__c});

		if(idObject != null)
		{
			if((Id.valueOf(idObject)).getSObjectType() == GMBLASERP__Serial_Number__c.sObjectType)
				mapFilters.put('idSerial', new list<string>{idObject});
			else if((Id.valueOf(idObject)).getSObjectType() == GMBLASERP__Lot__c.sObjectType)
				mapFilters.put('idLot', new list<string>{idObject});
			else if((Id.valueOf(idObject)).getSObjectType() == Product2.sObjectType)
				mapFilters.put('idProduct', new list<string>{idObject});
		}

		if(idType != '' && !mapFilters.containsKey('idProduct'))
		{
			List<String> listProductId = new List<String>();
			if(idType != '' && searchText != '' && searchText != null) {
				searchText = '%'+searchText.replaceAll('[*]','%') +'%';
				for (Product2 p : [
					SELECT Id
					FROM Product2
					WHERE AcctSeed__Inventory_Product__c = true
					AND (ProductCode like:searchText OR Name like:searchText)
					AND RecordTypeId = :idType
				]) {
					listProductId.add(p.Id);
				}
			}else if(idType != '') {
				for (Product2 p : [
					SELECT Id
					FROM Product2
					WHERE AcctSeed__Inventory_Product__c = true
					AND RecordTypeId = :idType
				]) {
					listProductId.add(p.Id);
				}
			}
			if(!listProductId.isEmpty())
				mapFilters.put('idProduct',listProductId);
			else
				return new list<map<string,string>>();
		}

		return gcInventoryMovementCube_Report.inventorySummary(mapFilters, new list<string>{'idProduct','idLot','idSerial'});
	}

	@RemoteAction
	global static map<string,string> adjustQuantity(String idMove, Decimal qty)
	{
		//return GMBLASERP.gcInventoryAdjustment_Ext.adjustQuantity(idMove, qty);
		AcctSeedERP__Inbound_Inventory_Movement__c move = [SELECT Id FROM AcctSeedERP__Inbound_Inventory_Movement__c WHERE Id =: idMove][0];

		if(qty == null) qty = 0;
		move.AcctSeedERP__Quantity__c = qty;

		update move;

		return retrieveMoves(move.Id)[0];
	}

	@RemoteAction
	global static map<string,string> adjustValue(String idMove, Decimal amt)
	{
		//return GMBLASERP.gcInventoryAdjustment_Ext.adjustValue(idMove, amt);
		AcctSeedERP__Inbound_Inventory_Movement__c moveIn = new AcctSeedERP__Inbound_Inventory_Movement__c();
		AcctSeedERP__Outbound_Inventory_Movement__c moveOut = new AcctSeedERP__Outbound_Inventory_Movement__c();
		for(AcctSeedERP__Inbound_Inventory_Movement__c move :
		[SELECT Id,
			AcctSeedERP__Inventory_Balance__c,
			AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c,
			AcctSeedERP__Movement_Date__c,
			AcctSeedERP__Quantity__c,
			AcctSeedERP__Type__c,
			AcctSeedERP__Unit_Cost__c,
			GMBLASERP__Cost_Override__c,
			GMBLASERP__Inventory_Adjustment__r.GMBLASERP__Adjustment_Type__c,
			GMBLASERP__Inventory_GL_Amount__c,
			GMBLASERP__Lot__c,
			GMBLASERP__Serial_Number__c,
		(SELECT Id,
			AcctSeedERP__Type__c,
			AcctSeedERP__Quantity__c,
			AcctSeedERP__Unit_Cost__c,
			GMBLASERP__Cost_Override__c,
			GMBLASERP__Inventory_GL_Amount__c
		FROM AcctSeedERP__Outbound_Inventory_Movements__r
		LIMIT 1)
		FROM AcctSeedERP__Inbound_Inventory_Movement__c
		WHERE Id = :idMove])
		{
			moveIn = move;
			moveOut = move.AcctSeedERP__Outbound_Inventory_Movements__r[0];
		}

		Decimal qtyInv = 0;
		Decimal amtInv = 0;

		for(AggregateResult aggRes :
		[SELECT sum(GMBLASERP__Quantity__c) qty, sum(GMBLASERP__Inventory_GL_Amount__c) amt
		FROM GMBLASERP__Inventory_Movement_Cube__c
		WHERE GMBLASERP__Product__c = :moveIn.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c
		AND GMBLASERP__Lot__c = :moveIn.GMBLASERP__Lot__c
		AND GMBLASERP__Serial_Number__c = :moveIn.GMBLASERP__Serial_Number__c
		AND GMBLASERP__Movement_Date__c <= :moveIn.AcctSeedERP__Movement_Date__c])
		{
			qtyInv = (Decimal)aggRes.get('qty');
			amtInv = (Decimal)aggRes.get('amt');
		}

		if(qtyInv == null) qtyInv = 0;
		if(amtInv == null) amtInv = 0;

		if(moveIn.AcctSeedERP__Quantity__c != null)
			qtyInv -= moveIn.AcctSeedERP__Quantity__c;
		if(moveOut.AcctSeedERP__Quantity__c != null)
			qtyInv += moveOut.AcctSeedERP__Quantity__c;

		if(moveIn.GMBLASERP__Inventory_GL_Amount__c != null)
			amtInv -= moveIn.GMBLASERP__Inventory_GL_Amount__c;
		if(moveOut.GMBLASERP__Inventory_GL_Amount__c != null)
			amtInv += moveOut.GMBLASERP__Inventory_GL_Amount__c;

		//for serialized inventory, the adjustments take place at the inventory balance at which the serial number
		//is currently located.
		//in order to ensure that the Quantity at that balance does not go above 1 temporarily during the move,
		//the inbound movement must first be cleared, after which the outbound movement and inbound movement are updated

		Decimal unitCost = 0;

		if(moveIn.GMBLASERP__Serial_Number__c != null)
		{
			//move the item out
			moveOut.AcctSeedERP__Quantity__c = 1;
			moveOut.AcctSeedERP__Unit_Cost__c = amtInv.setScale(6);
			update moveOut;

			//move the item in at the new value
			moveIn.AcctSeedERP__Quantity__c = 1;
			moveIn.AcctSeedERP__Unit_Cost__c = (amtInv + amt).setScale(6);
			/// This code is off becuase of too many SOQL
			//update moveIn;

		}
		//for non-serialized inventory, the adjustments take place at the adjustment warehouse
		//in order to ensure that the Quantity at the adjustment warehouse does not go below 0 temporarily during the move,
		//the outbound movement must first be cleared, after which the outbound and inbound movement are updated
		else
		{
			system.debug('stop 10:  reset of move out');
			//reset the move-out
			moveOut.AcctSeedERP__Quantity__c = 0;
			moveOut.AcctSeedERP__Unit_Cost__c = 0;
			//update moveOut;

			unitCost = 0;
			if(qtyInv != 0)
				unitCost = (amtInv + amt)/qtyInv;

			system.debug('stop 20:  move in at new value');
			//move inventory back in at the new value
			moveIn.AcctSeedERP__Quantity__c = qtyInv.setScale(6);
			moveIn.AcctSeedERP__Unit_Cost__c = unitCost.setScale(6);
			// This code is off due to too many SOQL
			update moveIn;

			//move inventory out at the old value
			unitCost = 0;
			if(qtyInv != 0)
				unitCost = amtInv/qtyInv;

			system.debug('stop 30: move out at old value');
			//move all inventory out
			//moveOut = [SELECT Id, AcctSeedERP__Quantity__c,  FROM AcctSeedERP__Outbound_Inventory_Movement__c WHERE Id =:moveOut.Id][0];
			moveOut = new AcctSeedERP__Outbound_Inventory_Movement__c(Id = moveOut.Id);
			moveOut.AcctSeedERP__Quantity__c = qtyInv.setScale(6);
			moveOut.AcctSeedERP__Unit_Cost__c = unitCost.setScale(6);
			//update moveOut;

			system.debug('stop 40:  all done');

		}
		return retrieveMoves(moveIn.Id)[0];
	}

	@RemoteAction
	global static map<string,string> adjustValueIn(String idMove, Decimal amt)
	{
		System.debug('idMove');
		System.debug(idMove);
		System.debug('amt');
		System.debug(amt);
		List<sObject> listIn = new List<sObject>();
		Id idInMove;
		for(AcctSeedERP__Outbound_Inventory_Movement__c move :
		[SELECT Id,
			AcctSeedERP__Quantity__c,
			GMBLASERP__Serial_Number__c,
			GMBLASERP__Serial_Number__r.Current_Unit_Cost__c,
			AcctSeedERP__Unit_Cost__c,
			AcctSeedERP__Inbound_Inventory_Movement__c,
			AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Quantity__c,
			AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Unit_Cost__c
		FROM AcctSeedERP__Outbound_Inventory_Movement__c
		WHERE AcctSeedERP__Inbound_Inventory_Movement__c =:idMove])
		{
			if(move.GMBLASERP__Serial_Number__c != null){
				AcctSeedERP__Inbound_Inventory_Movement__c inMove = new AcctSeedERP__Inbound_Inventory_Movement__c();
				inMove.Id = move.AcctSeedERP__Inbound_Inventory_Movement__c;
				inMove.AcctSeedERP__Quantity__c = move.AcctSeedERP__Quantity__c;
				inMove.AcctSeedERP__Unit_Cost__c = move.AcctSeedERP__Unit_Cost__c + (amt/move.AcctSeedERP__Quantity__c);
				listIn.add(inMove);
			}else{
				move.AcctSeedERP__Quantity__c = move.AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Quantity__c;
				move.AcctSeedERP__Unit_Cost__c = move.AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Unit_Cost__c - (amt/move.AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Quantity__c);
				listIn.add(move);
			}
			idInMove = move.AcctSeedERP__Inbound_Inventory_Movement__c;
		}
		System.debug(listIn);
		System.debug(listIn.size());
		update listIn;
		return retrieveMoves(idInMove)[0];
	}

	@RemoteAction
	global static map<string,string> createAdjustment(String idAdjustment, String idObject)
	{
		//return GMBLASERP.gcInventoryAdjustment_Ext.createAdjustment(idAdjustment, idObject);
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
		Id idProduct;
		Id idBalance;

		for(GMBLASERP__Serial_Number__c serial : [SELECT Id, GMBLASERP__Inventory_Balance__c, GMBLASERP__Lot__c, GMBLASERP__Product__c FROM GMBLASERP__Serial_Number__c WHERE Id =:idObject])
		{
			idSerial = serial.Id;
			idLot = serial.GMBLASERP__Lot__c;
			idProduct = serial.GMBLASERP__Product__c;
			idBalance = serial.GMBLASERP__Inventory_Balance__c;
			idObject = null;
		}
		if(idObject != null)
			for(GMBLASERP__Lot__c lot : [SELECT Id, GMBLASERP__Product__c FROM GMBLASERP__Lot__c WHERE Id =:idObject])
			{
				idLot = lot.Id;
				idProduct = lot.GMBLASERP__Product__c;
				idObject = null;
			}
		if(idObject != null)
			for(Product2 p : [SELECT Id FROM Product2 WHERE Id = :idObject])
			{
				idProduct = p.Id;
				idObject = null;
			}

		if(idObject != null) return new map<string,string>();

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
			AcctSeedERP__Quantity__c = 0,
			AcctSeedERP__Type__c = 'Accounting',
			AcctSeedERP__Unit_Cost__c = 0,
			GMBLASERP__Cost_Override__c = false,
			GMBLASERP__Lot__c = idLot,
			GMBLASERP__Serial_Number__c = idSerial,
			AcctSeedERP__Ledger__c = gcConstants.idActualLedger
		);

		if(adj.GMBLASERP__Adjustment_Type__c == 'Quantity' && idSerial != null)
			moveIn.AcctSeedERP__Quantity__c = -1;
		if(adj.GMBLASERP__Adjustment_Type__c !='Quantity')
			moveIn.GMBLASERP__Cost_Override__c = true;

		System.debug('moveIn');
		System.debug(moveIn);
		insert moveIn;

		if(adj.GMBLASERP__Adjustment_Type__c !='Quantity')
		{
			AcctSeedERP__Outbound_Inventory_Movement__c moveOut = new AcctSeedERP__Outbound_Inventory_Movement__c(
				AcctSeedERP__Debit_GL_Account__c = adj.GMBLASERP__GL_Account__c,
				AcctSeedERP__Inventory_Balance__c = idBalance,
				AcctSeedERP__Movement_Date__c = adj.GMBLASERP__Adjustment_Date__c,
				AcctSeedERP__Quantity__c = 0,
				AcctSeedERP__Type__c = 'Accounting',
				AcctSeedERP__Unit_Cost__c = 0,
				GMBLASERP__Cost_Override__c = true,
				GMBLASERP__Lot__c = idLot,
				GMBLASERP__Serial_Number__c = idSerial,
				AcctSeedERP__Inbound_Inventory_Movement__c = moveIn.Id,
				AcctSeedERP__Ledger__c = gcConstants.idActualLedger
			);
			insert moveOut;
			System.debug('moveOut');
			System.debug(moveOut);
		}

		return retrieveMoves(moveIn.Id)[0];
	}

	@RemoteAction
	global static string deleteMove(String idMove)
	{
		//return GMBLASERP.gcInventoryAdjustment_Ext.deleteMove(idMove);
		delete [SELECT Id FROM AcctSeedERP__Inbound_Inventory_Movement__c WHERE Id = :idMove];
		return '';
	}
}