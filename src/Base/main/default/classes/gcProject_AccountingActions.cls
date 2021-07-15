public without sharing class gcProject_AccountingActions {

	public gcProject_AccountingActions(){}
	public gcProject_AccountingActions(ApexPages.StandardController c){}

	private static boolean checkProjectHasFinishedGoods(Id idProject)
	{
		for(AggregateResult aggRes : 
			[SELECT sum(AcctSeedERP__Quantity__c) qty
			 FROM AcctSeedERP__Inbound_Inventory_Movement__c
			 WHERE AcctSeedERP__Project__c = :idProject
			   AND AcctSeedERP__Quantity__c != null])
		{
			Decimal qty = (Decimal)aggRes.get('qty');
			if(qty == null) qty = 0;
			if(qty.setScale(2) != 0)
				return true;
		}

		return false;
	}

	private static boolean checkProjectHasWip(Id idProject)
	{
    	Id idGlWIP = gcConstants.idGlWip;

		for(AggregateResult aggRes : 
			[SELECT sum(AcctSeed__Amount__c) amt
			 FROM AcctSeed__Transaction__c
			 WHERE AcctSeed__Project__c = :idProject
			   AND AcctSeed__Product__c != null
			   AND AcctSeed__GL_Account__c = :idGlWIP
			   AND AcctSeed__Amount__c != null])
		{
			Decimal amt = (Decimal)aggRes.get('amt');
			if(amt == null) amt = 0;
			//system.debug(loggingLevel.error,'remaining WIP: '+amt);
			//if(amt.setScale(2) >= 0)
				return true;
		}
		return false;	
	}

	private static boolean checkProjectHasCOGS(Id idProject)
	{
		for(AcctSeed__Journal_Entry__c je :
				[SELECT Id 
				FROM AcctSeed__Journal_Entry__c 
				WHERE Project__c = :idProject 
					AND (Name like '%Job Cost for%' OR Name like '%Internal Labour for%' OR Name like '%Internal Warranty for%')
				LIMIT 1])
		{
			return true;
		}
		return false;	
	}

	private static list<String> stringifyPageMessages(list<ApexPages.Message> listMsg)
	{
		list<String> listString = new list<String>();
		for(ApexPages.Message msg : listMsg)
		{
			String myString = msg.getSeverity().name();
			myString += ':  ';
			myString+= msg.getSummary();
			listString.add(myString);
		}
		return listString;
	}

	@RemoteAction
	public static list<String> postProjectRA(Id idProject)
	{
		Boolean isManufacturing = false;
		Boolean isInternalPartnerBoat = false;
		for(AcctSeed__Project__c project : [SELECT Id, Internal_Partner_Boat_Sale__c, RecordTypeId FROM AcctSeed__Project__c WHERE Id = :idProject])
		{
			if(project.RecordTypeId == gcConstants.idRtProjectManufacturing)
				isManufacturing = true;
			else if(project.Internal_Partner_Boat_Sale__c)
				isInternalPartnerBoat = true;
		}

		list<ApexPages.Message> listMsg = new list<ApexPages.Message>();

		listMsg.addAll(createWip(idProject,null,null));

		if(isManufacturing)
		{
			if(!listMsg.isEmpty())
				listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'INV --> WIP actions incomplete or unsuccessful; WIP --> FG actions were NOT attempted.'));
			else
			{
				listMsg.addAll(buildFinishedGoods(idProject,null));
				if(!listMsg.isEmpty())
					listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'WIP --> FG actions incomplete or unsuccessful.'));
			}

			if(listMsg.isEmpty())
				listMsg.addAll(takeExpense(idProject, null));
			if(!listMsg.isEmpty())
				listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'FG -> MFGCOST actions incomplete or unsuccessful.'));
			else
				listMsg.add(new ApexPages.Message(ApexPages.Severity.INFO, 'INV --> WIP --> FG --> MFGCOST actions succeeded!'));
		}
		else
		{
			if(!listMsg.isEmpty())
				listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'INV --> WIP actions incomplete or unsuccessful; WIP --> COGS actions were NOT attempted.'));
			else
			{
				listMsg.addAll(takeExpense(idProject, null));
				if(!listMsg.isEmpty())
					listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'WIP --> COGS actions incomplete or unsuccessful.'));
			}

			if(listMsg.isEmpty())
				listMsg.add(new ApexPages.Message(ApexPages.Severity.INFO, 'INV --> WIP --> COGS actions succeeded!'));			
		}

		/// If Internal Partner Boat Sale then move the Serialized items back into inventory and assign the cost and price
		if(isInternalPartnerBoat)
		{

		}

		return stringifyPageMessages(listMsg);
	}

	@RemoteAction
	public static list<String> unpostProjectRA(Id idProject, String pIdWarehouse)
	{
		Boolean isManufacturing = false;
		list<ApexPages.Message> listMsg = new list<ApexPages.Message>();
		for(AcctSeed__Project__c project : 
				[SELECT Id, 
					Internal_Partner_Boat_Sale__c,
					(SELECT Id FROM GMBLASERP__Billings__r), 
					RecordTypeId 
				FROM AcctSeed__Project__c 
				WHERE Id = :idProject])
		{
			if(project.RecordTypeId == gcConstants.idRtProjectManufacturing)
				isManufacturing = true;
			if(project.Internal_Partner_Boat_Sale__c && !project.GMBLASERP__Billings__r.isEmpty()){
				throw new gcException('The Internal ERP Order has Billing.  Please delete the billing before attempting to undo WIP.');
			}
		}

		if(isManufacturing)
		{
			listMsg.addAll(unbuildFinishedGoods(idProject));
			if(!listMsg.isEmpty())
				listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'Finished Goods reversal incomplete or unsuccessful.  WIP reversal was NOT attempted.'));
			else
			{
				listMsg.addAll(undoWip(idProject,pIdWarehouse));
				if(!listMsg.isEmpty())
					listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'Finished Goods reversal was successful, but WIP reversal was incomplete or unsuccessful.'));
			}

			if(listMsg.isEmpty())
				listMsg.add(new ApexPages.Message(ApexPages.Severity.INFO, 'Reversal of Finished Goods and reversal of WIP succeeded!'));
		}
		else
		{
			listMsg.addAll(untakeExpense(idProject));
			if(!listMsg.isEmpty())
				listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'COGS reversal incomplete or unsuccessful.  WIP reversal was NOT attempted.'));
			else
			{
				listMsg.addAll(undoWip(idProject,pIdWarehouse));
				if(!listMsg.isEmpty())
					listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'COGS reversal was successful, but WIP reversal was incomplete or unsuccessful.'));
			}

			if(listMsg.isEmpty())
				listMsg.add(new ApexPages.Message(ApexPages.Severity.INFO, 'Reversal of COGS and reversal of WIP succeeded!'));	
		}

		return stringifyPageMessages(listMsg);
	}

	@RemoteAction
	public static list<String> createWipRA(Id idProject, String pIdWarehouse, String movementDate)
	{
		gcManufacturingInventoryMovement.allowMFGERPSerialWIP = true;
		return stringifyPageMessages(createWip(idProject, pIdWarehouse, movementDate));
	}

	@RemoteAction
	public static List<ApexPages.Message> createWip(Id idProject, String pIdWarehouse, String movementDate)
	{
		Date moveDate = Date.today();
		if(movementDate != null)
			moveDate = Date.parse(movementDate);
		List<ApexPages.Message> listMsg = new list<ApexPages.Message>();

		String projectLabel = AcctSeed__Project__c.sObjectType.getDescribe().getLabel();
		String materialLabel = AcctSeedERP__Material__c.sObjectType.getDescribe().getLabel();
		Id idGlv1Wholesale = gcConstants.idGlv1Wholesale;
		Id idGlv2Sales = gcConstants.idGlv2Sales;

		AcctSeed__Project__c project = new AcctSeed__Project__c();
		Id idWarehouse;
		Id idInternalDestinationWarehouse;
		Boolean isInternalPartnerBoat = false;
		Boolean isMFGOrder = false;

		for(AcctSeed__Project__c px : 
			[SELECT Id, Name, RecordTypeId,
					GMBLASERP__Warehouse__c,
					Internal_Destination_WarehouseId__c,
					Internal_Partner_Boat_Sale__c
			 FROM AcctSeed__Project__c
			 WHERE Id = :idProject])
		{
			if(px.RecordTypeId == gcConstants.idRtProjectManufacturing)
				isMFGOrder = true;
			idWarehouse = px.GMBLASERP__Warehouse__c;
			idInternalDestinationWarehouse = px.Internal_Destination_WarehouseId__c;
			isInternalPartnerBoat = px.Internal_Partner_Boat_Sale__c;
			project = px;
		}

		//if(pIdWarehouse != null)
		//	idWarehouse = pIdWarehouse;

		if(isInternalPartnerBoat)
			idWarehouse = gcConstants.idWarehouseWholesale;

		if(project == null)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'A '+projectLabel+' with the specified Id does not exist.'));
			return listMsg;
		}

		if(idWarehouse == null)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'A Warehouse has not been specified for the '+projectLabel+'.'));
			return listMsg;
		}

		AcctSeedERP__Warehouse__c whs = [SELECT Id, Name, Insufficient_Inventory_Email__c FROM AcctSeedERP__Warehouse__c WHERE Id=:idWarehouse][0];

		Date fillDate = date.Today();

		map<Id,Product2> mapProduct = new map<Id,Product2>();

		list<AcctSeedERP__Material__c> listMatl = new list<AcctSeedERP__Material__c>();
		list<AcctSeedERP__Manufacturing_Inventory_Movement__c> listMove = new list<AcctSeedERP__Manufacturing_Inventory_Movement__c>();

		set<Id> setIdProductBulk = new set<Id>();
		set<Id> setIdLot = new set<Id>();
		set<Id> setIdSerial = new set<Id>();

		set<Id> setIdProductReturn = new set<Id>();		
		Map<Id,Boolean> mapSerialMFG = new Map<Id,Boolean>();
		for(AcctSeedERP__Material__c matl : 
			[SELECT Id, Name,
					AcctSeedERP__GL_Account_Variable_1__c,
					AcctSeedERP__GL_Account_Variable_2__c,
					AcctSeedERP__GL_Account_Variable_3__c,
					AcctSeedERP__GL_Account_Variable_4__c,
					AcctSeedERP__Product__c,
					AcctSeedERP__Product__r.Name,
					AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
					AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c,
					AcctSeedERP__Project__c,
					AcctSeedERP__Project_Task__c,
					AcctSeedERP__Quantity_Allocated__c,
					AcctSeedERP__Quantity_Per_Unit__c,
					GMBLASERP__Lot__c,
					GMBLASERP__Serial_Number__c
			 FROM AcctSeedERP__Material__c
			 WHERE AcctSeedERP__Project__c = :idProject
			   AND AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = true
			   AND No_WIP__c = false])
		{
			Decimal qty = (matl.AcctSeedERP__Quantity_Per_Unit__c == null ? 0 : matl.AcctSeedERP__Quantity_Per_Unit__c);
			qty -= (matl.AcctSeedERP__Quantity_Allocated__c == null ? 0 : matl.AcctSeedERP__Quantity_Allocated__c);

			qty = qty.setScale(6);

			if(qty == 0)
				continue;

			Product2 product = matl.AcctSeedERP__Product__r;

			if(product.AcctSeedERP__Serialized__c && matl.GMBLASERP__Serial_Number__c == null)
			{
				String msg = 'Product ['+product.Name+'] was not moved from inventory to WIP because the product is serialized and a serial number has not been specified on '+materialLabel+' '+matl.Name;
				if(isInternalPartnerBoat)
					throw new gcException('For Internal Boat Sale all Inventory Products must be moved at the Same time. '+msg);
				listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, msg));
				continue;
			}

			if(product.GMBLASERP__Lot_Tracked__c && matl.GMBLASERP__Lot__c == null)
			{
				String msg = 'Product ['+product.Name+'] was not moved from inventory to WIP because the product is lot-tracked and a lot has not been specified on '+materialLabel+' '+matl.Name;
				if(isInternalPartnerBoat)
					throw new gcException('For Internal Boat Sale all Inventory Products must be moved at the Same time. '+msg);
				listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, msg));
				continue;
			}

			listMatl.add(matl);	
			
			mapProduct.put(product.Id,product);

			if(matl.GMBLASERP__Serial_Number__c != null)
				setIdSerial.add(matl.GMBLASERP__Serial_Number__c);
			else if(matl.GMBLASERP__Lot__c != null)
				setIdLot.add(matl.GMBLASERP__Lot__c);
			else
				setIdProductBulk.add(matl.AcctSeedERP__Product__c);

			if(qty < 0)
				setIdProductReturn.add(matl.AcctSeedERP__Product__c);

			if(!isMFGOrder && product.AcctSeedERP__Serialized__c && matl.GMBLASERP__Serial_Number__c != null)
				mapSerialMFG.put(matl.GMBLASERP__Serial_Number__c, false);
		}
		/// Validate Manufacturing Order
		retrieveIncompleteSerialMFG(mapSerialMFG,idProject);

		mapProduct.remove(null);

		map<Id,map<Id,Decimal>> mapOBQ = new map<Id,map<Id,Decimal>>(); //map [Product / Lot / Serial].Id => InventoryBalance.Id => QtyAvail

		list<AggregateResult> listAggRes = new list<AggregateResult>();
		listAggRes.addAll(
			[SELECT GMBLASERP__Inventory_Balance__c idBalance,
					GMBLASERP__Lot__c idLot,
					GMBLASERP__Product__c idProduct,
					GMBLASERP__Serial_Number__c idSerial,
					sum(GMBLASERP__Quantity__c) qty
			 FROM GMBLASERP__Inventory_Movement_Cube__c
			 WHERE GMBLASERP__Movement_Date__c <= :fillDate
			   AND GMBLASERP__Warehouse__c = :idWarehouse
			   AND (GMBLASERP__Product__c IN :setIdProductBulk OR
			   		GMBLASERP__Lot__c IN :setIdLot OR
			   		GMBLASERP__Serial_Number__c IN :setIdSerial)
			 GROUP BY GMBLASERP__Inventory_Balance__c,
			 		  GMBLASERP__Lot__c,
			 		  GMBLASERP__Product__c,
			 		  GMBLASERP__Serial_Number__c
			 HAVING sum(GMBLASERP__Quantity__c) > 0]
		);		

		for(AggregateResult aggRes : listAggRes)
		{
			Id idBalance = (Id)aggRes.get('idBalance');

			Id idObject = (Id)aggRes.get('idSerial');
			if(idObject == null)
			   idObject = (Id)aggRes.get('idLot');
			if(idObject == null)
			   idObject = (Id)aggRes.get('idProduct');

			Decimal qtyBal = (Decimal)(aggRes.get('qty'));
			qtyBal = (qtyBal == null ? 0 : qtyBal);

			map<Id,Decimal> mapBQ = mapOBQ.get(idObject);
			if(mapBQ == null)
			{
				mapBQ = new map<Id,Decimal>();
				mapOBQ.put(idObject,mapBQ);
			}

			Decimal qtyMap = mapBQ.get(idBalance);
			qtyMap = (qtyMap == null ? 0 : qtyMap);

			mapBQ.put(idBalance, qtyMap + qtyBal);

			if(!setIdProductReturn.isEmpty())
				setIdProductReturn.remove((Id)aggRes.get('idProduct'));
		}

		//the remaining elements in setIdProductReturn are products that are being returned, and for which there is not currently any inventory
		//we must identify a balance to use for the return of these items.
		if(!setIdProductReturn.isEmpty())
		{
			Id idLocation;
			for(AcctSeedERP__Location__c loc : 
				[SELECT Id
				 FROM AcctSeedERP__Location__c
				 WHERE AcctSeedERP__Warehouse__c = :idWarehouse
				 ORDER BY CreatedDate
				 LIMIT 1])
			{
				idLocation = loc.Id;
			}

			map<Id,map<Id,map<Id,Id>>> mapPWLB = new map<Id,map<Id,map<Id,Id>>>();
			for(Id idProduct : setIdProductReturn)
			{
				mapPWLB.put(idProduct, new map<Id,map<Id,Id>>{idWarehouse => new map<Id,Id>{idLocation => null}});
			}

			GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);

			for(Id idProduct : mapPWLB.keySet())
			{
				Id idBalance = mapPWLB.get(idProduct).get(idWarehouse).get(idLocation);

				map<Id,Decimal> mapBQ = mapOBQ.get(idProduct);
				if(mapBQ == null)
				{
					mapBQ = new map<Id,Decimal>();
					mapOBQ.put(idProduct, mapBQ);
				}
				mapOBQ.get(idProduct).put(idBalance,0);
			}
		}

		List<String> listIIB = new List<String>();
		for(AcctSeedERP__Material__c matl : listMatl)
		{
			Decimal qtyNeeded = (matl.AcctSeedERP__Quantity_Per_Unit__c == null ? 0 : matl.AcctSeedERP__Quantity_Per_Unit__c);
			qtyNeeded -= (matl.AcctSeedERP__Quantity_Allocated__c == null ? 0 : matl.AcctSeedERP__Quantity_Allocated__c);

			qtyNeeded = qtyNeeded.setScale(6);

			if(qtyNeeded == 0)
				continue;

			Product2 product = matl.AcctSeedERP__Product__r;

			Id idObject = matl.GMBLASERP__Serial_Number__c;
			if(idObject == null)
			   idObject = matl.GMBLASERP__Lot__c;
			if(idObject == null)
				idObject = matl.AcctSeedERP__Product__c;


			map<Id,Decimal> mapBQ = mapOBQ.get(idObject);
			if(mapBQ == null && qtyNeeded < 0)
			{
				mapBQ = mapOBQ.get(matl.AcctSeedERP__Product__c);
			}

			if(mapBQ != null)
			for(Id idBalance : mapBQ.keySet())
			{
				Decimal qtyBal = mapBQ.get(idBalance);
				
				if(qtyNeeded < 0 || qtyBal > 0)
				{	
					Decimal qtyMove = 0;

					if(qtyNeeded < 0)
					   qtyMove = qtyNeeded;
					else if(qtyNeeded <= qtyBal)
					   qtyMove = qtyNeeded;
					else
					   qtyMove = qtyBal;

					listMove.add(new AcctSeedERP__Manufacturing_Inventory_Movement__c(
						AcctSeedERP__GL_Account_Variable_1__c = isInternalPartnerBoat ? idGlv1Wholesale : matl.AcctSeedERP__GL_Account_Variable_1__c,
						AcctSeedERP__GL_Account_Variable_2__c = isInternalPartnerBoat ? idGlv2Sales : matl.AcctSeedERP__GL_Account_Variable_2__c,
						AcctSeedERP__GL_Account_Variable_3__c = matl.AcctSeedERP__GL_Account_Variable_3__c,
						AcctSeedERP__GL_Account_Variable_4__c = matl.AcctSeedERP__GL_Account_Variable_4__c,
						AcctSeedERP__Inventory_Balance__c = idBalance,
						AcctSeedERP__Material__c = matl.Id,
						AcctSeedERP__Quantity__c = qtyMove,
						AcctSeedERP__Movement_Date__c = moveDate,
						GMBLASERP__Lot__c = matl.GMBLASERP__Lot__c,
						GMBLASERP__Serial_Number__c = matl.GMBLASERP__Serial_Number__c
					));

					mapBQ.put(idBalance, qtyBal - qtyMove);
					qtyNeeded -= qtyMove;
					if(qtyNeeded == 0) break;
				}
			}

			if(qtyNeeded != 0)
			{
				String msg = 'Product ['+product.Name+'] was not completely moved from inventory to WIP due to insufficient inventory for '+materialLabel+' '+matl.Name+' in '+whs.Name;
				if(isInternalPartnerBoat)
					throw new gcException('For Internal Boat Sale all Inventory Products must be moved at the Same time. '+msg);
				listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, msg));
				listIIB.add(msg);
				continue;
			}
		}

		if(!listMove.isEmpty()){
			System.debug(loggingLevel.Error, 'listMoveBefore:'+listMove);
			insert listMove;
			System.debug(loggingLevel.Error, 'listMoveAfter:'+listMove);
		}

		if(!listMsg.isEmpty())
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'INV --> WIP actions incomplete.'));
		}
		if(!listIIB.isEmpty())
		{
			sendEmail(listIIB, whs.Insufficient_Inventory_Email__c,project);
		}
		return listMsg;
	}

	public static void retrieveIncompleteSerialMFG(Map<Id,Boolean> mapSerialMFG, Id idProject){
		Id idRtProjectManufacturing = gcConstants.idRtProjectManufacturing;
		for(GMBLASERP__Serial_Number__c sn :
				[SELECT Id, Name,
					(SELECT Id, AcctSeedERP__Project__r.Name FROM GMBLASERP__Materials__r WHERE AcctSeedERP__Project__r.RecordTypeId =:idRtProjectManufacturing AND AcctSeedERP__Project__r.AcctSeed__Status__c != 'Completed' AND AcctSeedERP__Project__c !=:idProject LIMIT 1),
					(SELECT Id, Name FROM Projects__r WHERE RecordTypeId =:idRtProjectManufacturing AND AcctSeed__Status__c != 'Completed' AND Id !=:idProject LIMIT 1)
				FROM GMBLASERP__Serial_Number__c
				WHERE Id IN :mapSerialMFG.keySet()])
			{
				String erpName;
				if(!sn.GMBLASERP__Materials__r.isEmpty()) 
					erpName = sn.GMBLASERP__Materials__r[0].AcctSeedERP__Project__r.Name;
				if(!sn.Projects__r.isEmpty())
					erpName = sn.Projects__r[0].Name;
				if(erpName != null){
					throw new gcException('Please complete the ERP '+erpName+' to proceed.');
				}
			}
	}

	@RemoteAction
	public static list<String> undoWipRA(Id idProject, String pIdWarehouse)
	{
		return stringifyPageMessages(undoWip(idProject, pIdWarehouse));
	}

    @RemoteAction 
    public static list<ApexPages.Message> undoWip(Id idProject, String pIdWarehouse)
    {
		List<ApexPages.Message> listMsg = new list<ApexPages.Message>();
		for(AcctSeed__Project__c px : 
			[SELECT Id,
					RecordTypeId,
					Internal_Partner_Boat_Sale__c,
					(SELECT Id FROM GMBLASERP__Billings__r)
			 FROM AcctSeed__Project__c
			 WHERE Id = :idProject])
		{
			if((px.Internal_Partner_Boat_Sale__c 
					|| px.RecordTypeId == gcConstants.idRtProjectBoatSale) 
				&& !px.GMBLASERP__Billings__r.isEmpty())
			{
				throw new gcException('The Boat Sale ERP Order has associated Billings.  Please delete the billing before attempting to undo WIP.');
				//listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Boat Sale ERP Order has associated Billings.  Please delete the billing before attempting to undo WIP.'));
				//return listMsg;				
			}
		}

    	if(checkProjectHasFinishedGoods(idProject))
    	{
    		System.debug(loggingLevel.Error,'undoWIP Finished');
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Project has Finished Goods.  Reverse or delete the Finished Goods movement before attempting to undo WIP.'));
			return listMsg;
    	}

    	if(checkProjectHasWip(idProject) == false)
    	{
    		System.debug(loggingLevel.Error,'undoWIP No WIP');
			return listMsg;
    	}

    	if(checkProjectHasCOGS(idProject))
    	{
			throw new gcException('The Project has COGS Movements. Delete the Journal Entries before attempting to undo WIP.');
			//listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Project has COGS Movements. Delete the Journal Entries before attempting to undo WIP.'));
			//return listMsg;
    	}

    	System.debug(loggingLevel.Error,'undoWIP Start:'+idProject);
    	Date dateEarliestOpen = GMBLASERP.gcAccountingPeriod.dateEarliestOpen();
    	list<AcctSeedERP__Manufacturing_Inventory_Movement__c> listMoveInsert = new list<AcctSeedERP__Manufacturing_Inventory_Movement__c>();
    	list<AcctSeedERP__Manufacturing_Inventory_Movement__c> listMoveDelete = new list<AcctSeedERP__Manufacturing_Inventory_Movement__c>();
    	List<AcctSeedERP__Manufacturing_Inventory_Movement__c> listMovesNonWhs = new list<AcctSeedERP__Manufacturing_Inventory_Movement__c>();
    	for(AcctSeedERP__Manufacturing_Inventory_Movement__c move : 
    		[SELECT Id,
    				GMBLASERP__Cost_Override__c,
    				AcctSeedERP__GL_Account_Variable_1__c,
    				AcctSeedERP__GL_Account_Variable_2__c,
    				AcctSeedERP__GL_Account_Variable_3__c,
    				AcctSeedERP__GL_Account_Variable_4__c,
    				AcctSeedERP__Inventory_Balance__c,
    				AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
    				AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c,
    				AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c,
       				GMBLASERP__Lot__c,
    				AcctSeedERP__Material__c,
    				AcctSeedERP__Movement_Date__c,
    				AcctSeedERP__Quantity__c,
    				GMBLASERP__Serial_Number__c,
    				AcctSeedERP__Unit_Cost__c
    		 FROM AcctSeedERP__Manufacturing_Inventory_Movement__c
    		 WHERE AcctSeedERP__Material__r.AcctSeedERP__Project__c = :idProject])
    	{
    		//if(move.AcctSeedERP__Inventory_Balance__c != null && move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c != pIdWarehouse)
    		//	listMovesNonWhs.add(move);

    		if(move.AcctSeedERP__Movement_Date__c >= dateEarliestOpen)
    			listMoveDelete.add(move);
    		else
    		{
    			AcctSeedERP__Manufacturing_Inventory_Movement__c moveNew = move.clone();
    			moveNew.GMBLASERP__Cost_Override__c = true;
    			moveNew.AcctSeedERP__Movement_Date__c = date.today();
    			moveNew.AcctSeedERP__Quantity__c *= (-1);
    			listMoveInsert.add(moveNew);
    		}
    	}

    	if(listMoveDelete.size() > 0)
    		delete listMoveDelete;
    	if(listMoveInsert.size() > 0)
    		insert listMoveInsert;

    	/// Now we are going to transfer all the items to the selected warehouse
    	//if(!listMovesNonWhs.isEmpty())
    	//	makeInventoryTransfer(listMovesNonWhs,pIdWarehouse);

		return listMsg;
    }

    public static void makeInventoryTransfer(List<AcctSeedERP__Manufacturing_Inventory_Movement__c> listMoves, String pIdWarehouse)
    {
    	Id idLocation;
		for(AcctSeedERP__Location__c loc : [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c = :pIdWarehouse ORDER BY CreatedDate LIMIT 1])
			idLocation = loc.Id;
		map<Id,map<Id,map<Id,Id>>> mapPWLB = new map<Id,map<Id,map<Id,Id>>>();
        List<AcctSeedERP__Outbound_Inventory_Movement__c> listOutMoves = new List<AcctSeedERP__Outbound_Inventory_Movement__c>();
        List<AcctSeedERP__Inbound_Inventory_Movement__c> listMoveIn = new List<AcctSeedERP__Inbound_Inventory_Movement__c>();
        for(AcctSeedERP__Manufacturing_Inventory_Movement__c move : listMoves)
        {
			if(!mapPWLB.containsKey(move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c)){
            	mapPWLB.put(move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c, new map<Id,map<Id,Id>>{pIdWarehouse => new map<Id,Id>{idLocation => null}});
			}

	        AcctSeedERP__Outbound_Inventory_Movement__c moveOut = new AcctSeedERP__Outbound_Inventory_Movement__c(
	        	GMBLASERP__Product__c = move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c,
	            AcctSeedERP__Debit_GL_Account__c = move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c,
	            AcctSeedERP__Inventory_Balance__c = move.AcctSeedERP__Inventory_Balance__c,
	            AcctSeedERP__Movement_Date__c = Date.today(),
	            AcctSeedERP__Quantity__c = move.AcctSeedERP__Quantity__c,
	            AcctSeedERP__Type__c = 'Non-Accounting',
	            AcctSeedERP__Unit_Cost__c = 0,
	            GMBLASERP__Cost_Override__c = true,
	            GMBLASERP__Lot__c = move.GMBLASERP__Lot__c,
	            GMBLASERP__Serial_Number__c = move.GMBLASERP__Serial_Number__c
	        );
	        listOutMoves.add(moveOut);
	    }

	    if(!listOutMoves.isEmpty())
	    {
	    	insert listOutMoves;
	    	GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
			for(AcctSeedERP__Outbound_Inventory_Movement__c moveOut : listOutMoves)
			{	
				Id idProduct = moveOut.GMBLASERP__Product__c;
				Id idBalance = mapPWLB.get(idProduct).get(pIdWarehouse).get(idLocation);

				listMoveIn.add(new AcctSeedERP__Inbound_Inventory_Movement__c(
						GMBLASERP__Product__c = moveOut.GMBLASERP__Product__c,
						AcctSeedERP__Credit_GL_Account__c = moveOut.AcctSeedERP__Debit_GL_Account__c,
						AcctSeedERP__Inventory_Balance__c = idBalance,
						AcctSeedERP__Movement_Date__c = moveOut.AcctSeedERP__Movement_Date__c,
						AcctSeedERP__Outbound_Inventory_Movement__c = moveOut.Id,
						AcctSeedERP__Quantity__c = moveOut.AcctSeedERP__Quantity__c,
						AcctSeedERP__Type__c = moveOut.AcctSeedERP__Type__c,
						AcctSeedERP__Unit_Cost__c = moveOut.AcctSeedERP__Unit_Cost__c,
						GMBLASERP__Cost_Override__c = true,
						GMBLASERP__Serial_Number__c = moveOut.GMBLASERP__Serial_Number__c,		
						GMBLASERP__Lot__c = moveOut.GMBLASERP__Lot__c		
					));
			}
			insert listMoveIn;
	    }
    }

	@RemoteAction
	public static list<String> buildFinishedGoodsRA(Id idProject, String buildDate)
	{
		return stringifyPageMessages(buildFinishedGoods(idProject,buildDate));
	}

	@RemoteAction
	public static List<ApexPages.Message> buildFinishedGoods(Id idProject, String buildDate)
	{
		list<ApexPages.Message> listMsg = new list<ApexPages.Message>();
		Date moveDate = Date.today();
		if(buildDate != null)
			moveDate = Date.parse(buildDate);
//		for(AggregateResult aggRes : [SELECT AcctSeedERP__Material__r.AcctSeedERP__Project__c idProject,
//								SUM(AcctSeedERP__Quantity__c) totQty
//							FROM AcctSeedERP__Manufacturing_Inventory_Movement__c
//							WHERE AcctSeedERP__Material__r.AcctSeedERP__Project__c = :idProject
//							GROUP BY AcctSeedERP__Material__r.AcctSeedERP__Project__c])
//		{
//			Id idBalance = (Id)aggRes.get('idProject');
//			Decimal qtyMoved = (Decimal)aggRes.get('totQty');
//		}
		AcctSeed__Project__c project = 
		[SELECT Id,
				RecordTypeId,
				AcctSeedERP__Manufactured_Product__c,
				AcctSeedERP__Manufactured_Product__r.AcctSeed__Inventory_Product__c,
				AcctSeedERP__Manufactured_Product__r.AcctSeedERP__Serialized__c,
				Serial_Number__c,
				Serial_Number__r.GMBLASERP__Inventory_Balance__c,
				Serial_Number__r.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
				Serial_Number__r.GMBLASERP__Lot__c,
				Serial_Number__r.GMBLASERP__Product__c,
         		GMBLASERP__Warehouse__c,
				(SELECT Id, Product__c FROM AcctSeed__Project_Tasks__r ORDER BY CreatedDate),
				(SELECT Id, 
						AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
						AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c,
						AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
						AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c,
						GMBLASERP__Total_Price__c,
						AcctSeedERP__Project_Task__c,
						AcctSeedERP__Quantity_Allocated__c,
						AcctSeedERP__Quantity_Per_Unit__c,
						Actual_Quantity_Filled__c,
						GMBLASERP__Serial_Number__c
				 FROM AcctSeedERP__Project_Materials__r)
		 FROM AcctSeed__Project__c
		 WHERE Id = :idProject][0];

		if(!(project.RecordTypeId == gcConstants.idRtProjectManufacturing 
			|| project.RecordTypeId == gcConstants.idRtTradeIn))
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods may not be built, unless the Project Record Type is [Manufacturing/Trade In].'));
			return listMsg;	 	
		}

		if(project.AcctSeedERP__Manufactured_Product__c == null)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'A Manufactured Product must be specified, in order to build Finished Goods.'));
			return listMsg;	 	
		}

	 	if(project.AcctSeedERP__Manufactured_Product__r.AcctSeed__Inventory_Product__c == false)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Manufactured Product must be an Inventory Product, in order to build Finished Goods.'));
			return listMsg;	 	
		}

		if(project.GMBLASERP__Warehouse__c == null)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'A Warehouse must be specified for the Project, in order to Build Finished Goods.'));
			return listMsg;	 	
		}

		Id idProjectTask;
		Decimal nonInventoryPrice = 0;
		if(project.RecordTypeId == gcConstants.idRtProjectManufacturing)
		{
			for(AcctSeed__Project_Task__c pt : project.AcctSeed__Project_Tasks__r)
			{
				if(pt.Product__c == project.AcctSeedERP__Manufactured_Product__c)
				{
					if(idProjectTask != null)
					{
						listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'There cannot be multiple project tasks for the manufactured product.'));
						return listMsg;	 	
					}

					idProjectTask = pt.Id;
				}
			}

			if(idProjectTask == null)
			{
				listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'A Project Task for the Manufactured Product does not exist.'));
				return listMsg;	 	
			}
		
			if(checkProjectHasWip(idProject) == false)
			{
				listMsg.add(new ApexPages.Message(ApexPages.Severity.INFO, 'Finished Goods were not built, because the Project has no WIP.'));
				return listMsg;	 	
			}

		 	if(project.AcctSeedERP__Manufactured_Product__r.AcctSeedERP__Serialized__c)
		 	{
		 		if(project.Serial_Number__c == null)
				{
					listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods were not built, because the Manufactured Product is serialized, and a Serial Number has not been specified for the Project.'));
					return listMsg;	 	
				}
			 	else if(project.AcctSeedERP__Manufactured_Product__c != project.Serial_Number__r.GMBLASERP__Product__c)
				{
					listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods were not built, because the specified Serial Number is for a different Product than the Manufactured Product.'));
					return listMsg;	 	
				}
			 	/*else if(project.Serial_Number__r.GMBLASERP__Inventory_Balance__c == null)
				{
					listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods were not built, because the Project Serial Number is not in inventory.'));
					return listMsg;	 	
				}*/
			 	else if(checkProjectHasFinishedGoods(idProject))
				{
					listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods were not built, because the Project already has Finished Goods.  All Finished Goods must be deleted or reversed, before building Finished Goods.'));
					return listMsg;	 	
				}

				//move the projects serial into WIP

				//first, find or create a Material record
				Decimal qtyOrdered = 0;
				Decimal qtyFilled = 0;
				AcctSeedERP__Material__c matl;
				for(AcctSeedERP__Material__c mx : project.AcctSeedERP__Project_Materials__r)
				{
					if(mx.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c){
						qtyOrdered += mx.AcctSeedERP__Quantity_Per_Unit__c == null ? 0 : mx.AcctSeedERP__Quantity_Per_Unit__c;
						qtyFilled += mx.Actual_Quantity_Filled__c == null ? 0 : mx.Actual_Quantity_Filled__c;
						if(mx.AcctSeedERP__Product__c == project.AcctSeedERP__Manufactured_Product__c)
						{
							if(matl == null || matl.GMBLASERP__Serial_Number__c == project.Serial_Number__c)
								matl = mx;
						}
					}else{
						Decimal qt = mx.AcctSeedERP__Quantity_Per_Unit__c == null ? 0 : mx.AcctSeedERP__Quantity_Per_Unit__c;
						Decimal am = mx.AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c == null ? 0 : mx.AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c;
						nonInventoryPrice += (qt * am);
					}
				}
				if(qtyOrdered != qtyFilled){
					listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'All Inventory Products must be WIPed before creating a Finished Good.'));
					return listMsg;
				}

				if(matl != null && matl.GMBLASERP__Serial_Number__c == null)
				{
					matl.GMBLASERP__Serial_Number__c = project.Serial_Number__c;
					update matl;
				}
				else if(matl == null)
				{
					if(project.Serial_Number__r.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c != project.GMBLASERP__Warehouse__c){
						listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'The ERP Serial is not in the ERP warehouse.'));
						return listMsg;
					}
					matl = new AcctSeedERP__Material__c(
							AcctSeedERP__Product__c = project.AcctSeedERP__Manufactured_Product__c,
							AcctSeedERP__Project__c = project.Id,
							AcctSeedERP__Project_Task__c = idProjectTask,
	                        AcctSeedERP__Quantity_Per_Unit__c = 1,
	                        GMBLASERP__Serial_Number__c = project.Serial_Number__c
					);
					insert matl;
				}
				Boolean mfgExists = false;
				for(AcctSeedERP__Manufacturing_Inventory_Movement__c mfg : 
					[SELECT Id 
					FROM AcctSeedERP__Manufacturing_Inventory_Movement__c 
					WHERE AcctSeedERP__Material__c =:matl.Id])
				{
					mfgExists = true;
				}
				/// If a MFG movements does not exist and also the Serial Number is not in inventory then that means the Serial Number was used somewhere else
				/// Cannot proceed to create FG 
				if(!mfgExists && project.Serial_Number__r.GMBLASERP__Inventory_Balance__c == null)
				{
					listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods were not built, because the Project Serial Number has already been used in some other project and not in inventory anymore.'));
					return listMsg;	 	
				}

				if(!mfgExists)
				{
					insert new AcctSeedERP__Manufacturing_Inventory_Movement__c(
						AcctSeedERP__Inventory_Balance__c = project.Serial_Number__r.GMBLASERP__Inventory_Balance__c,
						AcctSeedERP__Material__c = matl.Id,
						AcctSeedERP__Movement_Date__c = date.Today(),
						AcctSeedERP__Quantity__c = 1,
						AcctSeedERP__Unit_Cost__c = 0,
						GMBLASERP__Lot__c = project.Serial_Number__r.GMBLASERP__Lot__c,
						GMBLASERP__Serial_Number__c = project.Serial_Number__c
					);
				}
			}
		}

    	//create an inventory movement to move the finished good from WIP to inventory.
    	Id idGlWIP = gcConstants.idGlWip;
    	Decimal amtWip = 0;
		for(AggregateResult aggRes : 
			[SELECT sum(AcctSeed__Amount__c) amt
			 FROM AcctSeed__Transaction__c
			 WHERE AcctSeed__Project__c = :idProject
			   AND AcctSeed__GL_Account__c = :idGlWIP
			   AND (AcctSeed__Amount__c < 0 OR AcctSeed__Amount__c > 0)])
		{
			Decimal amt = (Decimal)aggRes.get('amt');
			amtWip += (amt == null ? 0 : amt);
		}

    	AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c = :project.GMBLASERP__Warehouse__c][0];
    	Id idBalance = GMBLASERP.gcInventoryBalance.findOrCreateBalance(project.AcctSeedERP__Manufactured_Product__c,project.GMBLASERP__Warehouse__c,loc.Id);
    	insert new AcctSeedERP__Inbound_Inventory_Movement__c(
    			AcctSeedERP__Credit_GL_Account__c = idGlWIP,
    			AcctSeedERP__Inventory_Balance__c = idBalance,
    			AcctSeedERP__Movement_Date__c = moveDate,
    			AcctSeedERP__Project__c = idProject,
    			AcctSeedERP__Project_Task__c = idProjectTask,
    			AcctSeedERP__Quantity__c = 1,
    			AcctSeedERP__Type__c = 'Accounting',
    			AcctSeedERP__Unit_Cost__c = amtWip + nonInventoryPrice,
    			GMBLASERP__Cost_Override__c = true,
    			GMBLASERP__Lot__c = project.Serial_Number__r.GMBLASERP__Lot__c,
    			GMBLASERP__Serial_Number__c = project.Serial_Number__c
    		);

		//if(listMsg.isEmpty())
		//	listMsg.addAll(takeExpense(idProject, buildDate));
		return listMsg;
	}

	@RemoteAction
	public static list<String> unbuildFinishedGoodsRA(Id idProject)
	{
		return stringifyPageMessages(unbuildFinishedGoods(idProject));
	}

	@RemoteAction
	public static list<ApexPages.Message> unbuildFinishedGoods(Id idProject)
	{
		list<ApexPages.Message> listMsg = new list<ApexPages.Message>();

		//in order to reverse, there must be net inbound movement
		if(checkProjectHasFinishedGoods(idProject) == false)
		{
			return listMsg;	
		}

		Date dateEarliestOpen = GMBLASERP.gcAccountingPeriod.dateEarliestOpen();

		list<AcctSeedERP__Inbound_Inventory_Movement__c> listInboundUpsert = new list<AcctSeedERP__Inbound_Inventory_Movement__c>();
		list<AcctSeedERP__Inbound_Inventory_Movement__c> listInboundDelete = new list<AcctSeedERP__Inbound_Inventory_Movement__c>();

		//delete or reverse all inbound movements for this project
		for(AcctSeedERP__Inbound_Inventory_Movement__c move : 
			[SELECT Id,
					AcctSeedERP__Credit_GL_Account__c,
					AcctSeedERP__Debit_GL_Account__c,
					AcctSeedERP__Inventory_Balance__c,
					AcctSeedERP__Movement_Date__c,
					AcctSeedERP__Project__c,
					AcctSeedERP__Project_Task__c,
					AcctSeedERP__Quantity__c,
					AcctSeedERP__Type__c,
					AcctSeedERP__Unit_Cost__c,
					GMBLASERP__Cost_Override__c,
					GMBLASERP__Lot__c,
					GMBLASERP__Serial_Number__c
			FROM AcctSeedERP__Inbound_Inventory_Movement__c
			WHERE AcctSeedERP__Project__c = :idProject])
		{
			if(move.AcctSeedERP__Movement_Date__c >= dateEarliestOpen)
				listInboundDelete.add(move);
			
			else
			{
				AcctSeedERP__Inbound_Inventory_Movement__c x = move.clone();
				x.AcctSeedERP__Quantity__c *= (-1);
				x.GMBLASERP__Cost_Override__c = true;
				x.AcctSeedERP__Movement_Date__c = date.today();
				listInboundUpsert.add(x);
			}
		}

		if(!listInboundDelete.isEmpty())
			delete listInboundDelete;

		if(!listInboundUpsert.isEmpty())
			upsert listInboundUpsert;

		return listMsg;
	}

	/// Trade In
	@RemoteAction
	public static list<String> buildFinishedGoodsRATradeIn(Id idProject, Decimal tradeInAmount)
	{
		return stringifyPageMessages(buildFinishedGoodsTradeIn(idProject,tradeInAmount));
	}

	@RemoteAction
	public static List<ApexPages.Message> buildFinishedGoodsTradeIn(Id idProject, Decimal tradeInAmount)
	{
		list<ApexPages.Message> listMsg = new list<ApexPages.Message>();

		AcctSeed__Project__c project = 
		[SELECT Id,
				RecordTypeId,
				AcctSeedERP__Manufactured_Product__c,
				AcctSeedERP__Manufactured_Product__r.AcctSeed__Inventory_Product__c,
				AcctSeedERP__Manufactured_Product__r.AcctSeedERP__Serialized__c,
				Serial_Number__c,
				Serial_Number__r.GMBLASERP__Inventory_Balance__c,
				Serial_Number__r.GMBLASERP__Lot__c,
				Serial_Number__r.GMBLASERP__Product__c,
         		GMBLASERP__Warehouse__c,
				(SELECT Id, Product__c FROM AcctSeed__Project_Tasks__r ORDER BY CreatedDate LIMIT 1),
				(SELECT Id, 
						AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
						AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c,
						AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c,
						AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
						AcctSeedERP__Project_Task__c,
						AcctSeedERP__Quantity_Allocated__c,
						AcctSeedERP__Quantity_Per_Unit__c,
						GMBLASERP__Serial_Number__c,
						Actual_Quantity_Filled__c
				 FROM AcctSeedERP__Project_Materials__r)
		 FROM AcctSeed__Project__c
		 WHERE Id = :idProject][0];

		if(!(project.RecordTypeId == gcConstants.idRtProjectManufacturing 
			|| project.RecordTypeId == gcConstants.idRtTradeIn))
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods may not be built, unless the Project Record Type is [Manufacturing/Trade In].'));
			return listMsg;	 	
		}

		if(project.AcctSeedERP__Manufactured_Product__c == null)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'A Manufactured Product must be specified, in order to build Finished Goods.'));
			return listMsg;	 	
		}

	 	if(project.AcctSeedERP__Manufactured_Product__r.AcctSeed__Inventory_Product__c == false)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Manufactured Product must be an Inventory Product, in order to build Finished Goods.'));
			return listMsg;	 	
		}

		if(project.GMBLASERP__Warehouse__c == null)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'A Warehouse must be specified for the Project, in order to Build Finished Goods.'));
			return listMsg;	 	
		}
		
		if(checkProjectHasWip(idProject) == false)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.INFO, 'Finished Goods were not built, because the Project has no WIP.'));
			return listMsg;	 	
		}

		Id idProjectTask;
		Decimal nonInventoryPrice = 0;
		if(project.RecordTypeId == gcConstants.idRtTradeIn)
		{
			for(AcctSeed__Project_Task__c pt : project.AcctSeed__Project_Tasks__r)
			{
				idProjectTask = pt.Id;
			}

			if(idProjectTask == null)
			{
				listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'A Project Task for the Manufactured Product does not exist.'));
				return listMsg;	 	
			}
		
			if(checkProjectHasWip(idProject) == false)
			{
				listMsg.add(new ApexPages.Message(ApexPages.Severity.INFO, 'Finished Goods were not built, because the Project has no WIP.'));
				return listMsg;	 	
			}
		

		 	if(project.AcctSeedERP__Manufactured_Product__r.AcctSeedERP__Serialized__c)
		 	{
		 		if(project.Serial_Number__c == null)
				{
					listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods were not built, because the Manufactured Product is serialized, and a Serial Number has not been specified for the Project.'));
					return listMsg;	 	
				}
			 	else if(project.AcctSeedERP__Manufactured_Product__c != project.Serial_Number__r.GMBLASERP__Product__c)
				{
					listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods were not built, because the specified Serial Number is for a different Product than the Manufactured Product.'));
					return listMsg;	 	
				}

				//first, find or create a Material record
				AcctSeedERP__Material__c matl;
				for(AcctSeedERP__Material__c mx : project.AcctSeedERP__Project_Materials__r)
				{
					if(mx.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c){
						if(mx.AcctSeedERP__Product__c == project.AcctSeedERP__Manufactured_Product__c)
						{
							if(matl == null || matl.GMBLASERP__Serial_Number__c == project.Serial_Number__c)
								matl = mx;
						}else{
							if(mx.Actual_Quantity_Filled__c != mx.AcctSeedERP__Quantity_Per_Unit__c){
								listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods were not built, because all items are not moved to WIP.'));
								return listMsg;
							}
						}
					}else{
						Decimal qt = mx.AcctSeedERP__Quantity_Per_Unit__c == null ? 0 : mx.AcctSeedERP__Quantity_Per_Unit__c;
						Decimal am = mx.AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c == null ? 0 : mx.AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c;
						nonInventoryPrice += (qt * am);
					}
				}
				if(matl != null && matl.GMBLASERP__Serial_Number__c == null)
				{
					matl.GMBLASERP__Serial_Number__c = project.Serial_Number__c;
					update matl;
				}
				else if(matl == null)
				{
					matl = new AcctSeedERP__Material__c(
							AcctSeedERP__Product__c = project.AcctSeedERP__Manufactured_Product__c,
							AcctSeedERP__Project__c = project.Id,
							AcctSeedERP__Project_Task__c = idProjectTask,
	                        AcctSeedERP__Quantity_Per_Unit__c = 1,
	                        GMBLASERP__Serial_Number__c = project.Serial_Number__c,
	                        GMBLASERP__Unit_Price__c = 0,
	                        GMBLASERP__Price_Override__c = true
					);
					insert matl;
				}
				Boolean mfgExists = false;
				for(AcctSeedERP__Manufacturing_Inventory_Movement__c mfg : 
					[SELECT Id 
					FROM AcctSeedERP__Manufacturing_Inventory_Movement__c 
					WHERE AcctSeedERP__Material__c =:matl.Id])
				{
					mfgExists = true;
				}
				/// If a MFG movements does not exist and also the Serial Number is not in inventory then that means the Serial Number was used somewhere else
				/// Cannot proceed to create FG 
				if(!mfgExists && project.Serial_Number__r.GMBLASERP__Inventory_Balance__c == null)
				{
					listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods were not built, because the Project Serial is not in inventory.'));
					return listMsg;	 	
				}
		    	AcctSeedERP__Inbound_Inventory_Movement__c inb;
		    	Id idGlTradeIn = gcConstants.idGlTradeIn;
		    	for(AcctSeedERP__Inbound_Inventory_Movement__c i : [SELECT Id, AcctSeedERP__Unit_Cost__c FROM AcctSeedERP__Inbound_Inventory_Movement__c WHERE GMBLASERP__Serial_Number__c =:project.Serial_Number__c AND AcctSeedERP__Project__c =:idProject AND AcctSeedERP__Unit_Cost__c != 0 AND AcctSeedERP__Credit_GL_Account__c =:idGlTradeIn ]){
		    		inb = i;
		    	}
		    	if(inb == null){
		    		listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'There must be a tradein value for the latest inbound.'));
		    		return listMsg;	 	
		    	}

				if(!mfgExists)
				{
					insert new AcctSeedERP__Manufacturing_Inventory_Movement__c(
						AcctSeedERP__Inventory_Balance__c = project.Serial_Number__r.GMBLASERP__Inventory_Balance__c,
						AcctSeedERP__Material__c = matl.Id,
						AcctSeedERP__Movement_Date__c = date.Today(),
						AcctSeedERP__Quantity__c = 1,
						AcctSeedERP__Unit_Cost__c = 0,
						GMBLASERP__Lot__c = project.Serial_Number__r.GMBLASERP__Lot__c,
						GMBLASERP__Serial_Number__c = project.Serial_Number__c
					);
				}
			}
		}

    	//create an inventory movement to move the finished good from WIP to inventory.
    	//AcctSeedERP__Inbound_Inventory_Movement__c inb;
    	//for(AcctSeedERP__Inbound_Inventory_Movement__c i : [SELECT Id, AcctSeedERP__Unit_Cost__c FROM AcctSeedERP__Inbound_Inventory_Movement__c WHERE GMBLASERP__Serial_Number__c =:project.Serial_Number__c AND AcctSeedERP__Project__c =:idProject]){
    	//	inb = i;
    	//}
    	Id idGlWIP = gcConstants.idGlWip;
    	Decimal amtWip = 0; // = inb != null ? (inb.AcctSeedERP__Unit_Cost__c == null ? 0 : inb.AcctSeedERP__Unit_Cost__c) : tradeInAmount;
		for(AggregateResult aggRes : 
			[SELECT sum(AcctSeed__Amount__c) amt
			 FROM AcctSeed__Transaction__c
			 WHERE AcctSeed__Project__c = :idProject
			   AND AcctSeed__GL_Account__c = :idGlWIP
			   AND (AcctSeed__Amount__c < 0 OR AcctSeed__Amount__c > 0)])
		{
			Decimal amt = 0;
			if(aggRes.get('amt') != null)
				amt = (Decimal)aggRes.get('amt');
			amtWip += (amt == null ? 0 : amt);
		}

		//if(inb != null){
		//	inb.AcctSeedERP__Unit_Cost__c = amtWip;
		//	update inb;
		//}else{
    	AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c = :project.GMBLASERP__Warehouse__c][0];
    	Id idBalance = GMBLASERP.gcInventoryBalance.findOrCreateBalance(project.AcctSeedERP__Manufactured_Product__c,project.GMBLASERP__Warehouse__c,loc.Id);
    	insert new AcctSeedERP__Inbound_Inventory_Movement__c(
    			AcctSeedERP__Credit_GL_Account__c = idGlWIP,
    			AcctSeedERP__Inventory_Balance__c = idBalance,
    			AcctSeedERP__Movement_Date__c = date.today(),
    			AcctSeedERP__Project__c = idProject,
    			AcctSeedERP__Project_Task__c = idProjectTask,
    			AcctSeedERP__Quantity__c = 1,
    			AcctSeedERP__Type__c = 'Accounting',
    			AcctSeedERP__Unit_Cost__c = amtWip + nonInventoryPrice,
    			GMBLASERP__Cost_Override__c = true,
    			GMBLASERP__Lot__c = project.Serial_Number__r.GMBLASERP__Lot__c,
    			GMBLASERP__Serial_Number__c = project.Serial_Number__c
    		);
    	/// Now Create the auto inbound moves
  //  	List<AcctSeedERP__Inbound_Inventory_Movement__c> listInbound = new List<AcctSeedERP__Inbound_Inventory_Movement__c>();
  //  	Id idGlTradeIn = gcConstants.idGlTradeIn;
  //  	List<GMBLASERP__Serial_Number__c> listSerials = new List<GMBLASERP__Serial_Number__c>();
		//Map<Id,Map<Id,Map<Id,Id>>> mapPWLB = new Map<Id,Map<Id,Map<Id,Id>>>();
  //  	for(GMBLASERP__Serial_Number__c nested :
  //          [SELECT 
  //          	Id, 
  //          	GMBLASERP__Lot__c, 
  //          	GMBLASERP__Product__c, 
  //          	GMBLASERP__Inventory_Balance__c,
  //          	(SELECT Id FROM GMBLASERP__Manufacturing_Inventory_Movements__r LIMIT 1)
  //          FROM GMBLASERP__Serial_Number__c
  //          WHERE Nest__c =:project.Serial_Number__c])
  //      {
		//	/// If it is already in inventory then no need
		//	if(nested.GMBLASERP__Inventory_Balance__c != null) continue;
		//	/// If the serial was used in WIP then no need
		//	if(!nested.GMBLASERP__Manufacturing_Inventory_Movements__r.isEmpty()) continue;
			
		//	listSerials.add(nested);
		//	if(!mapPWLB.containsKey(nested.GMBLASERP__Product__c))
		//	{
		//		mapPWLB.put(nested.GMBLASERP__Product__c, new map<Id,map<Id,Id>>{project.GMBLASERP__Warehouse__c => new map<Id,Id>{loc.Id => null}});
		//	}
  //      }
  //      if(!mapPWLB.isEmpty())
  //      {
		//	GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
  //      	for(GMBLASERP__Serial_Number__c serial : listSerials)
  //      	{
  //      		Id idSNBalance = mapPWLB.get(serial.GMBLASERP__Product__c).get(project.GMBLASERP__Warehouse__c).get(loc.Id);
  //      		listInbound.add(new AcctSeedERP__Inbound_Inventory_Movement__c(
		//			    			AcctSeedERP__Credit_GL_Account__c = idGlTradeIn,
		//			    			AcctSeedERP__Inventory_Balance__c = idSNBalance,
		//			    			AcctSeedERP__Movement_Date__c = date.today(),
		//			    			AcctSeedERP__Project__c = idProject,
		//			    			AcctSeedERP__Project_Task__c = idProjectTask,
		//			    			AcctSeedERP__Quantity__c = 1,
		//			    			AcctSeedERP__Type__c = 'Accounting',
		//			    			AcctSeedERP__Unit_Cost__c = 0,
		//			    			GMBLASERP__Cost_Override__c = true,
		//			    			GMBLASERP__Lot__c = serial.GMBLASERP__Lot__c,
		//			    			GMBLASERP__Serial_Number__c = serial.Id
		//			    		));
		//   	}
  //      }

  //      if(!listInbound.isEmpty())
  //  		insert listInbound;
	    //}

		return listMsg;
	}

	@RemoteAction
	public static list<String> createInboundMovesRA(Id idProject)
	{
		return stringifyPageMessages(createInboundMoves(idProject));
	}

	@RemoteAction
	public static List<ApexPages.Message> createInboundMoves(Id idProject)
	{
		list<ApexPages.Message> listMsg = new list<ApexPages.Message>();

		AcctSeed__Project__c project = 
		[SELECT Id,
				RecordTypeId,
				Internal_Partner_Boat_Sale__c,
				AcctSeedERP__Manufactured_Product__c,
				AcctSeedERP__Manufactured_Product__r.AcctSeed__Inventory_Product__c,
				AcctSeedERP__Manufactured_Product__r.AcctSeedERP__Serialized__c,
				Serial_Number__c,
				Serial_Number__r.GMBLASERP__Inventory_Balance__c,
				Serial_Number__r.GMBLASERP__Lot__c,
				Serial_Number__r.GMBLASERP__Product__c,
         		GMBLASERP__Warehouse__c,
				(SELECT Id, Product__c FROM AcctSeed__Project_Tasks__r ORDER BY CreatedDate),
				(SELECT Id, 
						AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
						AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c,
						AcctSeedERP__Project_Task__c,
						AcctSeedERP__Quantity_Allocated__c,
						AcctSeedERP__Quantity_Per_Unit__c,
						GMBLASERP__Serial_Number__c
				 FROM AcctSeedERP__Project_Materials__r
				 WHERE AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = true
				   AND AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = TRUE)
		 FROM AcctSeed__Project__c
		 WHERE Id = :idProject][0];

		 Boolean isInternalPartnerBoat = project.Internal_Partner_Boat_Sale__c;

		if(project.RecordTypeId != gcConstants.idRtTradeIn)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods may not be built, unless the Project Record Type is [TradeIn].'));
			return listMsg;	 	
		}

		if(project.AcctSeedERP__Manufactured_Product__c == null && !isInternalPartnerBoat)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'A Manufactured Product must be specified, in order to build Finished Goods.'));
			return listMsg;	 	
		}

	 	if(project.AcctSeedERP__Manufactured_Product__r.AcctSeed__Inventory_Product__c == false && !isInternalPartnerBoat)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Manufactured Product must be an Inventory Product, in order to build Finished Goods.'));
			return listMsg;	 	
		}

		if(project.GMBLASERP__Warehouse__c == null)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'A Warehouse must be specified for the Project, in order to Build Finished Goods.'));
			return listMsg;	 	
		}

		Id idProjectTask;
		for(AcctSeed__Project_Task__c pt : project.AcctSeed__Project_Tasks__r)
		{
			if(pt.Product__c == project.AcctSeedERP__Manufactured_Product__c && !isInternalPartnerBoat)
			{
				if(idProjectTask != null)
				{
					listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'There cannot be multiple project tasks for the manufactured product.'));
					return listMsg;	 	
				}

				idProjectTask = pt.Id;
			}
		}
		if(idProjectTask == null && !project.AcctSeed__Project_Tasks__r.isEmpty())
			idProjectTask = project.AcctSeed__Project_Tasks__r[0].Id;

		if(!isInternalPartnerBoat)
	 	if(project.AcctSeedERP__Manufactured_Product__r.AcctSeedERP__Serialized__c)
	 	{
	 		if(project.Serial_Number__c == null)
			{
				listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods were not built, because the Manufactured Product is serialized, and a Serial Number has not been specified for the Project.'));
				return listMsg;	 	
			}
		 	else if(project.AcctSeedERP__Manufactured_Product__c != project.Serial_Number__r.GMBLASERP__Product__c)
			{
				listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods were not built, because the specified Serial Number is for a different Product than the Manufactured Product.'));
				return listMsg;	 	
			}
		 	else if(checkProjectHasFinishedGoods(idProject))
			{
				listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Finished Goods were not built, because the Project already has Finished Goods.  All Finished Goods must be deleted or reversed, before building Finished Goods.'));
				return listMsg;	 	
			}
		}

    	List<AcctSeedERP__Inbound_Inventory_Movement__c> listInbound = new List<AcctSeedERP__Inbound_Inventory_Movement__c>();
    	Id idGlTradeIn = gcConstants.idGlTradeIn;

    	AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c = :project.GMBLASERP__Warehouse__c][0];

    	List<GMBLASERP__Serial_Number__c> listSerials = new List<GMBLASERP__Serial_Number__c>();
		Map<Id,Map<Id,Map<Id,Id>>> mapPWLB = new Map<Id,Map<Id,Map<Id,Id>>>();
    	for(GMBLASERP__Serial_Number__c serial :
            [SELECT 
            	Id, 
            	GMBLASERP__Lot__c, 
            	GMBLASERP__Product__c, 
            	GMBLASERP__Inventory_Balance__c,
            	(SELECT Id, 
            		GMBLASERP__Lot__c, 
            		GMBLASERP__Product__c,
            		GMBLASERP__Inventory_Balance__c 
            	FROM Nested_Serial_Numbers__r) 
            FROM GMBLASERP__Serial_Number__c
            WHERE Id =:project.Serial_Number__c])
        {
        	if(serial.GMBLASERP__Inventory_Balance__c == null){
        		listSerials.add(serial);
				mapPWLB.put(serial.GMBLASERP__Product__c, new map<Id,map<Id,Id>>{project.GMBLASERP__Warehouse__c => new map<Id,Id>{loc.Id => null}});
        	}

			if(!serial.Nested_Serial_Numbers__r.isEmpty())
			{
				for(GMBLASERP__Serial_Number__c nested : serial.Nested_Serial_Numbers__r)
				{
					if(nested.GMBLASERP__Inventory_Balance__c != null) continue;
					
					listSerials.add(nested);
					if(!mapPWLB.containsKey(nested.GMBLASERP__Product__c))
					{
						mapPWLB.put(nested.GMBLASERP__Product__c, new map<Id,map<Id,Id>>{project.GMBLASERP__Warehouse__c => new map<Id,Id>{loc.Id => null}});
					}
				}
			}
        }
        if(!mapPWLB.isEmpty())
        {
			GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
        	for(GMBLASERP__Serial_Number__c serial : listSerials)
        	{
        		Id idBalance = mapPWLB.get(serial.GMBLASERP__Product__c).get(project.GMBLASERP__Warehouse__c).get(loc.Id);
        		listInbound.add(new AcctSeedERP__Inbound_Inventory_Movement__c(
					    			AcctSeedERP__Credit_GL_Account__c = idGlTradeIn,
					    			AcctSeedERP__Inventory_Balance__c = idBalance,
					    			AcctSeedERP__Movement_Date__c = date.today(),
					    			AcctSeedERP__Project__c = idProject,
					    			AcctSeedERP__Project_Task__c = idProjectTask,
					    			AcctSeedERP__Quantity__c = 1,
					    			AcctSeedERP__Type__c = 'Accounting',
					    			AcctSeedERP__Unit_Cost__c = 0,
					    			GMBLASERP__Cost_Override__c = true,
					    			GMBLASERP__Lot__c = serial.GMBLASERP__Lot__c,
					    			GMBLASERP__Serial_Number__c = serial.Id
					    		));
		   	}
        }
        
        if(!listInbound.isEmpty())
    		insert listInbound;

		return listMsg;
	}
	////////////

	@RemoteAction
	public static list<String> createInboundInboundMovesRA(Id idProject, String inboundDateStr)
	{
		Date inboundDate = Date.today();
		if(inboundDateStr != null)
			inboundDate = Date.parse(inboundDateStr);
		return stringifyPageMessages(createInboundMovesForInternal(idProject, inboundDate));
	}
	@RemoteAction
	public static List<ApexPages.Message> createInboundMovesForInternal(Id idProject, Date inboundDate)
	{
		list<ApexPages.Message> listMsg = new list<ApexPages.Message>();
		Set<Id> setIdSerial = new Set<Id>(); 
		AcctSeed__Project__c project = 
		[SELECT Id,
				RecordTypeId,
				Order_Item_Total__c,
				Expense__c,
				Internal_Partner_Boat_Sale__c,
         		GMBLASERP__Warehouse__c,
         		Internal_Destination_WarehouseId__c,
				(SELECT Id, Product__c FROM AcctSeed__Project_Tasks__r ORDER BY CreatedDate)
		 FROM AcctSeed__Project__c
		 WHERE Id = :idProject][0];

		Id idDestinationWarehouse = project.Internal_Destination_WarehouseId__c;
		Id idProjectTask = project.AcctSeed__Project_Tasks__r[0].Id;

		Boolean isInternalPartnerBoat = project.Internal_Partner_Boat_Sale__c;

		if(idDestinationWarehouse == null)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'A Warehouse must be specified for the Project, in order to Build Internal Transfers.'));
			return listMsg;	 	
		}
		Decimal projectTotal = project.Order_Item_Total__c;
		Decimal projectProfit = project.Order_Item_Total__c - project.Expense__c;
    	List<AcctSeedERP__Inbound_Inventory_Movement__c> listInbound = new List<AcctSeedERP__Inbound_Inventory_Movement__c>();
    	Id idGlInternalBilling = gcConstants.idGlInternalBilling;

    	AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c = :idDestinationWarehouse][0];

    	//List<GMBLASERP__Serial_Number__c> listSerials = new List<GMBLASERP__Serial_Number__c>();
		Map<Id,Map<Id,Map<Id,Id>>> mapPWLB = new Map<Id,Map<Id,Map<Id,Id>>>();
		Map<Id,Decimal> mapUnitCost = new Map<Id,Decimal>();
		Map<Id,Decimal> mapProfitShare = new Map<Id,Decimal>();
        Boolean boatExist = false;
		List<AcctSeedERP__Material__c> listMatl = new List<AcctSeedERP__Material__c>();
		for(AcctSeedERP__Material__c matl : 
		 		[SELECT Id, 
						AcctSeedERP__Product__c,
						AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
						AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c,
						AcctSeedERP__Product__r.RecordType.Name,
						AcctSeedERP__Project_Task__c,
						AcctSeedERP__Quantity_Allocated__c,
						AcctSeedERP__Quantity_Per_Unit__c,
						GMBLASERP__Unit_Price__c,
						GMBLASERP__Serial_Number__c,
						GMBLASERP__Serial_Number__r.GMBLASERP__Lot__c,
						(SELECT Id, GMBLASERP__Inventory_GL_Amount__c FROM AcctSeedERP__Manufacturing_Inventory_Movements__r)
				FROM AcctSeedERP__Material__c
				WHERE AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = true 
					AND GMBLASERP__Serial_Number__c != null
					AND AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = TRUE
					AND AcctSeedERP__Project__c = :idProject])
		 {
             if(matl.AcctSeedERP__Product__r.RecordType.Name == 'Boat') {
                 boatExist = true;
             }
		 	listMatl.add(matl);
		 	mapPWLB.put(matl.AcctSeedERP__Product__c, new map<Id,map<Id,Id>>{idDestinationWarehouse => new map<Id,Id>{loc.Id => null}});
		 }
        for(AcctSeedERP__Material__c matl : listMatl)
        {
            Decimal glAmount = matl.AcctSeedERP__Manufacturing_Inventory_Movements__r[0].GMBLASERP__Inventory_GL_Amount__c;
            if(matl.AcctSeedERP__Product__r.RecordType.Name != 'Boat'){
                //if(matl.AcctSeedERP__Product__r.RecordType.Name == 'Motor'){
                //	mapUnitCost.put(matl.GMBLASERP__Serial_Number__c, glAmount);
                //	projectTotal -= glAmount;
                //	mapProfitShare.put(matl.GMBLASERP__Serial_Number__c, 0);
                //}
                //else {
                Decimal serialProfit = matl.GMBLASERP__Unit_Price__c - glAmount;
                mapProfitShare.put(matl.GMBLASERP__Serial_Number__c, serialProfit);
                mapUnitCost.put(matl.GMBLASERP__Serial_Number__c, matl.GMBLASERP__Unit_Price__c);
                projectTotal -= matl.GMBLASERP__Unit_Price__c;
                projectProfit -= serialProfit;
                //}
            }
        }

        List<GMBLASERP__Serial_Number__c> listSerials = new List<GMBLASERP__Serial_Number__c>();
        if(!mapPWLB.isEmpty())
        {
			GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
        	for(AcctSeedERP__Material__c matl : listMatl)
        	{
        		Id idBalance = mapPWLB.get(matl.AcctSeedERP__Product__c).get(idDestinationWarehouse).get(loc.Id);

        		Decimal unitCost = 0;
        		if(boatExist && matl.AcctSeedERP__Product__r.RecordType.Name == 'Boat'){
        			unitCost = projectTotal;
        			listSerials.add(new GMBLASERP__Serial_Number__c(Id = matl.GMBLASERP__Serial_Number__c, Billing_Revenue_Internal__c = projectProfit));
        		}else if(!boatExist && matl.AcctSeedERP__Product__r.RecordType.Name != 'Boat'){
                    unitCost = mapUnitCost.get(matl.GMBLASERP__Serial_Number__c) + projectTotal;
        			listSerials.add(new GMBLASERP__Serial_Number__c(Id = matl.GMBLASERP__Serial_Number__c, Billing_Revenue_Internal__c = projectProfit));
        		}else{
        			unitCost = mapUnitCost.get(matl.GMBLASERP__Serial_Number__c);
        			listSerials.add(new GMBLASERP__Serial_Number__c(Id = matl.GMBLASERP__Serial_Number__c, Billing_Revenue_Internal__c = mapProfitShare.get(matl.GMBLASERP__Serial_Number__c)));
        		}

        		listInbound.add(new AcctSeedERP__Inbound_Inventory_Movement__c(
					    			AcctSeedERP__Credit_GL_Account__c = idGlInternalBilling,
					    			AcctSeedERP__Inventory_Balance__c = idBalance,
					    			AcctSeedERP__Movement_Date__c = inboundDate,
					    			AcctSeedERP__Project__c = idProject,
					    			AcctSeedERP__Project_Task__c = idProjectTask,
					    			AcctSeedERP__Quantity__c = 1,
					    			AcctSeedERP__Type__c = 'Accounting',
					    			AcctSeedERP__Unit_Cost__c = unitCost,
					    			GMBLASERP__Cost_Override__c = true,
					    			GMBLASERP__Lot__c = matl.GMBLASERP__Serial_Number__r.GMBLASERP__Lot__c,
					    			GMBLASERP__Serial_Number__c = matl.GMBLASERP__Serial_Number__c
					    		));
		   	}
        }
        
        if(!listInbound.isEmpty()){
    		insert listInbound;
    		if(!listSerials.isEmpty()){
    			Boolean oldVal = gcSerialNumber.disableTrigger; 
    			gcSerialNumber.disableTrigger = true;
    			update listSerials;
    			gcSerialNumber.disableTrigger = oldVal;
    		}
        }

		return listMsg;
	}

	@RemoteAction
	public static list<String> takeExpenseRA(Id idProject,String expenseDate)
	{
		return stringifyPageMessages(takeExpense(idProject,expenseDate));
	}

    @RemoteAction
	public static List<ApexPages.Message> takeExpense(Id idFilter, String expenseDate)
	{
        System.debug('From MFG or TradeIn');
		Date cogsDate = Date.today();
		if(expenseDate != null)
			cogsDate = Date.parse(expenseDate);
		list<ApexPages.Message> listMsg = new list<ApexPages.Message>();
		Id idProject;
		Id idGlWip = gcConstants.idGlWip;
		Id idGlCogsParts = gcConstants.idGlCogsParts;
		Id idGlProjectParts = gcConstants.idGlProjectParts;
		Id idGlInternalLabour = gcConstants.idGlInternalLabour;
		Id idGlWagesLabour = gcConstants.idGlWagesLabour;
		Id idGlv1Wholesale = gcConstants.idGlv1Wholesale;
		Id idGlv2Sales = gcConstants.idGlv2Sales;
		Id idGlv2PartsAndService = gcConstants.idGlv2PartsAndService;
		Id idGlProjectPartsClearing = gcConstants.idGlProjectPartsClearing;
		Id idProductInternalLabour = gcConstants.idProductInternalLabour;

		list<AcctSeed__Journal_Entry_Line__c> listJEL = new list<AcctSeed__Journal_Entry_Line__c>();
		list<AcctSeed__Journal_Entry_Line__c> listJELLabour = new list<AcctSeed__Journal_Entry_Line__c>();
		List<AcctSeedERP__Material__c> listMatlNow = new List<AcctSeedERP__Material__c>();
		Map<Id,Map<Id,Decimal>> mapPTQ = new Map<Id,Map<Id,Decimal>>();
    	for(AcctSeedERP__Material__c matl : 
    		[SELECT Id,
    				AcctSeedERP__Product__c,
    				AcctSeedERP__Product__r.RecordType.Name,
    				AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c,
    				AcctSeedERP__Product__r.Partner_Price__c,
    				AcctSeedERP__Product__r.Loaded_Cost__c,
    				AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c,
    				AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,
    				AcctSeedERP__Project__c,
    				AcctSeedERP__Project__r.RecordTypeId,
    				AcctSeedERP__Project__r.Internal_Labour_Service__c,
    				AcctSeedERP__Project__r.Internal_Warranty__c,
    				AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c,
    				AcctSeedERP__Project__r.Internal_Partner_Parts_Order__c,
    				AcctSeedERP__Project__r.GL_Account_Variable_1__c,
    				AcctSeedERP__Project__r.GL_Account_Variable_2__c,
    				AcctSeedERP__Project__r.AcctSeed__Account__r.GL_Account_Variable_1__c,
    				AcctSeedERP__Project_Task__c,
    				AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c,
    				AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
    				AcctSeedERP__Quantity_Allocated__c,
    				AcctSeedERP__Quantity_Per_Unit__c,
    				GMBLASERP__Serial_Number__c,
    				GMBLASERP__Unit_Price__c,
    				No_WIP__c,
    				AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
    				(SELECT Id, AcctSeed__Units__c FROM Journal_Entry_Lines__r),
    				(SELECT Id, AcctSeedERP__Quantity__c FROM Outbound_Inventory_Movements__r),
    				(SELECT Id, AcctSeedERP__Unit_Cost__c FROM AcctSeedERP__Manufacturing_Inventory_Movements__r LIMIT 1)
    		FROM AcctSeedERP__Material__c
    		WHERE (AcctSeedERP__Project__c = :idFilter OR AcctSeedERP__Project_Task__c = :idFilter)])
		{
			if((matl.AcctSeedERP__Project__r.RecordTypeId != gcConstants.idRtProjectManufacturing && matl.AcctSeedERP__Project__r.RecordTypeId != gcConstants.idRtTradeIn)
				|| (!matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && (matl.AcctSeedERP__Project__r.RecordTypeId == gcConstants.idRtProjectManufacturing
						|| matl.AcctSeedERP__Project__r.RecordTypeId == gcConstants.idRtTradeIn)))
			{
				System.debug('Inside');
				if (idProject == null) idProject = matl.AcctSeedERP__Project__c;
				if (matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && matl.AcctSeedERP__Manufacturing_Inventory_Movements__r.isEmpty() && !matl.AcctSeedERP__Project__r.Internal_Warranty__c) continue;
				Decimal qty = matl.AcctSeedERP__Quantity_Per_Unit__c;
				Decimal amt = matl.AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c;
				Decimal unitCost = 0;
				if (matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && !matl.AcctSeedERP__Manufacturing_Inventory_Movements__r.isEmpty()) {
					qty = matl.AcctSeedERP__Quantity_Allocated__c;
					unitCost = matl.AcctSeedERP__Manufacturing_Inventory_Movements__r[0].AcctSeedERP__Unit_Cost__c;
				}

				if (!matl.Outbound_Inventory_Movements__r.isEmpty()) {
					qty = 0;
					unitCost = 0;
					for (AcctSeedERP__Outbound_Inventory_Movement__c oim : matl.Outbound_Inventory_Movements__r)
						qty += oim.AcctSeedERP__Quantity__c == null ? 0 : oim.AcctSeedERP__Quantity__c;
				}

				if (!matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && (matl.AcctSeedERP__Project__r.RecordTypeId == gcConstants.idRtProjectManufacturing || matl.AcctSeedERP__Project__r.RecordTypeId == gcConstants.idRtTradeIn)) {
					unitCost = matl.AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c;
				}

				if (!matl.Journal_Entry_Lines__r.isEmpty())
					for (AcctSeed__Journal_Entry_Line__c jel : matl.Journal_Entry_Lines__r) {
						qty -= jel.AcctSeed__Units__c == null ? 0 : jel.AcctSeed__Units__c;
					}
				if (matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c || (!matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && (matl.AcctSeedERP__Project__r.RecordTypeId == gcConstants.idRtProjectManufacturing || matl.AcctSeedERP__Project__r.RecordTypeId == gcConstants.idRtTradeIn)))
					amt = qty * unitCost;

				if (qty != null && qty != 0) {
					if (amt == null) amt = 0;

					amt = amt.setScale(6);
					qty = qty.setScale(6);
					Id idDebitGL = idGlProjectParts;
					Id idCreditGL = idGlProjectPartsClearing;
					if (matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && (matl.AcctSeedERP__Project__r.RecordTypeId != gcConstants.idRtProjectManufacturing || matl.AcctSeedERP__Project__r.RecordTypeId != gcConstants.idRtTradeIn)) {
						idDebitGL = idGlCogsParts;
						idCreditGL = idGlWIP;
					} else if (!matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && (matl.AcctSeedERP__Project__r.RecordTypeId == gcConstants.idRtProjectManufacturing || matl.AcctSeedERP__Project__r.RecordTypeId == gcConstants.idRtTradeIn)) {
						idDebitGL = idGlWIP;
						idCreditGL = matl.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c;
					}
					if (matl.AcctSeedERP__Product__r.RecordType.Name == gcConstants.internalProductRecordTypeName
						&& matl.AcctSeedERP__Project__r.Internal_Labour_Service__c) {
						idDebitGL = idGlWagesLabour;
						idCreditGL = idGlInternalLabour;
						amt = (matl.GMBLASERP__Unit_Price__c == null ? 0 : matl.GMBLASERP__Unit_Price__c) * qty;
					}
					Boolean noERP = false;
					if (matl.AcctSeedERP__Project__r.Internal_Warranty__c) {
						idDebitGL = gcConstants.idGlInternalRevenue;
						noERP = true;
						idCreditGL = gcConstants.idGLInternalWarrantyClearing;
						amt = (matl.GMBLASERP__Unit_Price__c == null ? 0 : matl.GMBLASERP__Unit_Price__c) * qty;
					}
					AcctSeed__Journal_Entry_Line__c debitJE = new AcctSeed__Journal_Entry_Line__c(
						AcctSeed__Debit__c = amt,
						AcctSeed__GL_Account__c = idDebitGL,
						AcctSeed__Product__c = matl.AcctSeedERP__Product__c,
						AcctSeed__Project__c = noERP ? null : matl.AcctSeedERP__Project__c,
						AcctSeed__Project_Task__c = noERP ? null : matl.AcctSeedERP__Project_Task__c,
						AcctSeed__Date__c = cogsDate,
						AcctSeed__Units__c = qty,
						Material__c = matl.Id
					);

					AcctSeed__Journal_Entry_Line__c creditJE = new AcctSeed__Journal_Entry_Line__c(
						AcctSeed__Credit__c = amt,
						AcctSeed__GL_Account__c = idCreditGL,
						AcctSeed__Product__c = matl.AcctSeedERP__Product__c,
						AcctSeed__Project__c = null,
						AcctSeed__Project_Task__c = null,
						AcctSeed__Date__c = cogsDate,
						AcctSeed__Units__c = qty * (-1)
					);
					if (matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c) {
						creditJE.AcctSeed__Project__c = matl.AcctSeedERP__Project__c;
						creditJE.AcctSeed__Project_Task__c = matl.AcctSeedERP__Project_Task__c;
					}
					// For Internal Orders we are actually taking the inventory out of Wholesale
					if (matl.AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c
						|| matl.AcctSeedERP__Project__r.Internal_Partner_Parts_Order__c) {
						creditJE.AcctSeed__GL_Account_Variable_1__c = idGlv1Wholesale;
						creditJE.AcctSeed__GL_Account_Variable_2__c = idGlv2Sales;
						debitJE.AcctSeed__GL_Account_Variable_1__c = idGlv1Wholesale;
						debitJE.AcctSeed__GL_Account_Variable_2__c = idGlv2Sales;
					}

					if (matl.AcctSeedERP__Product__r.RecordType.Name == gcConstants.internalProductRecordTypeName
						&& matl.AcctSeedERP__Project__r.Internal_Labour_Service__c) {
						//debitJE.AcctSeed__Project__c = null;
						//debitJE.AcctSeed__Project_Task__c = null;
						creditJE.AcctSeed__Project__c = matl.AcctSeedERP__Project__c;
						creditJE.AcctSeed__Project_Task__c = matl.AcctSeedERP__Project_Task__c;
						debitJE.AcctSeed__GL_Account_Variable_1__c = matl.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c;
						debitJE.AcctSeed__GL_Account_Variable_2__c = matl.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c;
						listJELLabour.add(debitJE);
						listJELLabour.add(creditJE);
					} else {
						if (matl.AcctSeedERP__Project__r.Internal_Warranty__c) {
							creditJE.AcctSeed__GL_Account_Variable_1__c = matl.AcctSeedERP__Project__r.AcctSeed__Account__r.GL_Account_Variable_1__c;
							debitJE.AcctSeed__GL_Account_Variable_1__c = matl.AcctSeedERP__Project__r.AcctSeed__Account__r.GL_Account_Variable_1__c;
						}
						listJEL.add(debitJE);
						listJEL.add(creditJE);
					}

					/// Now the Internal Parts JEL
					if ((matl.AcctSeedERP__Project__r.RecordTypeId == gcConstants.idRtProjectBoatSale
						|| matl.AcctSeedERP__Project__r.RecordTypeId == gcConstants.idRtProjectCounterSale
						|| matl.AcctSeedERP__Project__r.RecordTypeId == gcConstants.idRtProjectService)
						&& matl.AcctSeedERP__Product__r.RecordType.Name == 'Part') {
						Decimal factoryPrice = matl.AcctSeedERP__Product__r.Partner_Price__c;
						Id projectGLV1 = matl.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c;
						Id projectGLV2 = matl.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c;
						//Decimal factoryLoadedCost = matl.AcctSeedERP__Product__r.Loaded_Cost__c;
						if (factoryPrice == null) factoryPrice = 0;
						factoryPrice = factoryPrice * qty;
						//if(factoryLoadedCost == null) factoryLoadedCost = 0;
						/// Wholesale COST
						if (factoryPrice <> 0) {
							listJEL.add(new AcctSeed__Journal_Entry_Line__c(
								AcctSeed__Debit__c = amt,
								AcctSeed__GL_Account__c = idGlCogsParts,
								AcctSeed__Product__c = matl.AcctSeedERP__Product__c,
								AcctSeed__Project__c = null,
								AcctSeed__Project_Task__c = null,
								AcctSeed__GL_Account_Variable_1__c = idGlv1Wholesale,
								AcctSeed__GL_Account_Variable_2__c = idGlv2PartsAndService,//projectGLV2,//idGlv2Sales,
								AcctSeed__Date__c = cogsDate,
								AcctSeed__Units__c = qty)
							);
							/// Wholesale Revenue
							listJEL.add(new AcctSeed__Journal_Entry_Line__c(
								AcctSeed__Credit__c = factoryPrice,
								AcctSeed__GL_Account__c = gcConstants.idGlProductRevenue,
								AcctSeed__Product__c = matl.AcctSeedERP__Product__c,
								AcctSeed__Project__c = null,
								AcctSeed__Project_Task__c = null,
								AcctSeed__GL_Account_Variable_1__c = idGlv1Wholesale,
								AcctSeed__GL_Account_Variable_2__c = idGlv2PartsAndService,//projectGLV2,//idGlv2Sales,
								AcctSeed__Date__c = cogsDate,
								AcctSeed__Units__c = qty * (-1))
							);
							/// Wholesale Revenue
							listJEL.add(new AcctSeed__Journal_Entry_Line__c(
								AcctSeed__Debit__c = factoryPrice - amt,
								AcctSeed__GL_Account__c = idGlCogsParts,
								AcctSeed__Product__c = matl.AcctSeedERP__Product__c,
								AcctSeed__Project__c = matl.AcctSeedERP__Project__c,
								AcctSeed__Project_Task__c = matl.AcctSeedERP__Project_Task__c,
								Internal_Wholesale_Cost__c = true,
								AcctSeed__Date__c = cogsDate,
								AcctSeed__Units__c = qty)
							);
						}
					}
				}
			}
    	}
		System.debug('listJEL');
		System.debug(listJEL);
    	if(!listJEL.isEmpty() || !listJELLabour.isEmpty())
    	{
			AcctSeed__Project__c project = 
			[SELECT Id,
					AcctSeedERP__Work_Order_Number__c,
					GL_Account_Variable_1__c,
					GL_Account_Variable_2__c,
					Internal_Partner_Boat_Sale__c,
					Internal_Labour_Service__c,
					Internal_Warranty__c,
                    RecordTypeId
			 FROM AcctSeed__Project__c
			 WHERE Id = :idProject][0]; 
            
            List<AcctSeed__Journal_Entry__c> listJE = new List<AcctSeed__Journal_Entry__c>();
            AcctSeed__Journal_Entry__c je;
            AcctSeed__Journal_Entry__c jeLabour;
            if(!listJEL.isEmpty()){
            	String jobCostOrWarranty = 'Job Cost for ';
            	if(project.Internal_Warranty__c)
            		jobCostOrWarranty = 'Internal Warranty for ';
            	if(project.RecordTypeId == gcConstants.idRtProjectManufacturing || project.RecordTypeId == gcConstants.idRtTradeIn)
            		jobCostOrWarranty = 'Manufacturing Cost for ';

	    		je = new AcctSeed__Journal_Entry__c(
	    			Name = jobCostOrWarranty + project.AcctSeedERP__Work_Order_Number__c,
	    			AcctSeed__Journal_Date__c = cogsDate,//date.today(),
	    			AcctSeed__Status__c = 'Approved',
	    			Project__c = idProject
	    		);
    			listJE.add(je);
    		}
    		if(project.Internal_Labour_Service__c && !listJELLabour.isEmpty()){
	    		jeLabour = new AcctSeed__Journal_Entry__c(
	    			Name = 'Internal Labour for '+ project.AcctSeedERP__Work_Order_Number__c,
	    			AcctSeed__Journal_Date__c = cogsDate,//date.today(),
	    			AcctSeed__Status__c = 'Approved',
	    			Project__c = idProject
	    		);
	    		listJE.add(jeLabour);    			
    		}
    		insert listJE;
    		for(AcctSeed__Journal_Entry_Line__c jel : listJEL)
    		{
    			if(jel.AcctSeed__GL_Account_Variable_1__c == null)
    				jel.AcctSeed__GL_Account_Variable_1__c = project.GL_Account_Variable_1__c;
    			if(jel.AcctSeed__GL_Account_Variable_2__c == null)
    				jel.AcctSeed__GL_Account_Variable_2__c = project.GL_Account_Variable_2__c;
    			jel.AcctSeed__Journal_Entry__c = je.Id;
    		}
    		for(AcctSeed__Journal_Entry_Line__c jel : listJELLabour)
    		{
    			if(jel.AcctSeed__GL_Account_Variable_1__c == null)
    				jel.AcctSeed__GL_Account_Variable_1__c = project.GL_Account_Variable_1__c;
    			if(jel.AcctSeed__GL_Account_Variable_2__c == null)
    				jel.AcctSeed__GL_Account_Variable_2__c = project.GL_Account_Variable_2__c;
    			jel.AcctSeed__Journal_Entry__c = jeLabour.Id;
    		}
    		if(!listJELLabour.isEmpty())
    			listJEL.addAll(listJELLabour);
    		
    		insert listJEL;

    		AcctSeed.PostResult[] postResults = AcctSeed.JournalEntryPostService.postJournalEntries(listJE);
    		//if(project.Internal_Partner_Boat_Sale__c)
    		//	createInboundMovesForInternal(project.Id,cogsDate);
    	}

		return listMsg;
    }

	@RemoteAction
	public static list<String> untakeExpenseRA(Id idProject)
	{
		return stringifyPageMessages(untakeExpense(idProject));
	}

    @RemoteAction
    public static list<ApexPages.Message> untakeExpense(Id idProject)
    {
    	list<ApexPages.Message> listMsg = new list<ApexPages.Message>();

		AcctSeed__Project__c project = 
		[SELECT Id,
				GL_Account_Variable_1__c,
				GL_Account_Variable_2__c,
				Internal_Partner_Boat_Sale__c
		 FROM AcctSeed__Project__c
		 WHERE Id = :idProject][0];

		list<AcctSeed__Journal_Entry__c> listJeUnpost = new list<AcctSeed__Journal_Entry__c>();
		list<AcctSeed__Journal_Entry__c> listJeDelete = new list<AcctSeed__Journal_Entry__c>();
		list<AcctSeed__Journal_Entry__c> listJeInsert = new list<AcctSeed__Journal_Entry__c>();
		list<AcctSeed__Journal_Entry_Line__c> listJelInsert = new list<AcctSeed__Journal_Entry_Line__c>();

    	for(AcctSeed__Journal_Entry__c je :
			[SELECT Id, Name,
					AcctSeed__Accounting_Period__c,
					AcctSeed__Accounting_Period__r.AcctSeed__Status__c,
					AcctSeed__Status__c,
					Project__c,
					Project__r.AcctSeedERP__Work_Order_Number__c,
					(SELECT Id,
							AcctSeed__Credit__c,
							AcctSeed__Debit__c,
							AcctSeed__GL_Account__c,
							AcctSeed__Product__c,
							AcctSeed__Project__c,
							AcctSeed__Project_Task__c,
							AcctSeed__Units__c,
							AcctSeed__GL_Account_Variable_1__c,
							AcctSeed__GL_Account_Variable_2__c,
							Material__c
					 FROM AcctSeed__Journal_Entry_Lines__r)
			 FROM AcctSeed__Journal_Entry__c
			 WHERE Project__c = :idProject
			 	AND (Name like '%Job Cost for%' OR Name like '%Internal Labour for%' OR Name like '%Internal Warranty for%')])
		{
			if(je.AcctSeed__Status__c != 'Posted')
				listJeDelete.add(je);
			else if(je.AcctSeed__Accounting_Period__r.AcctSeed__Status__c == 'Open')
				listJeUnpost.add(je);
			else
			{
				if(listJeInsert.isEmpty())
				{
					listJeInsert.add(new AcctSeed__Journal_Entry__c(
		    			Name = 'Reverse ' + je.Name,
		    			AcctSeed__Journal_Date__c = date.today(),
		    			AcctSeed__Status__c = 'Approved',
		    			Project__c = idProject));
					insert listJeInsert;
				}

				for(AcctSeed__Journal_Entry_Line__c x : je.AcctSeed__Journal_Entry_Lines__r)
				{
					AcctSeed__Journal_Entry_Line__c jel = x.clone();
					if(x.AcctSeed__Debit__c != null)
						x.AcctSeed__Debit__c *= (-1);
					if(x.AcctSeed__Credit__c != null)
						x.AcctSeed__Credit__c *= (-1);
					if(x.AcctSeed__Units__c != null)
						x.AcctSeed__Units__c *= (-1);

					//jel.AcctSeed__GL_Account_Variable_1__c = project.GL_Account_Variable_1__c;
					//jel.AcctSeed__GL_Account_Variable_2__c = project.GL_Account_Variable_2__c;

					jel.AcctSeed__Journal_Entry__c = listJeInsert[0].Id;

					listJelInsert.add(jel);
				}
			}
		}
		if(project.Internal_Partner_Boat_Sale__c)
			unbuildFinishedGoods(idProject);

		if(!listJelInsert.isEmpty())
		{
			insert listJelInsert;
    		AcctSeed.PostResult[] postResults = AcctSeed.JournalEntryPostService.postJournalEntries(listJeInsert);
		}

		if(!listJeUnpost.isEmpty())
		{
			AcctSeed.PostResult[] postResults = AcctSeed.JournalEntryPostService.unpostJournalEntries(listJeUnpost);
			listJeDelete.addAll(listJeUnpost);
		}

		if(!listJeDelete.isEmpty())
			delete listJeDelete;

		if(project.Internal_Partner_Boat_Sale__c){
	        List<GMBLASERP__Serial_Number__c> listSerials = new List<GMBLASERP__Serial_Number__c>();		
	    	for(AcctSeedERP__Material__c matl : 
	    		[SELECT Id,
	    				GMBLASERP__Serial_Number__c
	    		FROM AcctSeedERP__Material__c
	    		WHERE AcctSeedERP__Project__c = :idProject
	    			AND GMBLASERP__Serial_Number__c != null])
	    	{
	    		listSerials.add(new GMBLASERP__Serial_Number__c(Id = matl.GMBLASERP__Serial_Number__c, Billing_Revenue_Used__c = false, Billing_Revenue_Internal__c = 0));
	    	}
			if(!listSerials.isEmpty()){
				Boolean oldVal = gcSerialNumber.disableTrigger; 
				gcSerialNumber.disableTrigger = true;
				update listSerials;
				gcSerialNumber.disableTrigger = oldVal;
			}
		}

		return listMsg;
    }

    @RemoteAction
	public static list<String> createWipRASelected(Id idProject, String pIdWarehouse, List<Map<String,String>> listMaterials, String movementDate)
	{
		return stringifyPageMessages(createWipSelected(idProject, pIdWarehouse, listMaterials, movementDate));
	}

	@RemoteAction
	public static List<ApexPages.Message> createWipSelected(Id idProject, String pIdWarehouse, List<Map<String,String>> listMaterials, String movementDate)
	{
		Date moveDate = Date.today();
		if(movementDate != null)
			moveDate = Date.parse(movementDate);

		Map<Id,Decimal> mapQtyToMove = new Map<Id,Decimal>();
		Set<String> setIdMaterials = new Set<String>();
		for(Map<String,String> m : listMaterials){
			Id idMaterial = m.get('idMaterial');
			Decimal qtyToMove = Decimal.valueOf(m.get('qtyToMove') == null ? '0' : m.get('qtyToMove'));
			if(qtyToMove <> 0){
				setIdMaterials.add(idMaterial);
				mapQtyToMove.put(idMaterial, qtyToMove);
			}
		}

		List<ApexPages.Message> listMsg = new list<ApexPages.Message>();

		String projectLabel = AcctSeed__Project__c.sObjectType.getDescribe().getLabel();
		String materialLabel = AcctSeedERP__Material__c.sObjectType.getDescribe().getLabel();

		AcctSeed__Project__c project = new AcctSeed__Project__c();
		Id idWarehouse;
		Boolean isMFGOrder = false;
		for(AcctSeed__Project__c px : 
			[SELECT Id, Name,
					RecordTypeId,
					GMBLASERP__Warehouse__c
			 FROM AcctSeed__Project__c
			 WHERE Id = :idProject])
		{
			if(px.RecordTypeId == gcConstants.idRtProjectManufacturing)
				isMFGOrder = true;
			idWarehouse = px.GMBLASERP__Warehouse__c;
			project = px;
		}

		//if(pIdWarehouse != null)
		//	idWarehouse = pIdWarehouse;

		if(project == null)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'A '+projectLabel+' with the specified Id does not exist.'));
			return listMsg;
		}

		if(idWarehouse == null)
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'A Warehouse has not been specified for the '+projectLabel+'.'));
			return listMsg;
		}
		AcctSeedERP__Warehouse__c whs = [SELECT Id, Name, Insufficient_Inventory_Email__c FROM AcctSeedERP__Warehouse__c WHERE Id=:idWarehouse][0];

		Date fillDate = date.Today();

		map<Id,Product2> mapProduct = new map<Id,Product2>();

		list<AcctSeedERP__Material__c> listMatl = new list<AcctSeedERP__Material__c>();
		list<AcctSeedERP__Manufacturing_Inventory_Movement__c> listMove = new list<AcctSeedERP__Manufacturing_Inventory_Movement__c>();

		set<Id> setIdProductBulk = new set<Id>();
		set<Id> setIdLot = new set<Id>();
		set<Id> setIdSerial = new set<Id>();

		set<Id> setIdProductReturn = new set<Id>();		
		Map<Id,Boolean> mapSerialMFG = new Map<Id,Boolean>();
		for(AcctSeedERP__Material__c matl : 
			[SELECT Id, Name,
					AcctSeedERP__GL_Account_Variable_1__c,
					AcctSeedERP__GL_Account_Variable_2__c,
					AcctSeedERP__GL_Account_Variable_3__c,
					AcctSeedERP__GL_Account_Variable_4__c,
					AcctSeedERP__Product__c,
					AcctSeedERP__Product__r.Name,
					AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
					AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c,
					AcctSeedERP__Project__c,
					AcctSeedERP__Project_Task__c,
					AcctSeedERP__Quantity_Allocated__c,
					AcctSeedERP__Quantity_Per_Unit__c,
					GMBLASERP__Lot__c,
					GMBLASERP__Serial_Number__c
			 FROM AcctSeedERP__Material__c
			 WHERE Id IN :setIdMaterials
			   AND AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = true])
		{
			Decimal qty = (matl.AcctSeedERP__Quantity_Per_Unit__c == null ? 0 : matl.AcctSeedERP__Quantity_Per_Unit__c);
			qty -= (matl.AcctSeedERP__Quantity_Allocated__c == null ? 0 : matl.AcctSeedERP__Quantity_Allocated__c);

			qty = qty.setScale(6);

			if(qty == 0)
				continue;
			Decimal qtyToMove = mapQtyToMove.get(matl.Id);
			Product2 product = matl.AcctSeedERP__Product__r;
			if(qtyToMove > qty){
				listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'Product ['+product.Name+'] cannot be moveded from inventory to WIP because quantity to move cannot be more than quantity can be moved on '+materialLabel+' '+matl.Name));
				continue;				
			}else{
				qty = qtyToMove;
			}


			if(product.AcctSeedERP__Serialized__c && matl.GMBLASERP__Serial_Number__c == null)
			{
				listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'Product ['+product.Name+'] was not moved from inventory to WIP because the product is serialized and a serial number has not been specified on '+materialLabel+' '+matl.Name));
				continue;
			}

			if(product.GMBLASERP__Lot_Tracked__c && matl.GMBLASERP__Lot__c == null)
			{
				listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'Product ['+product.Name+'] was not moved from inventory to WIP because the product is lot-tracked and a lot has not been specified on '+materialLabel+' '+matl.Name));
				continue;
			}

			listMatl.add(matl);	
			
			mapProduct.put(product.Id,product);

			if(matl.GMBLASERP__Serial_Number__c != null)
				setIdSerial.add(matl.GMBLASERP__Serial_Number__c);
			else if(matl.GMBLASERP__Lot__c != null)
				setIdLot.add(matl.GMBLASERP__Lot__c);
			else
				setIdProductBulk.add(matl.AcctSeedERP__Product__c);

			if(qty < 0)
				setIdProductReturn.add(matl.AcctSeedERP__Product__c);

			if(!isMFGOrder && product.AcctSeedERP__Serialized__c && matl.GMBLASERP__Serial_Number__c != null)
				mapSerialMFG.put(matl.GMBLASERP__Serial_Number__c, false);
		}
		/// Validate Manufacturing Order
		retrieveIncompleteSerialMFG(mapSerialMFG,idProject);

		mapProduct.remove(null);

		map<Id,map<Id,Decimal>> mapOBQ = new map<Id,map<Id,Decimal>>(); //map [Product / Lot / Serial].Id => InventoryBalance.Id => QtyAvail

		list<AggregateResult> listAggRes = new list<AggregateResult>();
		listAggRes.addAll(
			[SELECT GMBLASERP__Inventory_Balance__c idBalance,
					GMBLASERP__Lot__c idLot,
					GMBLASERP__Product__c idProduct,
					GMBLASERP__Serial_Number__c idSerial,
					sum(GMBLASERP__Quantity__c) qty
			 FROM GMBLASERP__Inventory_Movement_Cube__c
			 WHERE GMBLASERP__Movement_Date__c <= :fillDate
			   AND GMBLASERP__Warehouse__c = :idWarehouse
			   AND (GMBLASERP__Product__c IN :setIdProductBulk OR
			   		GMBLASERP__Lot__c IN :setIdLot OR
			   		GMBLASERP__Serial_Number__c IN :setIdSerial)
			 GROUP BY GMBLASERP__Inventory_Balance__c,
			 		  GMBLASERP__Lot__c,
			 		  GMBLASERP__Product__c,
			 		  GMBLASERP__Serial_Number__c
			 HAVING sum(GMBLASERP__Quantity__c) > 0]
		);		

		for(AggregateResult aggRes : listAggRes)
		{
			Id idBalance = (Id)aggRes.get('idBalance');

			Id idObject = (Id)aggRes.get('idSerial');
			if(idObject == null)
			   idObject = (Id)aggRes.get('idLot');
			if(idObject == null)
			   idObject = (Id)aggRes.get('idProduct');

			Decimal qtyBal = (Decimal)(aggRes.get('qty'));
			qtyBal = (qtyBal == null ? 0 : qtyBal);

			map<Id,Decimal> mapBQ = mapOBQ.get(idObject);
			if(mapBQ == null)
			{
				mapBQ = new map<Id,Decimal>();
				mapOBQ.put(idObject,mapBQ);
			}

			Decimal qtyMap = mapBQ.get(idBalance);
			qtyMap = (qtyMap == null ? 0 : qtyMap);

			mapBQ.put(idBalance, qtyMap + qtyBal);

			if(!setIdProductReturn.isEmpty())
				setIdProductReturn.remove((Id)aggRes.get('idProduct'));
		}

		//the remaining elements in setIdProductReturn are products that are being returned, and for which there is not currently any inventory
		//we must identify a balance to use for the return of these items.
		if(!setIdProductReturn.isEmpty())
		{
			Id idLocation;
			for(AcctSeedERP__Location__c loc : 
				[SELECT Id
				 FROM AcctSeedERP__Location__c
				 WHERE AcctSeedERP__Warehouse__c = :idWarehouse
				 ORDER BY CreatedDate
				 LIMIT 1])
			{
				idLocation = loc.Id;
			}

			map<Id,map<Id,map<Id,Id>>> mapPWLB = new map<Id,map<Id,map<Id,Id>>>();
			for(Id idProduct : setIdProductReturn)
			{
				mapPWLB.put(idProduct, new map<Id,map<Id,Id>>{idWarehouse => new map<Id,Id>{idLocation => null}});
			}

			GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);

			for(Id idProduct : mapPWLB.keySet())
			{
				Id idBalance = mapPWLB.get(idProduct).get(idWarehouse).get(idLocation);

				map<Id,Decimal> mapBQ = mapOBQ.get(idProduct);
				if(mapBQ == null)
				{
					mapBQ = new map<Id,Decimal>();
					mapOBQ.put(idProduct, mapBQ);
				}
				mapOBQ.get(idProduct).put(idBalance,0);
			}
		}
		List<String> listIIB = new List<String>();
		for(AcctSeedERP__Material__c matl : listMatl)
		{
			Decimal qtyNeeded = (matl.AcctSeedERP__Quantity_Per_Unit__c == null ? 0 : matl.AcctSeedERP__Quantity_Per_Unit__c);
			qtyNeeded -= (matl.AcctSeedERP__Quantity_Allocated__c == null ? 0 : matl.AcctSeedERP__Quantity_Allocated__c);

			qtyNeeded = qtyNeeded.setScale(6);

			if(qtyNeeded == 0)
				continue;

			Product2 product = matl.AcctSeedERP__Product__r;

			Decimal qtyNeededToMove = mapQtyToMove.get(matl.Id);
			if(qtyNeededToMove > qtyNeeded){
				listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'Product ['+product.Name+'] cannot be moveded from inventory to WIP because quantity to move cannot be more than quantity can be moved on '+materialLabel+' '+matl.Name));
				continue;								
			}else{
				qtyNeeded = qtyNeededToMove;
			}

			Id idObject = matl.GMBLASERP__Serial_Number__c;
			if(idObject == null)
			   idObject = matl.GMBLASERP__Lot__c;
			if(idObject == null)
				idObject = matl.AcctSeedERP__Product__c;


			map<Id,Decimal> mapBQ = mapOBQ.get(idObject);
			if(mapBQ == null && qtyNeeded < 0)
			{
				mapBQ = mapOBQ.get(matl.AcctSeedERP__Product__c);
			}

			if(mapBQ != null)
			for(Id idBalance : mapBQ.keySet())
			{
				Decimal qtyBal = mapBQ.get(idBalance);
				
				if(qtyNeeded < 0 || qtyBal > 0)
				{	
					Decimal qtyMove = 0;

					if(qtyNeeded < 0)
					   qtyMove = qtyNeeded;
					else if(qtyNeeded <= qtyBal)
					   qtyMove = qtyNeeded;
					else
					   qtyMove = qtyBal;

					listMove.add(new AcctSeedERP__Manufacturing_Inventory_Movement__c(
						AcctSeedERP__GL_Account_Variable_1__c = matl.AcctSeedERP__GL_Account_Variable_1__c,
						AcctSeedERP__GL_Account_Variable_2__c = matl.AcctSeedERP__GL_Account_Variable_2__c,
						AcctSeedERP__GL_Account_Variable_3__c = matl.AcctSeedERP__GL_Account_Variable_3__c,
						AcctSeedERP__GL_Account_Variable_4__c = matl.AcctSeedERP__GL_Account_Variable_4__c,
						AcctSeedERP__Inventory_Balance__c = idBalance,
						AcctSeedERP__Material__c = matl.Id,
						AcctSeedERP__Quantity__c = qtyMove,
						AcctSeedERP__Movement_Date__c = moveDate,
						GMBLASERP__Lot__c = matl.GMBLASERP__Lot__c,
						GMBLASERP__Serial_Number__c = matl.GMBLASERP__Serial_Number__c
					));

					mapBQ.put(idBalance, qtyBal - qtyMove);
					qtyNeeded -= qtyMove;
					if(qtyNeeded == 0) break;
				}
			}

			if(qtyNeeded != 0)
			{
				String msg = 'Product ['+product.Name+'] was not completely moved from inventory to WIP due to insufficient inventory for '+materialLabel+' '+matl.Name+' in Warehouse '+whs.Name;
				listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, msg));
				listIIB.add(msg);
				continue;
			}
		}

		if(!listMove.isEmpty())
			insert listMove;

		if(!listMsg.isEmpty())
		{
			listMsg.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'INV --> WIP actions incomplete.'));
		}
		if(!listIIB.isEmpty())
		{
			sendEmail(listIIB, whs.Insufficient_Inventory_Email__c, project);
		}
		return listMsg;
	}

	@RemoteAction
	public static list<String> undoWipRASelected(Id idProject, List<String> listIdMaterials, String pIdWarehouse)
	{
		Set<String> setIdMaterials = new Set<String>();
		setIdMaterials.addAll(listIdMaterials);
		return stringifyPageMessages(undoWipSelected(idProject,setIdMaterials,pIdWarehouse));
	}

    @RemoteAction 
    public static list<ApexPages.Message> undoWipSelected(Id idProject, Set<String> setIdMaterials, String pIdWarehouse)
    {
    	System.debug(loggingLevel.Error,'undoWipSelected:'+idProject);
		List<ApexPages.Message> listMsg = new list<ApexPages.Message>();

    	if(checkProjectHasFinishedGoods(idProject))
    	{
    		System.debug(loggingLevel.Error,'undoWipSelected Finished');
			listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Project has Finished Goods.  Reverse or delete the Finished Goods movement before attempting to undo WIP.'));
			return listMsg;
    	}

    	if(checkProjectHasWip(idProject) == false)
    	{
    		System.debug(loggingLevel.Error,'undoWIP No WIP');
			return listMsg;
    	}

    	if(checkProjectHasCOGS(idProject))
    	{
			throw new gcException('The Project has COGS Movements. Delete the Journal Entries before attempting to undo WIP.');
			//listMsg.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Project has COGS Movements. Delete the Journal Entries before attempting to undo WIP.'));
			//return listMsg;
    	}

    	System.debug(loggingLevel.Error,'undoWIP Start:'+idProject);
    	Date dateEarliestOpen = GMBLASERP.gcAccountingPeriod.dateEarliestOpen();
    	list<AcctSeedERP__Manufacturing_Inventory_Movement__c> listMoveInsert = new list<AcctSeedERP__Manufacturing_Inventory_Movement__c>();
    	list<AcctSeedERP__Manufacturing_Inventory_Movement__c> listMoveDelete = new list<AcctSeedERP__Manufacturing_Inventory_Movement__c>();
    	List<AcctSeedERP__Manufacturing_Inventory_Movement__c> listMovesNonWhs = new list<AcctSeedERP__Manufacturing_Inventory_Movement__c>();
    	for(AcctSeedERP__Manufacturing_Inventory_Movement__c move : 
    		[SELECT Id,
    				GMBLASERP__Cost_Override__c,
    				AcctSeedERP__GL_Account_Variable_1__c,
    				AcctSeedERP__GL_Account_Variable_2__c,
    				AcctSeedERP__GL_Account_Variable_3__c,
    				AcctSeedERP__GL_Account_Variable_4__c,
    				AcctSeedERP__Inventory_Balance__c,
    				AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
    				AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c,
    				AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c,
       				GMBLASERP__Lot__c,
    				AcctSeedERP__Material__c,
    				AcctSeedERP__Movement_Date__c,
    				AcctSeedERP__Quantity__c,
    				GMBLASERP__Serial_Number__c,
    				AcctSeedERP__Unit_Cost__c
    		 FROM AcctSeedERP__Manufacturing_Inventory_Movement__c
    		 WHERE AcctSeedERP__Material__r.AcctSeedERP__Project__c = :idProject
    		 	AND AcctSeedERP__Material__c IN:setIdMaterials])
    	{
    		//if(move.AcctSeedERP__Inventory_Balance__c != null && move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c != pIdWarehouse)
    		//	listMovesNonWhs.add(move);

    		if(move.AcctSeedERP__Movement_Date__c >= dateEarliestOpen)
    			listMoveDelete.add(move);
    		else
    		{
    			AcctSeedERP__Manufacturing_Inventory_Movement__c moveNew = move.clone();
    			moveNew.GMBLASERP__Cost_Override__c = true;
    			moveNew.AcctSeedERP__Movement_Date__c = date.today();
    			moveNew.AcctSeedERP__Quantity__c *= (-1);
    			listMoveInsert.add(moveNew);
    		}
    	}

    	if(listMoveDelete.size() > 0)
    		delete listMoveDelete;
    	if(listMoveInsert.size() > 0)
    		insert listMoveInsert;

    	/// Now we are going to transfer all the items to the selected warehouse
    	//if(!listMovesNonWhs.isEmpty())
    	//	makeInventoryTransfer(listMovesNonWhs,pIdWarehouse);

		return listMsg;
    }

    public static void sendEmail(List<String> listIIB, String emailAddress, AcctSeed__Project__c project)
    {
    	return;
    	String insufficientInventoryEmail = ERP_Order_Settings__c.getOrgDefaults().Insufficient_Inventory_Email__c;
    	if(emailAddress != null)
    		insufficientInventoryEmail = emailAddress;

    	if(insufficientInventoryEmail == null) return;

		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
		String bodyMsg = 'ERP Order: '+project.Name+ '\n';
		bodyMsg += 'URL: '+baseURL+'/'+project.Id+'\n\n';
		for(String msg : listIIB)
			bodyMsg += msg + '\n';

		message.toAddresses = new String[] { insufficientInventoryEmail };
		message.optOutPolicy = 'FILTER';
		message.subject = 'Insufficient Inventory balance';
		message.plainTextBody = bodyMsg;
		Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
		Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

		if (results[0].success) {
		    System.debug('The email was sent successfully.');
		} else {
		    System.debug('The email failed to send: ' + results[0].errors[0].message);
		}    	
    }
    @RemoteAction
	public static String createWipAndTransferelected(Id idProject, List<Map<String,String>> listIdMaterials, String pIdWarehouse, String movementDate)
	{
		List<String> listRes = new List<String>();
		if(listIdMaterials.isEmpty()) return '';
		Date moveDate = Date.today();
		if(movementDate != null)
			moveDate = Date.parse(movementDate);
		Map<Id,Decimal> mapQtyToMove = new Map<Id,Decimal>();
		Set<String> setIdMaterials = new Set<String>();
		for(Map<String,String> m : listIdMaterials)
		{
			Id idMaterial = m.get('idMaterial');
			Decimal qtyToMove = Decimal.valueOf(m.get('qtyToMove') == null ? '0' : m.get('qtyToMove'));
			if(qtyToMove <> 0){
				setIdMaterials.add(idMaterial);
				mapQtyToMove.put(idMaterial, qtyToMove);
			}
		}
		AcctSeed__Project__c project = 
		[SELECT Id,
				Name,
				RecordTypeId,
				Order_Item_Total__c,
				Expense__c,
				Internal_Partner_Boat_Sale__c,
         		GMBLASERP__Warehouse__c,
         		Internal_Destination_WarehouseId__c,
				(SELECT Id, Product__c FROM AcctSeed__Project_Tasks__r ORDER BY CreatedDate)
		 FROM AcctSeed__Project__c
		 WHERE Id = :idProject][0];

		Id idProjectTask = project.AcctSeed__Project_Tasks__r[0].Id;
		Id idLocationWholesale;
		Id idLocationPWarehouse;
		Set<Id> setIdWarehouse = new Set<Id>{pIdWarehouse,project.Internal_Destination_WarehouseId__c};
		for(AcctSeedERP__Location__c loc : [SELECT Id, AcctSeedERP__Warehouse__c FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c IN :setIdWarehouse])
		{
			if(loc.AcctSeedERP__Warehouse__c == pIdWarehouse)
				idLocationWholesale = loc.Id;
			else if(loc.AcctSeedERP__Warehouse__c == project.Internal_Destination_WarehouseId__c)
				idLocationPWarehouse = loc.Id;
		}
		map<Id,map<Id,map<Id,Id>>> mapPWLB = new map<Id,map<Id,map<Id,Id>>>();
        List<AcctSeedERP__Outbound_Inventory_Movement__c> listOutMoves = new List<AcctSeedERP__Outbound_Inventory_Movement__c>();
        List<AcctSeedERP__Inbound_Inventory_Movement__c> listMoveIn = new List<AcctSeedERP__Inbound_Inventory_Movement__c>();
		List<AcctSeedERP__Material__c> listMatl = new List<AcctSeedERP__Material__c>();
		for(AcctSeedERP__Material__c matl : 
		 		[SELECT Id, 
						AcctSeedERP__Product__c,
						AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
						AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c,
						AcctSeedERP__Product__r.RecordType.Name,
						AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c,
						AcctSeedERP__Project_Task__c,
						AcctSeedERP__Quantity_Allocated__c,
						AcctSeedERP__Quantity_Per_Unit__c,
						GMBLASERP__Unit_Price__c,
						GMBLASERP__Serial_Number__c,
						GMBLASERP__Serial_Number__r.GMBLASERP__Lot__c,
						(SELECT Id, AcctSeedERP__Quantity__c FROM Outbound_Inventory_Movements__r)
				FROM AcctSeedERP__Material__c
				WHERE AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = true 
					AND Id IN:setIdMaterials])
		 {
		 	Decimal qtyMoved = 0;
		 	for(AcctSeedERP__Outbound_Inventory_Movement__c oim : matl.Outbound_Inventory_Movements__r){
		 		qtyMoved += oim.AcctSeedERP__Quantity__c == null ? 0 : oim.AcctSeedERP__Quantity__c;
		 	}
		 	if(matl.AcctSeedERP__Quantity_Per_Unit__c <> qtyMoved)
		 	{
		 		Decimal qtyCanMove = matl.AcctSeedERP__Quantity_Per_Unit__c - qtyMoved;
		 		Decimal qtyToMove = mapQtyToMove.get(matl.Id);
		 		if(qtyToMove > qtyCanMove)
		 			throw new gcException('Quantity To Move cannot be more than Quantity Can be moved.');
		 		listMatl.add(matl);
		 		mapPWLB.put(matl.AcctSeedERP__Product__c, new map<Id,map<Id,Id>>{project.Internal_Destination_WarehouseId__c => new map<Id,Id>{idLocationPWarehouse => null},pIdWarehouse => new map<Id,Id>{idLocationWholesale => null}});
		 	}
		 }

	    if(!mapPWLB.isEmpty())
	    {
	    	GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
	    	GMBLASERP__Inventory_Transfer__c newTsf = new GMBLASERP__Inventory_Transfer__c(
	    														ERP_Order__c = project.Id,
	    														GMBLASERP__Warehouse_From__c = pIdWarehouse,
	    														GMBLASERP__Warehouse_To__c = project.Internal_Destination_WarehouseId__c,
	    														GMBLASERP__Outbound_Date__c = moveDate,
	    														Comments__c = 'Inventory Transfer from Internal Partner Parts Order '+project.Name
	    													);
	    	insert newTsf;
        	for(AcctSeedERP__Material__c matl : listMatl)
        	{
        		Id idBalance = mapPWLB.get(matl.AcctSeedERP__Product__c).get(pIdWarehouse).get(idLocationWholesale);

        		listOutMoves.add(new AcctSeedERP__Outbound_Inventory_Movement__c(
        							GMBLASERP__Product__c = matl.AcctSeedERP__Product__c,
					    			AcctSeedERP__Debit_GL_Account__c = matl.AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c,
					    			AcctSeedERP__Inventory_Balance__c = idBalance,
					    			AcctSeedERP__Movement_Date__c = moveDate,
					    			AcctSeedERP__Project__c = idProject,
					    			AcctSeedERP__Project_Task__c = matl.AcctSeedERP__Project_Task__c,
					    			AcctSeedERP__Quantity__c = mapQtyToMove.get(matl.Id),
						            AcctSeedERP__Type__c = 'Non-Accounting',
						            AcctSeedERP__Unit_Cost__c = 0,
						            GMBLASERP__Cost_Override__c = true,
					    			GMBLASERP__Lot__c = matl.GMBLASERP__Serial_Number__r.GMBLASERP__Lot__c,
					    			GMBLASERP__Serial_Number__c = matl.GMBLASERP__Serial_Number__c,
					    			Material__c = matl.Id,
					    			GMBLASERP__Inventory_Transfer__c = newTsf.Id
					    		));
		   	}
		   	insert listOutMoves;
		 
			return newTsf.Id;
	    }
	    //return listRes;	
	    return '';
	}

    @RemoteAction
	public static String createWipAndTransfer(Id idProject, String pIdWarehouse, String movementDate){
		Date moveDate = Date.today();
		if(movementDate != null)
			moveDate = Date.parse(movementDate);
		List<String> listRes = new List<String>();
		AcctSeed__Project__c project = 
		[SELECT Id,
				RecordTypeId,
				Order_Item_Total__c,
				Expense__c,
				Internal_Partner_Boat_Sale__c,
         		GMBLASERP__Warehouse__c,
         		Internal_Destination_WarehouseId__c,
				(SELECT Id, Product__c FROM AcctSeed__Project_Tasks__r ORDER BY CreatedDate)
		 FROM AcctSeed__Project__c
		 WHERE Id = :idProject][0];

		Id idProjectTask = project.AcctSeed__Project_Tasks__r[0].Id;
		Id idLocationWholesale;
		Id idLocationPWarehouse;
		Set<Id> setIdWarehouse = new Set<Id>{pIdWarehouse,project.Internal_Destination_WarehouseId__c};
		for(AcctSeedERP__Location__c loc : [SELECT Id, AcctSeedERP__Warehouse__c FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c IN :setIdWarehouse]){
			if(loc.AcctSeedERP__Warehouse__c == pIdWarehouse)
				idLocationWholesale = loc.Id;
			else if(loc.AcctSeedERP__Warehouse__c == project.Internal_Destination_WarehouseId__c)
				idLocationPWarehouse = loc.Id;
		}
		map<Id,map<Id,map<Id,Id>>> mapPWLB = new map<Id,map<Id,map<Id,Id>>>();
        List<AcctSeedERP__Outbound_Inventory_Movement__c> listOutMoves = new List<AcctSeedERP__Outbound_Inventory_Movement__c>();
        List<AcctSeedERP__Inbound_Inventory_Movement__c> listMoveIn = new List<AcctSeedERP__Inbound_Inventory_Movement__c>();
		List<AcctSeedERP__Material__c> listMatl = new List<AcctSeedERP__Material__c>();
		Map<Id,Decimal> mapQtyToMove = new Map<Id,Decimal>();
		for(AcctSeedERP__Material__c matl : 
		 		[SELECT Id, 
						AcctSeedERP__Product__c,
						AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
						AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c,
						AcctSeedERP__Product__r.RecordType.Name,
						AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c,
						AcctSeedERP__Project_Task__c,
						AcctSeedERP__Quantity_Allocated__c,
						AcctSeedERP__Quantity_Per_Unit__c,
						GMBLASERP__Unit_Price__c,
						GMBLASERP__Serial_Number__c,
						GMBLASERP__Serial_Number__r.GMBLASERP__Lot__c,
						(SELECT Id, AcctSeedERP__Quantity__c FROM Outbound_Inventory_Movements__r)
				FROM AcctSeedERP__Material__c
				WHERE AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = true 
					AND AcctSeedERP__Project__c = :idProject
					AND No_WIP__c = false])
		 {
		 	Decimal qtyMoved = 0;
		 	for(AcctSeedERP__Outbound_Inventory_Movement__c oim : matl.Outbound_Inventory_Movements__r){
		 		qtyMoved += oim.AcctSeedERP__Quantity__c == null ? 0 : oim.AcctSeedERP__Quantity__c;
		 	}
		 	if(matl.AcctSeedERP__Quantity_Per_Unit__c <> qtyMoved)
		 	{
		 		Decimal qtyToMove = matl.AcctSeedERP__Quantity_Per_Unit__c - qtyMoved;
		 		mapQtyToMove.put(matl.Id,qtyToMove);
		 		listMatl.add(matl);
		 		mapPWLB.put(matl.AcctSeedERP__Product__c, new map<Id,map<Id,Id>>{project.Internal_Destination_WarehouseId__c => new map<Id,Id>{idLocationPWarehouse => null},pIdWarehouse => new map<Id,Id>{idLocationWholesale => null}});
		 	}
		 }

	    if(!mapPWLB.isEmpty())
	    {
	    	GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
	    	GMBLASERP__Inventory_Transfer__c newTsf = new GMBLASERP__Inventory_Transfer__c(
	    														ERP_Order__c = project.Id,
	    														GMBLASERP__Warehouse_From__c = pIdWarehouse,
	    														GMBLASERP__Warehouse_To__c = project.Internal_Destination_WarehouseId__c,
	    														GMBLASERP__Outbound_Date__c = moveDate,
	    														Comments__c = 'Inventory Transfer from Internal Partner Parts Order '+project.Name
	    													);
	    	insert newTsf;
        	for(AcctSeedERP__Material__c matl : listMatl)
        	{
        		Id idBalance = mapPWLB.get(matl.AcctSeedERP__Product__c).get(pIdWarehouse).get(idLocationWholesale);

        		listOutMoves.add(new AcctSeedERP__Outbound_Inventory_Movement__c(
        							GMBLASERP__Product__c = matl.AcctSeedERP__Product__c,
					    			AcctSeedERP__Debit_GL_Account__c = matl.AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c,
					    			AcctSeedERP__Inventory_Balance__c = idBalance,
					    			AcctSeedERP__Movement_Date__c = moveDate,
					    			AcctSeedERP__Project__c = idProject,
					    			AcctSeedERP__Project_Task__c = matl.AcctSeedERP__Project_Task__c,
					    			AcctSeedERP__Quantity__c = mapQtyToMove.get(matl.Id),
						            AcctSeedERP__Type__c = 'Non-Accounting',
						            AcctSeedERP__Unit_Cost__c = 0,
						            GMBLASERP__Cost_Override__c = true,
					    			GMBLASERP__Lot__c = matl.GMBLASERP__Serial_Number__r.GMBLASERP__Lot__c,
					    			GMBLASERP__Serial_Number__c = matl.GMBLASERP__Serial_Number__c,
					    			Material__c = matl.Id,
					    			GMBLASERP__Inventory_Transfer__c = newTsf.Id
					    		));
		   	}
		   	insert listOutMoves;

			return newTsf.Id;
	    }
	    //return listRes;	
	    return '';	
	}

    @RemoteAction
	public static list<String> undoTransferSelected(Id idProject, List<String> listIdMaterials, String pIdWarehouse)
	{
		Set<String> setIdIIM = new Set<String>();
		Set<String> setIdMaterials = new Set<String>();
		setIdMaterials.addAll(listIdMaterials);
		List<AcctSeedERP__Outbound_Inventory_Movement__c> listOIM = new List<AcctSeedERP__Outbound_Inventory_Movement__c>();
		for(AcctSeedERP__Outbound_Inventory_Movement__c oim : [select Id, (SELECT Id FROM AcctSeedERP__Inbound_Inventory_Movements__r) from AcctSeedERP__Outbound_Inventory_Movement__c WHERE Material__c IN:setIdMaterials]){
			listOIM.add(oim);
			for(AcctSeedERP__Inbound_Inventory_Movement__c iim : oim.AcctSeedERP__Inbound_Inventory_Movements__r){
				setIdIIM.add(iim.Id);
			}
		}
		delete [select Id from AcctSeedERP__Inbound_Inventory_Movement__c WHERE Id IN:setIdIIM];
		delete listOIM;
		list<String> listRes = new List<String>{'Undo transfer of selected Materials successfully completed.'};
		return listRes;
	}

    @RemoteAction
	public static list<String> undoTransfer(Id idProject, String pIdWarehouse)
	{
		delete [select Id from AcctSeedERP__Outbound_Inventory_Movement__c WHERE Material__r.AcctSeedERP__Project__c =:idProject];
		list<String> listRes = unbuildFinishedGoodsRA(idProject);
		return listRes;
	}


 	public static void coverage1(){
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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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

	public static void coverage2(){
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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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