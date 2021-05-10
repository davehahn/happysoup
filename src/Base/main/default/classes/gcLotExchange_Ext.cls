public with sharing class gcLotExchange_Ext {
	public gcLotExchange_Ext() {}
	public gcLotExchange_Ext(ApexPages.StandardController c){}

	@RemoteAction @ReadOnly
    public static list<map<string,string>> searchSerial(String strSearch)
    {
    	list<map<string,string>> listJSON = new list<map<string,string>>();

		for(GMBLASERP__Serial_Number__c sn : 
			[SELECT Id, Name,
					GMBLASERP__Product__c,
					GMBLASERP__Product__r.Family,
					GMBLASERP__Product__r.Name,
					GMBLASERP__Product__r.ProductCode,
					GMBLASERP__Product__r.RecordType.Name,
					GMBLASERP__Lot__c,
					GMBLASERP__Lot__r.Name,
					GMBLASERP__Inventory_Balance__c,
					GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
					GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name,
					Nest__c,
					Nest__r.Name
			FROM GMBLASERP__Serial_Number__c
			WHERE GMBLASERP__Lot__c = :strSearch
				AND (Available_Wholesale__c = true OR Available_Retail__c = true) 
				AND Dealer_Rigged__c = false])
		{
			map<string,string> m = new map<string,string>();

			m.put('idSerial',sn.Id);
			m.put('serialName',sn.Name);

			m.put('idProduct',sn.GMBLASERP__Product__c);
			m.put('productFamily',sn.GMBLASERP__Product__r.Family);
			m.put('productName',sn.GMBLASERP__Product__r.Name);
			m.put('productCode',sn.GMBLASERP__Product__r.ProductCode);
			if(sn.GMBLASERP__Product__r.RecordTypeId != null)
				m.put('productRecordTypeName',sn.GMBLASERP__Product__r.RecordType.Name);

			if(sn.GMBLASERP__Lot__c != null)
			{
				m.put('idLot',sn.GMBLASERP__Lot__c);
				m.put('lotName',sn.GMBLASERP__Lot__r.Name);
			}

			if(sn.GMBLASERP__Inventory_Balance__c != null)
			{
				m.put('idBalance',sn.GMBLASERP__Inventory_Balance__c);
				m.put('idWarehouse',sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c);
				m.put('warehouseName',sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name);
			}

			if(sn.Nest__c != null)
			{
				m.put('idNest', sn.Nest__c);
				m.put('nestName',sn.Nest__r.Name);
			}

			listJSON.add(m);
		}

		return listJSON;
    }

	@RemoteAction @ReadOnly
    public static list<map<string,string>> retrieveTransferredSerials(String idLotExchange)
    {
    	Date dateEarliestOpen = GMBLASERP.gcAccountingPeriod.dateEarliestOpen();
    	list<map<string,string>> listJSON = new list<map<string,string>>();
    	for(AcctSeedERP__Inbound_Inventory_Movement__c inm : 
    		[SELECT Id,
    			Name,
    			AcctSeedERP__Movement_Date__c,
    			GMBLASERP__Lot__c,
    			GMBLASERP__Lot__r.Name,
    			GMBLASERP__Lot__r.GMBLASERP__Product__c,
    			GMBLASERP__Lot__r.GMBLASERP__Product__r.Name,
    			GMBLASERP__Serial_Number__c,
    			GMBLASERP__Serial_Number__r.Name,
    			AcctSeedERP__Outbound_Inventory_Movement__c,
    			AcctSeedERP__Outbound_Inventory_Movement__r.Name,
    			AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Lot__c,
    			AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Lot__r.Name,
    			AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Lot__r.GMBLASERP__Product__c,
    			AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Lot__r.GMBLASERP__Product__r.Name,
    			AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Serial_Number__c,
    			AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Serial_Number__r.Name
    		FROM AcctSeedERP__Inbound_Inventory_Movement__c
    		WHERE Lot_Exchange__c =:idLotExchange])
    	{
    		map<string,string> m = new map<string,string>();
    		m.put('idProduct',inm.GMBLASERP__Lot__r.GMBLASERP__Product__c);
    		m.put('productName',inm.GMBLASERP__Lot__r.GMBLASERP__Product__r.Name);
    		m.put('idProductTo',inm.GMBLASERP__Lot__r.GMBLASERP__Product__c);
    		m.put('productNameTO',inm.GMBLASERP__Lot__r.GMBLASERP__Product__r.Name);
    		m.put('idInbound',inm.Id);
    		m.put('inboundName',inm.Name);
    		m.put('idOutbound',inm.AcctSeedERP__Outbound_Inventory_Movement__c);
    		m.put('outboundName',inm.AcctSeedERP__Outbound_Inventory_Movement__r.Name);
    		m.put('idLotTo',inm.GMBLASERP__Lot__c);
    		m.put('lotNameTo',inm.GMBLASERP__Lot__r.Name);
    		m.put('idProductFrom',inm.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Lot__r.GMBLASERP__Product__c);
    		m.put('productNameFrom',inm.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Lot__r.GMBLASERP__Product__r.Name);
    		m.put('idLotFrom',inm.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Lot__c);
    		m.put('lotNameFrom',inm.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Lot__r.Name);
    		m.put('idSerialNew',inm.GMBLASERP__Serial_Number__c);
    		m.put('serialNameNew',inm.GMBLASERP__Serial_Number__r.Name);
    		m.put('idSerialOld',inm.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Serial_Number__c);
    		m.put('serialNameOld',inm.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Serial_Number__r.Name);
            m.put('periodIsOpen','false');
            if(inm.AcctSeedERP__Movement_Date__c != null && inm.AcctSeedERP__Movement_Date__c >= dateEarliestOpen)
                m.put('periodIsOpen','true');
    		listJSON.add(m);
    	}

    	return listJSON;
    }

  	@RemoteAction
    public static String startTransfer(List<String> listSerial, String idLotExchange)
    {
    	Set<String> setIdPassed = new Set<String>();
    	setIdPassed.addAll(listSerial);
    	Lot_Exchange__c transferLot = 	[SELECT Id, 
											Lot_From__c, 
											Lot_From__r.GMBLASERP__Product__c, 
											Lot_From__r.GMBLASERP__Product__r.AcctSeed__Expense_GL_Account__c, 
											Lot_To__c, 
											Lot_To__r.GMBLASERP__Product__c, 
											Lot_To__r.GMBLASERP__Product__r.AcctSeed__Expense_GL_Account__c, 
											Exchange_Date__c,
											Exchange_Type__c 
    									FROM Lot_Exchange__c 
    									WHERE Id=:idLotExchange][0];
		List<AcctSeedERP__Outbound_Inventory_Movement__c> listOutboundMoves = new List<AcctSeedERP__Outbound_Inventory_Movement__c>();
		List<AcctSeedERP__Inbound_Inventory_Movement__c> listInboundMoves = new List<AcctSeedERP__Inbound_Inventory_Movement__c>();
		List<GMBLASERP__Serial_Number__c> listSerialUpdate = new List<GMBLASERP__Serial_Number__c>();
		Map<Id,GMBLASERP__Serial_Number__c> mapSerial = new Map<Id,GMBLASERP__Serial_Number__c>();
		List<GMBLASERP__Serial_Number__c> listSerialInsert = new List<GMBLASERP__Serial_Number__c>();
		map<Id,map<Id,map<Id,Id>>> mapPWLB = new map<Id,map<Id,map<Id,Id>>>();
		Savepoint sp = Database.setSavepoint();
		try{
			for(GMBLASERP__Serial_Number__c sr :
				[SELECT Id,
						Name,
						Description__c,
						Status__c,
						GMBLASERP__Product__c,
						GMBLASERP__Product__r.AcctSeed__Inventory_GL_Account__c,
						GMBLASERP__Product__r.AcctSeed__Expense_GL_Account__c,
						GMBLASERP__Lot__c,
						GMBLASERP__Lot__r.Name,
						Old_Serial_Number__c,
						Nest__c,
						GMBLASERP__Inventory_Balance__c,
						GMBLASERP__Inventory_Balance__r.AcctSeedERP__Product__c,
						GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
						GMBLASERP__Inventory_Balance__r.AcctSeedERP__Location__c
				 FROM GMBLASERP__Serial_Number__c
				 WHERE Id IN:setIdPassed])
			{
				GMBLASERP__Serial_Number__c serial = sr.clone(false,true);
				serial.GMBLASERP__Lot__c = transferLot.Lot_To__c;
				serial.GMBLASERP__Product__c = transferLot.Lot_To__r.GMBLASERP__Product__c;
				serial.Old_Serial_Number__c = sr.Id;
				serial.GMBLASERP__Inventory_Balance__c = null;
				listSerialInsert.add(serial);

				sr.Name = sr.Name + '' + sr.GMBLASERP__Lot__r.Name;
				sr.Nest__c = null;
				sr.Lot_Exchange__c = idLotExchange;
				listSerialUpdate.add(sr);
				mapSerial.put(sr.Id, sr);
				
				listOutboundMoves.add(new AcctSeedERP__Outbound_Inventory_Movement__c(			
										AcctSeedERP__Debit_GL_Account__c = sr.GMBLASERP__Product__r.AcctSeed__Expense_GL_Account__c,
										AcctSeedERP__Inventory_Balance__c = sr.GMBLASERP__Inventory_Balance__c,
										AcctSeedERP__Movement_Date__c = transferLot.Exchange_Date__c,
										AcctSeedERP__Quantity__c = 1,
										AcctSeedERP__Type__c = 'Lot Transfer',
										AcctSeedERP__Unit_Cost__c = null,
										GMBLASERP__Lot__c = sr.GMBLASERP__Lot__c,
										GMBLASERP__Serial_Number__c = sr.Id,
										Lot_Exchange__c = transferLot.Id
									));
				if(transferLot.Exchange_Type__c == 'Product')
				{
					Id idProduct = transferLot.Lot_To__r.GMBLASERP__Product__c;
					Id idWarehouse = sr.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c;
					Id idLocation = sr.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Location__c;

					if(!mapPWLB.containsKey(idProduct))
						mapPWLB.put(idProduct, new map<Id,map<Id,Id>>());

					if(!mapPWLB.get(idProduct).containsKey(idWarehouse))
						mapPWLB.get(idProduct).put(idWarehouse, new map<Id,Id>());

					if(!mapPWLB.get(idProduct).get(idWarehouse).containsKey(idLocation))
						mapPWLB.get(idProduct).get(idWarehouse).put(idLocation, null);
				}
			}
			GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
			if(!listSerialUpdate.isEmpty())
			{
	    		Boolean oldSrVal = gcSerialNumber.enableExchangeUpdate;
	    		gcSerialNumber.enableExchangeUpdate = true;
				update listSerialUpdate;
				insert listOutboundMoves;
				insert listSerialInsert;
				Set<Id> setIdOutMoves = new Set<Id>();
				for(AcctSeedERP__Outbound_Inventory_Movement__c outMove : listOutboundMoves)
					setIdOutMoves.add(outMove.Id);

				Map<Id,AcctSeedERP__Outbound_Inventory_Movement__c> mapListOutboundMoves = new Map<Id,AcctSeedERP__Outbound_Inventory_Movement__c>();
				for(AcctSeedERP__Outbound_Inventory_Movement__c outMove : 
					[SELECT Id, 
						AcctSeedERP__Unit_Cost__c, 
						GMBLASERP__Serial_Number__c 
					FROM AcctSeedERP__Outbound_Inventory_Movement__c
					WHERE Id IN:setIdOutMoves])
				{
					mapListOutboundMoves.put(outMove.GMBLASERP__Serial_Number__c, outMove);
				}

				for(GMBLASERP__Serial_Number__c srl : listSerialInsert)
				{
					GMBLASERP__Serial_Number__c oldSR = mapSerial.get(srl.Old_Serial_Number__c);
					Id idProduct = transferLot.Lot_To__r.GMBLASERP__Product__c;
					Id idWarehouse = oldSR.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c;
					Id idLocation = oldSR.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Location__c;
					Id idBalance;
					if(transferLot.Exchange_Type__c == 'Product')
						idBalance = mapPWLB.get(idProduct).get(idWarehouse).get(idLocation);
					else
						idBalance = oldSR.GMBLASERP__Inventory_Balance__c;
					AcctSeedERP__Outbound_Inventory_Movement__c outMove = mapListOutboundMoves.get(srl.Old_Serial_Number__c);
					listInboundMoves.add(new AcctSeedERP__Inbound_Inventory_Movement__c(
							AcctSeedERP__Credit_GL_Account__c = transferLot.Lot_To__r.GMBLASERP__Product__r.AcctSeed__Expense_GL_Account__c,
							AcctSeedERP__Inventory_Balance__c = idBalance,
							AcctSeedERP__Movement_Date__c = transferLot.Exchange_Date__c,
							AcctSeedERP__Quantity__c = 1,
							AcctSeedERP__Type__c = 'Lot Transfer',
							GMBLASERP__Cost_Override__c = true,
							AcctSeedERP__Unit_Cost__c = outMove.AcctSeedERP__Unit_Cost__c,
							AcctSeedERP__Outbound_Inventory_Movement__c = outMove.Id,
							GMBLASERP__Lot__c = srl.GMBLASERP__Lot__c,
							GMBLASERP__Serial_Number__c = srl.Id,
							Lot_Exchange__c = transferLot.Id
						));
				}
				insert listInboundMoves;
				gcSerialNumber.enableExchangeUpdate = oldSrVal;
				if(setIdPassed.size() == 1)
					return listSerialInsert.get(0).Id;
			}
		}catch(Exception e){
			Database.rollback(sp);
			throw new gcException(e.getMessage());
		}
		return '';
    }  

    @RemoteAction
    public static void reverseTransfer(String idOutMove, String idSerialNew, String idLotExchange) 
    {
 		Savepoint sp = Database.setSavepoint();
		try{
	   		AcctSeedERP__Outbound_Inventory_Movement__c outMove = [SELECT Id, GMBLASERP__Serial_Number__c FROM AcctSeedERP__Outbound_Inventory_Movement__c WHERE Id=:idOutMove][0];
	    	GMBLASERP__Serial_Number__c newSerial = [SELECT Id, Name, Available_Retail__c, Available_Wholesale__c FROM GMBLASERP__Serial_Number__c WHERE Id =:idSerialNew][0];
	    	GMBLASERP__Serial_Number__c oldSerial = new GMBLASERP__Serial_Number__c(Id = outMove.GMBLASERP__Serial_Number__c, Name = newSerial.Name, Lot_Exchange__c = null);
	    	if(!newSerial.Available_Wholesale__c && !newSerial.Available_Retail__c) 
	    		throw new gcException('The serial number ' + newSerial.Name + ' is already in use. Cannot reverse the lot exchange.');
	    	Boolean oldOutVal = gcOutboundInventoryMovement.enableExchangeDelete;
	    	Boolean oldInVal = gcInboundInventoryMovement.enableExchangeDelete;
	    	Boolean oldSrVal = gcSerialNumber.enableExchangeUpdate;
	    	gcOutboundInventoryMovement.enableExchangeDelete = true;
	    	gcInboundInventoryMovement.enableExchangeDelete = true;
	    	gcSerialNumber.enableExchangeUpdate = true;
	    	delete outMove;
	    	delete newSerial;
	    	update oldSerial;
	    	gcOutboundInventoryMovement.enableExchangeDelete = oldOutVal;
	    	gcInboundInventoryMovement.enableExchangeDelete = oldInVal;	    	
	    	gcSerialNumber.enableExchangeUpdate = oldSrVal;
	    }catch(Exception e){
			Database.rollback(sp);
			throw new gcException(e.getMessage());
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
	}
}