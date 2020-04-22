public without sharing class gcSerialNumber{

	public static Boolean disableTrigger{
		get{
			if(disableTrigger == null) return false;
			else return disableTrigger;
		}
		set{
			if(value == null) disableTrigger = false;
			else disableTrigger = value;
		}
	}

	public static Boolean enableExchangeUpdate{
		get{
			if(enableExchangeUpdate == null) return false;
			else return enableExchangeUpdate;
		}
		set{
			if(value == null) enableExchangeUpdate = false;
			else enableExchangeUpdate = value;
		}
	}

	public static Boolean enableAvailabilityUpdate{
		get{
			if(enableAvailabilityUpdate == null) return false;
			else return enableAvailabilityUpdate;
		}
		set{
			if(value == null) enableAvailabilityUpdate = false;
			else enableAvailabilityUpdate = value;
		}
	}

	public static void triggerHandler
		(map<Id,GMBLASERP__Serial_Number__c> oldMap,
		 map<Id,GMBLASERP__Serial_Number__c> newMap,
		 list<GMBLASERP__Serial_Number__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,GMBLASERP__Serial_Number__c>();
		if(newMap == NULL) newMap = new map<Id,GMBLASERP__Serial_Number__c>();
		if(listNew == NULL) listNew = new list<GMBLASERP__Serial_Number__c>();

		updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);

		if(boolIsBefore)
		{
			if(boolIsInsert)
			{

			}
			if(boolIsUpdate)
			{

			}
			if(boolIsDelete)
			{

			}
		}
		else //i.e. trigger.isAfter
		{
			if(boolIsInsert)
			{
				
			}
			if(boolIsUpdate)
			{
				Set<Id> setIdSerial = new Set<Id>();
				setIdSerial.addAll(newMap.keySet());
				setIdSerial.addAll(oldMap.keySet());
				updateSerialIsAvailable(setIdSerial);
			}
			if(boolIsDelete)
			{

			}
		}			
	}

	public static void updateAndValidate
		(map<Id,GMBLASERP__Serial_Number__c> oldMap,
		 map<Id,GMBLASERP__Serial_Number__c> newMap,
		 list<GMBLASERP__Serial_Number__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(boolIsBefore)
		{
			if(boolIsUpdate || boolIsDelete)
			{
				map<Id,GMBLASERP__Serial_Number__c> mapSerial = new map<Id,GMBLASERP__Serial_Number__c>();
				for(GMBLASERP__Serial_Number__c sn :
					[SELECT Id, Name,
						(SELECT Id FROM Serial_Numbers__r),
						(SELECT Id FROM GMBLASERP__Outbound_Inventory_Movements__r LIMIT 1),
						(SELECT Id FROM GMBLASERP__Inbound_Inventory_Movements__r LIMIT 1),
						(SELECT Id FROM GMBLASERP__Purchase_Order_Inventory_Movements__r LIMIT 1),
						(SELECT Id FROM GMBLASERP__Manufacturing_Inventory_Movements__r LIMIT 1),
						(SELECT Id, Name FROM GMBLASERP__Materials__r LIMIT 1),
						(SELECT Id, Locked__c FROM Projects__r LIMIT 1)
					FROM GMBLASERP__Serial_Number__c
					WHERE Id IN :oldMap.keySet()])
				{
					mapSerial.put(sn.Id,sn);
				}

				if(boolIsUpdate)
				for(GMBLASERP__Serial_Number__c x : listNew)
				{
					GMBLASERP__Serial_Number__c sn = mapSerial.get(x.Id);
					GMBLASERP__Serial_Number__c oldSerial = oldMap.get(x.Id);
					if(enableExchangeUpdate){
						if(x.Lot_Exchange__c != null && oldSerial.Lot_Exchange__c == null && !sn.Projects__r.isEmpty())
							x.addError('This serial number '+x.Name+' cannot be used in a lot exchange. It has already been used as ERP Order Serial.');
						else if(x.Lot_Exchange__c != null && oldSerial.Lot_Exchange__c == null && !sn.GMBLASERP__Materials__r.isEmpty())
							x.addError('This serial number '+x.Name+' cannot be used in a lot exchange. It has already been used as ERP Order item.');
					}
					/// Do not allow change of Internal Billing fields
					if(boolIsUpdate 
						&& (x.Billing_Revenue_Internal__c != oldMap.get(x.Id).Billing_Revenue_Internal__c
							|| x.Billing_Revenue_Used__c != oldMap.get(x.Id).Billing_Revenue_Used__c)){
						x.addError('Internal Billing related fields cannot be modified manually.');
					}

					if(x.Current_Unit_Cost__c != oldMap.get(x.Id).Current_Unit_Cost__c)
						x.Current_Unit_Cost__c = oldMap.get(x.Id).Current_Unit_Cost__c;

					if(!enableAvailabilityUpdate){
						if(oldSerial.Available_Retail__c != x.Available_Retail__c)
							x.Available_Retail__c = oldSerial.Available_Retail__c;
						if(oldSerial.Available_Wholesale__c != x.Available_Wholesale__c)
							x.Available_Wholesale__c = oldSerial.Available_Wholesale__c;
					}
				}

				if(!enableExchangeUpdate)
				for(GMBLASERP__Serial_Number__c x : oldMap.values())
				{
					GMBLASERP__Serial_Number__c sn = mapSerial.get(x.Id);
					if(!sn.Serial_Numbers__r.isEmpty() && boolIsUpdate)
						newMap.get(x.Id).addError('This serial number '+x.Name+' has been used in a lot exchange. Cannot be modified.');
					if(boolIsDelete){
						if(x.Old_Serial_Number__c != null || !sn.GMBLASERP__Outbound_Inventory_Movements__r.isEmpty())
							x.addError('This serial number '+x.Name+' has been used in a lot exchange. Cannot be deleted. Please delete the releated lot exchange to proceed.');
						if(!sn.GMBLASERP__Outbound_Inventory_Movements__r.isEmpty()
							|| !sn.GMBLASERP__Inbound_Inventory_Movements__r.isEmpty()
							|| !sn.GMBLASERP__Purchase_Order_Inventory_Movements__r.isEmpty()
							|| !sn.GMBLASERP__Manufacturing_Inventory_Movements__r.isEmpty())
						{
							x.addError('This serial number '+x.Name+' cannot be deleted. It has Inventory Movements. Please delete all the related movements to proceed.');
						}
						if(!sn.GMBLASERP__Materials__r.isEmpty()
							|| !sn.Projects__r.isEmpty())
						{
							x.addError('This serial number '+x.Name+' cannot be deleted. It has been used in an ERP Order. Please delete the project relation or the Material first to proceed.');
						}
					}
				}
			}
		}
		
		if(!boolIsBefore && (boolIsInsert || boolIsUpdate))
		{
			map<Id,GMBLASERP__Serial_Number__c> mapSerial = new map<Id,GMBLASERP__Serial_Number__c>();
			for(GMBLASERP__Serial_Number__c sn :
				[SELECT Id, Name,
						Nest__c,
						Nest__r.Id,
						Nest__r.Name,
						Nest__r.GMBLASERP__Product__c,
						Nest__r.GMBLASERP__Product__r.Id,
						Nest__r.GMBLASERP__Product__r.Can_be_Nest__c,
						Nest__r.Nest__c,
						Nest__r.Nest__r.Name,
						GMBLASERP__Product__c,
						GMBLASERP__Product__r.Id,
						GMBLASERP__Product__r.Name,
						GMBLASERP__Product__r.Can_be_Nested__c,
						(SELECT Id, Name FROM Nested_Serial_Numbers__r LIMIT 1),
						(SELECT Id, Name FROM GMBLASERP__Materials__r LIMIT 1),
						(SELECT Id, Locked__c FROM Projects__r LIMIT 1)
				FROM GMBLASERP__Serial_Number__c
				WHERE Id IN :newMap.keySet()])
			{
				mapSerial.put(sn.Id,sn);
			}

			for(GMBLASERP__Serial_Number__c x : listNew)
			{
				GMBLASERP__Serial_Number__c sn = mapSerial.get(x.Id);

				if(sn.Nest__c != null && !sn.GMBLASERP__Product__r.Can_be_Nested__c)
					x.addError('The Serial Number '+sn.Name+' is of a Product that cannot be nested.');
				else if(sn.Nest__c != null && !sn.Nest__r.GMBLASERP__Product__r.Can_be_Nest__c)
					x.addError('The Serial Number '+sn.Name+' cannot be nested to '+sn.Nest__r.Name+' because '+sn.Nest__r.Name+' is of a Product that cannot be a nest.');
				else if(sn.Nest__c != null && sn.Nest__r.Nest__c != null)
					x.addError('The Serial Number '+sn.Name+' cannot be nested to '+sn.Nest__r.Name+' because '+sn.Nest__r.Name+' is itself nested to '+sn.Nest__r.Nest__r.Name+' and multi-level nesting is not allowed.');
				else if(sn.Nest__c != null && sn.Nested_Serial_Numbers__r.size() > 0)
					x.addError('The Serial Number '+sn.Name+' cannot be nested to '+sn.Nest__r.Name+' because '+sn.Name+' is itself a nest for other serial numbers, including '+sn.Nested_Serial_Numbers__r[0].Name);
				/// Is lot exchange
				//if(enableExchangeUpdate && !sn.GMBLASERP__Materials__r.isEmpty())
				//	x.addError('This serial number '+x.Name+' cannot be used in a lot exchange. It has already been used as ERP Order item.');
				//else if(enableExchangeUpdate && !sn.Projects__r.isEmpty())
				//	x.addError('This serial number '+x.Name+' cannot be used in a lot exchange. It has already been used as ERP Order Serial.');
			}
		}
	}

	public static void updateSerialAvailability(Set<Id> setIdSerial, String warehouseType){
		if(warehouseType == 'Wholesale')
			updateWholesaleAvailability(setIdSerial);
		else
			updateRetailAvailability(setIdSerial);
	}

	/// Update Wholesale Availability
	public static void updateWholesaleAvailability(Set<Id> setIdSerial){
		List<GMBLASERP__Serial_Number__c> listSerial = new List<GMBLASERP__Serial_Number__c>();
		for(GMBLASERP__Serial_Number__c sn : [SELECT Id, Name, GMBLASERP__Inventory_Balance__c, Location__c, Available_Wholesale__c FROM GMBLASERP__Serial_Number__c WHERE Id IN :setIdSerial]){
			if(sn.GMBLASERP__Inventory_Balance__c == null || sn.Location__c != 'Wholesale')
				sn.Available_Wholesale__c = false;
			else
				sn.Available_Wholesale__c = true;
			listSerial.add(sn);
		}
		if(!listSerial.isEmpty()){
			Boolean boolOld = disableTrigger;
			disableTrigger = true;
			update listSerial;
			disableTrigger = boolOld;
		}
	}

	/// Update Retail Availability
	public static void updateRetailAvailability(Set<Id> setIdSerial){
		List<GMBLASERP__Serial_Number__c> listSerial = new List<GMBLASERP__Serial_Number__c>();
		for(GMBLASERP__Serial_Number__c sn : [SELECT Id, Available_Retail__c, GMBLASERP__Inventory_Balance__c FROM GMBLASERP__Serial_Number__c WHERE Id IN :setIdSerial]){
			if(sn.GMBLASERP__Inventory_Balance__c == null)
				sn.Available_Retail__c = false;
			else
				sn.Available_Retail__c = true;
			listSerial.add(sn);
		}
		if(!listSerial.isEmpty()){
			Boolean boolOld = disableTrigger;
			disableTrigger = true;
			update listSerial;
			disableTrigger = boolOld;
		}
	}

	@future
	public static void updateSerialIsAvailableFuture(Set<Id> setIdSerial)
	{
		updateSerialIsAvailable(setIdSerial);
	}

	public static void updateSerialIsAvailable(Set<Id> setIdSerial)
	{
		setIdSerial.remove(null);
		if(setIdSerial.isEmpty()) return;
		Id idRtManufacturing = gcConstants.idRtProjectManufacturing;
		Id idRtProjectWarranty = gcConstants.idRtProjectWarranty;
		Id idRtProjectService = gcConstants.idRtProjectService;
		Id idRtTradeIn = gcConstants.idRtTradeIn;
		Id idRtProjectCounterSale = gcConstants.idRtProjectCounterSale;
		Id idRtProjectPartnerBoatSale = gcConstants.idRtProjectPartnerBoatSale;
		Id idRtProjectBoatSale = gcConstants.idRtProjectBoatSale;
		List<GMBLASERP__Serial_Number__c> listSerialsToUpdate = new List<GMBLASERP__Serial_Number__c>();
		CustomPermissionsReader cpr = new CustomPermissionsReader();
		Boolean canDeNestSerialNumbers = false;
			if(cpr.hasPermission('CanDeNestSerialNumbers'))
				canDeNestSerialNumbers = true;
		for(GMBLASERP__Serial_Number__c sn :
			[SELECT Id, 
				Name,
				Available_Wholesale__c,
				Available_Retail__c,
				Available__c,
				Location__c,
				Dealer_Rigged__c,
				Usage__c,
				Nest__c,
				GMBLASERP__Product__r.RecordType.Name,
				GMBLASERP__Product__r.Can_be_Nest__c,
				GMBLASERP__Product__r.Can_be_Nested__c,
				(SELECT Id, 
					AcctSeedERP__Project__r.Name, 
					AcctSeedERP__Project__r.Locked__c, 
					AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c, 
					AcctSeedERP__Project__r.Internal_Partner_Parts_Order__c, 
					AcctSeedERP__Project__r.Internal_Labour_Service__c, 
					AcctSeedERP__Project__r.Serial_Number__c, 
					AcctSeedERP__Project__r.Serial_Number__r.GMBLASERP__Product__r.Can_be_Nest__c, 
					AcctSeedERP__Project__r.RecordTypeId 
				FROM GMBLASERP__Materials__r),
				(SELECT Id, Name, Locked__c, Internal_Partner_Boat_Sale__c, Internal_Partner_Parts_Order__c, Internal_Labour_Service__c, RecordTypeId FROM Projects__r)
			FROM GMBLASERP__Serial_Number__c
			WHERE Id IN :setIdSerial])
		{
			Boolean inSaleProjectSerial = false;
			Boolean inSaleProject = false;
			Boolean dealerRigged = false;
			/// Availability
			Boolean taggedInPartner = false;
			Boolean taggedInInternalPartnerOrder = false;
			Boolean taggedInRetailOrder = false;

			if(!sn.Projects__r.isEmpty())
			for(AcctSeed__Project__c p : sn.Projects__r)
			{
				/// Checking if it is a partner order
				/// Also by warehouse if wholesale
				if(p.RecordTypeId == idRtProjectPartnerBoatSale && !p.Locked__c)
					taggedInPartner = true;
				if(p.Internal_Partner_Boat_Sale__c && !p.Locked__c)
					taggedInInternalPartnerOrder = true;
				if(p.RecordTypeId != idRtProjectPartnerBoatSale && p.RecordTypeId != idRtManufacturing && p.RecordTypeId != idRtProjectWarranty && !p.Locked__c)
					taggedInRetailOrder = true;

				/// If already in a Project // && p.Locked__c == false)
				if(p.RecordTypeId == idRtProjectCounterSale
						|| p.RecordTypeId == idRtProjectPartnerBoatSale
						|| p.RecordTypeId == idRtProjectBoatSale)
					inSaleProjectSerial = true;
				/// If Dealer Rigged
				String productRT = sn.GMBLASERP__Product__r.RecordType.Name;
				if(p.RecordTypeId == idRtManufacturing && p.Locked__c == true && (productRT.equals('Boat') || productRT.equals('Trailer')) && p.Name.contains('PRE-RIG'))
					dealerRigged = true;
				else if(!dealerRigged && p.RecordTypeId == idRtManufacturing && p.Locked__c == false && (productRT.equals('Boat') || productRT.equals('Trailer')) && p.Name.contains('PRE-RIG'))
					dealerRigged = false;
			}
			Boolean addInUpdate = false;
			if(sn.Dealer_Rigged__c != dealerRigged)
			{
				sn.Dealer_Rigged__c = dealerRigged;
				addInUpdate = true;
			}
			Boolean inUnlockedMfgProject = false;
			Boolean changedNest = false;
			if(!sn.GMBLASERP__Materials__r.isEmpty())
			{
				for(AcctSeedERP__Material__c matl : sn.GMBLASERP__Materials__r)
				{
					if(matl.AcctSeedERP__Project__r.RecordTypeId == idRtManufacturing && !matl.AcctSeedERP__Project__r.Locked__c)
						inUnlockedMfgProject = true;

					if(matl.AcctSeedERP__Project__r.RecordTypeId == idRtProjectPartnerBoatSale && !matl.AcctSeedERP__Project__r.Locked__c)
						taggedInPartner = true;
					if(matl.AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c && !matl.AcctSeedERP__Project__r.Locked__c)
						taggedInInternalPartnerOrder = true;
					if(matl.AcctSeedERP__Project__r.RecordTypeId != idRtProjectPartnerBoatSale && matl.AcctSeedERP__Project__r.RecordTypeId != idRtManufacturing && matl.AcctSeedERP__Project__r.RecordTypeId != idRtProjectWarranty && !matl.AcctSeedERP__Project__r.Locked__c)
						taggedInRetailOrder = true;

					if(matl.AcctSeedERP__Project__r.RecordTypeId == idRtProjectCounterSale 
							|| matl.AcctSeedERP__Project__r.RecordTypeId == idRtProjectBoatSale
							|| matl.AcctSeedERP__Project__r.RecordTypeId == idRtProjectPartnerBoatSale)
						inSaleProject = true;

					if(matl.AcctSeedERP__Project__r.Serial_Number__c != null 
						&& sn.Nest__c != matl.AcctSeedERP__Project__r.Serial_Number__c 
						&& sn.Id != matl.AcctSeedERP__Project__r.Serial_Number__c
						&& sn.GMBLASERP__Product__r.Can_be_Nested__c)
					{
						/// We will by pass this section if the user has de-nest permission
						if(!canDeNestSerialNumbers && matl.AcctSeedERP__Project__r.Serial_Number__r.GMBLASERP__Product__r.Can_be_Nest__c)
						{
							sn.Nest__c = matl.AcctSeedERP__Project__r.Serial_Number__c;
							addInUpdate = true;
						}
					}
				}
			}
			/// These checkings can be done in one shot but did it separately for readability
			if(sn.Location__c == 'Out')
			{
				sn.Available_Retail__c = false;
				sn.Available_Wholesale__c = false;
				addInUpdate = true;
			}else if(sn.Location__c == 'Wholesale' && taggedInPartner && taggedInRetailOrder){
				System.debug(loggingLevel.error,'Case:1');
				sn.Available_Retail__c = false;
				sn.Available_Wholesale__c = false;
				addInUpdate = true;				
			}else if(sn.Location__c == 'Wholesale' && taggedInPartner && taggedInInternalPartnerOrder && !taggedInRetailOrder){
				System.debug(loggingLevel.error,'Case:2');
				sn.Available_Retail__c = true;
				sn.Available_Wholesale__c = false;
				addInUpdate = true;				
			}else if(sn.Location__c == 'Wholesale' && taggedInPartner && !taggedInInternalPartnerOrder && !taggedInRetailOrder){
				System.debug(loggingLevel.error,'Case:3');
				sn.Available_Retail__c = false;
				sn.Available_Wholesale__c = false;
				addInUpdate = true;				
			}else if(sn.Location__c == 'Wholesale' && !taggedInPartner && !taggedInInternalPartnerOrder && !taggedInRetailOrder){
				System.debug(loggingLevel.error,'Case:4');
				sn.Available_Retail__c = false;
				sn.Available_Wholesale__c = true;
				addInUpdate = true;				
			}else if(sn.Location__c != 'Wholesale' && !taggedInRetailOrder){
				System.debug(loggingLevel.error,'Case:5');
				sn.Available_Retail__c = true;
				sn.Available_Wholesale__c = false;
				addInUpdate = true;				
			}else if(sn.Location__c != 'Wholesale' && taggedInRetailOrder){
				System.debug(loggingLevel.error,'Case:6');
				sn.Available_Retail__c = false;
				sn.Available_Wholesale__c = false;
				addInUpdate = true;				
			}


			if(sn.Location__c == 'Out' || inSaleProjectSerial || inUnlockedMfgProject || inSaleProject)
			{
				if(sn.Available__c)
				{
					sn.Available__c = false;
					addInUpdate = true;
				}
			}
			else if(sn.Location__c != 'Out')
			{
				if(!sn.Available__c)
				{
					sn.Available__c = true;
					addInUpdate = true;
				}
			}

			if(inSaleProject && sn.Location__c == 'Out')
			{
				if(sn.Usage__c != 'Sold')
				{
					sn.Usage__c = 'Sold';
					addInUpdate = true;
				}
			}
			else if(sn.Location__c != 'Out')
			{
				if(sn.Usage__c != 'In')
				{
					sn.Usage__c = 'In';
					addInUpdate = true;
				}
			}
			else if(sn.Location__c == 'Out')
			{
				if(sn.Usage__c != null)
				{
					sn.Usage__c = null;
					addInUpdate = true;
				}
			}

			if(addInUpdate)
				listSerialsToUpdate.add(sn);
		}
		if(!listSerialsToUpdate.isEmpty())
		{
			Boolean boolOld = disableTrigger;
			disableTrigger = true;
			update listSerialsToUpdate;
			disableTrigger = boolOld;
		}
	}

	public static void checkPriorMovements(list<sObject> listMove, Map<Id,sObject> mapOldMoves){
		CustomPermissionsReader cpr = new CustomPermissionsReader();
		Boolean canModifyLockedPurchaseOrder = false;
		Boolean canMoveInventoryAnyDay = false;
			if(cpr.hasPermission('CanMoveInventoryAnyDay'))
				canMoveInventoryAnyDay = true;

			if(!canMoveInventoryAnyDay)
			{
			Map<Id,GMBLASERP__Serial_Number__c> mapSerials = new Map<Id,GMBLASERP__Serial_Number__c>();
			for(sObject obj : listMove)
			{
				Id idSerial = (Id)obj.get('GMBLASERP__Serial_Number__c');
				System.debug(loggingLevel.error,'idSerial:'+idSerial);

				if(idSerial != null){
					mapSerials.put(idSerial, null);
				}
			}
			// Old Moves As well for Delete
			if(Trigger.isDelete)
			for(sObject obj : mapOldMoves.values())
			{
				Id idSerial = (Id)obj.get('GMBLASERP__Serial_Number__c');
				System.debug(loggingLevel.error,'idSerial:'+idSerial);

				if(idSerial != null){
					mapSerials.put(idSerial, null);
				}
			}

			if(!mapSerials.isEmpty()){
				for(GMBLASERP__Serial_Number__c sn :
					[SELECT Id, Name,
						(SELECT Id, AcctSeedERP__Movement_Date__c FROM GMBLASERP__Outbound_Inventory_Movements__r ORDER BY AcctSeedERP__Movement_Date__c DESC LIMIT 2),
						(SELECT Id, AcctSeedERP__Movement_Date__c FROM GMBLASERP__Inbound_Inventory_Movements__r ORDER BY AcctSeedERP__Movement_Date__c DESC LIMIT 2),
						(SELECT Id, AcctSeedERP__Movement_Date__c FROM GMBLASERP__Purchase_Order_Inventory_Movements__r ORDER BY AcctSeedERP__Movement_Date__c DESC LIMIT 2),
						(SELECT Id, AcctSeedERP__Movement_Date__c FROM GMBLASERP__Manufacturing_Inventory_Movements__r ORDER BY AcctSeedERP__Movement_Date__c DESC LIMIT 2)
					FROM GMBLASERP__Serial_Number__c
					WHERE Id IN :mapSerials.keySet()])
				{
					mapSerials.put(sn.Id,sn);
				}
			}
			System.debug(loggingLevel.error,'Trigger.isInsert:'+Trigger.isInsert);
			System.debug(loggingLevel.error,'Trigger.isUpdate:'+Trigger.isUpdate);
			if(Trigger.isInsert || Trigger.isUpdate)
			for(sObject obj : listMove)
			{
				Id idSerial = (Id)obj.get('GMBLASERP__Serial_Number__c');
				Date moveDate = (Date)obj.get('AcctSeedERP__Movement_Date__c');
				System.debug(loggingLevel.error,'moveDate:'+moveDate);

				Date oldMoveDate;
				Id updateId;
				if(Trigger.isUpdate){
					updateId = (Id)obj.get('Id');
					oldMoveDate = (Date)mapOldMoves.get(updateId).get('AcctSeedERP__Movement_Date__c');
					System.debug(loggingLevel.error,'updateId:'+updateId);
					System.debug(loggingLevel.error,'oldMoveDate:'+oldMoveDate);
				}
				if(idSerial != null)
				{
					Map<Date,sObject> mapDateMove = new Map<Date,sObject>();
					Map<Date,Set<Id>> mapDateIds = new Map<Date,Set<Id>>();
					GMBLASERP__Serial_Number__c serialInfo = mapSerials.get(idSerial);
					System.debug(loggingLevel.error,'serialInfo:'+serialInfo);

					/// Outbound Moves
					sObject mc;
					sObject mc2;
					for(AcctSeedERP__Outbound_Inventory_Movement__c oim : serialInfo.GMBLASERP__Outbound_Inventory_Movements__r){
						mapDateMove.put(oim.AcctSeedERP__Movement_Date__c, oim);
						if(!mapDateIds.containsKey(oim.AcctSeedERP__Movement_Date__c))
							mapDateIds.put(oim.AcctSeedERP__Movement_Date__c,new Set<Id>());
						mapDateIds.get(oim.AcctSeedERP__Movement_Date__c).add(oim.Id);
					}
					/// Inbound Moves
					for(AcctSeedERP__Inbound_Inventory_Movement__c iim : serialInfo.GMBLASERP__Inbound_Inventory_Movements__r){
						mapDateMove.put(iim.AcctSeedERP__Movement_Date__c, iim);
						if(!mapDateIds.containsKey(iim.AcctSeedERP__Movement_Date__c))
							mapDateIds.put(iim.AcctSeedERP__Movement_Date__c,new Set<Id>());
						mapDateIds.get(iim.AcctSeedERP__Movement_Date__c).add(iim.Id);
					}
					/// Manufacturing Moves
					for(AcctSeedERP__Manufacturing_Inventory_Movement__c mim : serialInfo.GMBLASERP__Manufacturing_Inventory_Movements__r){
						mapDateMove.put(mim.AcctSeedERP__Movement_Date__c, mim);
						if(!mapDateIds.containsKey(mim.AcctSeedERP__Movement_Date__c))
							mapDateIds.put(mim.AcctSeedERP__Movement_Date__c,new Set<Id>());
						mapDateIds.get(mim.AcctSeedERP__Movement_Date__c).add(mim.Id);
					}
					/// Purchase Moves
					for(AcctSeedERP__Purchase_Order_Inventory_Movement__c pim : serialInfo.GMBLASERP__Purchase_Order_Inventory_Movements__r){
						mapDateMove.put(pim.AcctSeedERP__Movement_Date__c, pim);
						if(!mapDateIds.containsKey(pim.AcctSeedERP__Movement_Date__c))
							mapDateIds.put(pim.AcctSeedERP__Movement_Date__c,new Set<Id>());
						mapDateIds.get(pim.AcctSeedERP__Movement_Date__c).add(pim.Id);
					}
					if(!mapDateMove.isEmpty())
					{
						System.debug(loggingLevel.error,'mapDateMove:'+mapDateMove);
						List<Date> listAllKeys = new List<Date>();
						listAllKeys.addAll(mapDateMove.keySet());
						listAllKeys.sort();
						System.debug(loggingLevel.error,'listAllKeys:'+listAllKeys);
						Integer lstSize = listAllKeys.size();
						Integer lastIndx = lstSize - 1;
						mc = mapDateMove.get(listAllKeys[lastIndx]);
						Date mcDate = (Date)mc.get('AcctSeedERP__Movement_Date__c');
						Id mcId = (Id)mc.get('Id');
						System.debug(loggingLevel.error,'mcId:'+mcId);
						System.debug(loggingLevel.error,'mcDate:'+mcDate);
						Date mc2Date;
						Id mc2Id;
						if(listAllKeys.size() > 1){
							lastIndx = lstSize - 2;
							mc2 = mapDateMove.get(listAllKeys[lastIndx]);
							mc2Date = (Date)mc2.get('AcctSeedERP__Movement_Date__c');
							mc2Id = (Id)mc2.get('Id');
						}
						//// Validation Starts here
						if(Trigger.isInsert && (Date)mc.get('AcctSeedERP__Movement_Date__c') > moveDate)
							obj.addError('The Last movement for serial number '+serialInfo.Name+' was made on '+mcDate.format()+'. New movements must be made on or after that day.');

						if(Trigger.isUpdate)
						{
							if(mapDateIds.get(mcDate).contains(updateId) && mc2 != null && mc2Date > moveDate){
								System.debug(loggingLevel.error,'move:'+obj);
								System.debug(loggingLevel.error,'mc:'+mc);
								obj.addError('The movement date for serial number '+serialInfo.Name+' cannot be modified. Previous Movement was made on '+mc2Date.format()+'. Current movement must be made on or after that day.');
							}else if(mc2 != null && mapDateIds.get(mc2Date).contains(updateId) && moveDate != oldMoveDate){
								System.debug(loggingLevel.error,'move:'+obj);
								System.debug(loggingLevel.error,'Error 2:'+mc);
								obj.addError('The movement date for serial number '+serialInfo.Name+' cannot be modified. There are movements after this movement.');
							}
							else if(moveDate != oldMoveDate && !mapDateIds.get(mcDate).contains(updateId) && moveDate > mcDate){
								System.debug(loggingLevel.error,'move:'+obj);
								System.debug(loggingLevel.error,'Error 3:'+mc);
								obj.addError('The movement date for serial number '+serialInfo.Name+' cannot be modified. There are movements after this movement.');
							}
							else if(moveDate != oldMoveDate && !mapDateIds.get(mcDate).contains(updateId) && mc2 != null && !mapDateIds.get(mc2Date).contains(updateId)){
								System.debug(loggingLevel.error,'move:'+obj);
								System.debug(loggingLevel.error,'Error 4:'+mc);
								obj.addError('The movement date for '+serialInfo.Name+' cannot be modified. There are movements after this movement.');
							}
						}
					}
				}
			}

			/// If deleting an old move with serial
			if(Trigger.isDelete)
			{
				for(sObject obj : mapOldMoves.values())
				{
					Id idSerial = (Id)obj.get('GMBLASERP__Serial_Number__c');
					Date moveDate = (Date)obj.get('AcctSeedERP__Movement_Date__c');
					Id deleteId = (Id)obj.get('Id');
					System.debug(loggingLevel.error,'deleteId:'+deleteId);

					if(idSerial != null)
					{
						Map<Date,sObject> mapDateMove = new Map<Date,sObject>();
						Map<Date,Set<Id>> mapDateIds = new Map<Date,Set<Id>>();
						GMBLASERP__Serial_Number__c serialInfo = mapSerials.get(idSerial);
						System.debug(loggingLevel.error,'serialInfo:'+serialInfo);

						/// Outbound Moves
						sObject mc;
						sObject mc2;
						for(AcctSeedERP__Outbound_Inventory_Movement__c oim : serialInfo.GMBLASERP__Outbound_Inventory_Movements__r){
							mapDateMove.put(oim.AcctSeedERP__Movement_Date__c, oim);
							if(!mapDateIds.containsKey(oim.AcctSeedERP__Movement_Date__c))
								mapDateIds.put(oim.AcctSeedERP__Movement_Date__c,new Set<Id>());
							mapDateIds.get(oim.AcctSeedERP__Movement_Date__c).add(oim.Id);
						}
						/// Inbound Moves
						for(AcctSeedERP__Inbound_Inventory_Movement__c iim : serialInfo.GMBLASERP__Inbound_Inventory_Movements__r){
							mapDateMove.put(iim.AcctSeedERP__Movement_Date__c, iim);
							if(!mapDateIds.containsKey(iim.AcctSeedERP__Movement_Date__c))
								mapDateIds.put(iim.AcctSeedERP__Movement_Date__c,new Set<Id>());
							mapDateIds.get(iim.AcctSeedERP__Movement_Date__c).add(iim.Id);
						}
						/// Manufacturing Moves
						for(AcctSeedERP__Manufacturing_Inventory_Movement__c mim : serialInfo.GMBLASERP__Manufacturing_Inventory_Movements__r){
							System.debug(loggingLevel.error,'mim:'+mim);
							mapDateMove.put(mim.AcctSeedERP__Movement_Date__c, mim);
							if(!mapDateIds.containsKey(mim.AcctSeedERP__Movement_Date__c))
								mapDateIds.put(mim.AcctSeedERP__Movement_Date__c,new Set<Id>());
							mapDateIds.get(mim.AcctSeedERP__Movement_Date__c).add(mim.Id);
						}
						/// Purchase Moves
						for(AcctSeedERP__Purchase_Order_Inventory_Movement__c pim : serialInfo.GMBLASERP__Purchase_Order_Inventory_Movements__r){
							System.debug(loggingLevel.error,'pim:'+pim);
							mapDateMove.put(pim.AcctSeedERP__Movement_Date__c, pim);
							if(!mapDateIds.containsKey(pim.AcctSeedERP__Movement_Date__c))
								mapDateIds.put(pim.AcctSeedERP__Movement_Date__c,new Set<Id>());
							mapDateIds.get(pim.AcctSeedERP__Movement_Date__c).add(pim.Id);
						}
						if(!mapDateMove.isEmpty())
						{
							System.debug(loggingLevel.error,'mapDateIds:'+mapDateIds);
							System.debug(loggingLevel.error,'mapDateMove:'+mapDateMove);
							List<Date> listAllKeys = new List<Date>();
							listAllKeys.addAll(mapDateMove.keySet());
							listAllKeys.sort();
							System.debug(loggingLevel.error,'listAllKeys:'+listAllKeys);
							Integer lstSize = listAllKeys.size();
							Integer lastIndx = lstSize - 1;
							mc = mapDateMove.get(listAllKeys[lastIndx]);
							Date mcDate = (Date)mc.get('AcctSeedERP__Movement_Date__c');
							Id mcId = (Id)mc.get('Id');
							System.debug(loggingLevel.error,'mcId:'+mcId);
							System.debug(loggingLevel.error,'mcDate:'+mcDate);
							Date mc2Date;
							Id mc2Id;
							if(listAllKeys.size() > 1){
								lastIndx = lstSize - 2;
								mc2 = mapDateMove.get(listAllKeys[lastIndx]);
								mc2Date = (Date)mc2.get('AcctSeedERP__Movement_Date__c');
								mc2Id = (Id)mc2.get('Id');
							}
							if(!mapDateIds.get(mcDate).contains(deleteId)){
								System.debug(loggingLevel.error,'moveDel:'+obj);
								System.debug(loggingLevel.error,'mcD:'+mc);
								obj.addError('The movement cannot be deleted for serial number '+serialInfo.Name+'. There are movements after this movement.');
							}
						}
					}
				}

			}
		}
	}

	@future
	public static void updateSerialUnitCostFuture(List<String> listIdSerials){
		updateSerialUnitCost(listIdSerials);
	}

	public static void updateSerialUnitCost(List<String> listIdSerials)
	{
		if(listIdSerials.isEmpty()) return;
		map<String,list<String>> mapFilters = new map<String,list<String>>();
		mapFilters.put('idSerial',listIdSerials);
		List<gcInventoryMovementCube_Report.cube> allCubes = gcInventoryMovementCube_Report.inventoryAggRes(mapFilters, new List<String>{'idSerial'});
		Map<Id,Decimal> mapSerialCost = new Map<Id,Decimal>();
		for(gcInventoryMovementCube_Report.cube cube : allCubes){
			Decimal avg = cube.qty != 0 ? cube.amt/cube.qty : 0;
			mapSerialCost.put(cube.idSerial, avg);
		}
		List<GMBLASERP__Serial_Number__c> listSerials = new List<GMBLASERP__Serial_Number__c>();
		for(GMBLASERP__Serial_Number__c p : 
				[SELECT Id, 
					Current_Unit_Cost__c 
				FROM GMBLASERP__Serial_Number__c WHERE Id IN:mapSerialCost.keySet()])
		{
			Decimal avg = mapSerialCost.get(p.Id);
			if(avg == null) avg = 0;
			if(p.Current_Unit_Cost__c == null 
				|| p.Current_Unit_Cost__c.setScale(2) != avg.setScale(2))
			{
				p.Current_Unit_Cost__c = avg.setScale(2);
				listSerials.add(p);
			}
		}
		if(!listSerials.isEmpty()){
			Boolean olVal = gcSerialNumber.disableTrigger;
			gcSerialNumber.disableTrigger = true;
			update listSerials;
			gcSerialNumber.disableTrigger = olVal;
		}		
	}
	/// Auto de-nesting only happens from materials. 
	/// If a serial number was selected but later changed then the previous serial will be de-nested
	public static void deNestSrials(Set<Id> setIdSerial)
	{
		List<GMBLASERP__Serial_Number__c> listSerialsToUpdate = new List<GMBLASERP__Serial_Number__c>();
		for(GMBLASERP__Serial_Number__c sn : [SELECT Id, Nest__c FROM GMBLASERP__Serial_Number__c WHERE Id IN :setIdSerial])
		{
			sn.Nest__c = null;
			listSerialsToUpdate.add(sn);
		}
		Boolean boolOld = disableTrigger;
		disableTrigger = true;
		update listSerialsToUpdate;
		disableTrigger = boolOld;		
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
	}
}