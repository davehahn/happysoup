global without sharing class gcManufacturingInventoryMovement {

	global static Boolean disableTrigger{
		get{
			if(disableTrigger == null) return false;
			else return disableTrigger;
		}
		set{
			if(value == null) disableTrigger = false;
			else disableTrigger = value;
		}
	}

	global static Boolean allowMFGERPSerialWIP{
		get{
			if(allowMFGERPSerialWIP == null) return false;
			else return allowMFGERPSerialWIP;
		}
		set{
			if(value == null) allowMFGERPSerialWIP = false;
			else allowMFGERPSerialWIP = value;
		}
	}

	public static void triggerHandler
		(map<Id,AcctSeedERP__Manufacturing_Inventory_Movement__c> oldMap,
		 map<Id,AcctSeedERP__Manufacturing_Inventory_Movement__c> newMap,
		 list<AcctSeedERP__Manufacturing_Inventory_Movement__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeedERP__Manufacturing_Inventory_Movement__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeedERP__Manufacturing_Inventory_Movement__c>();
		if(listNew == NULL) listNew = new list<AcctSeedERP__Manufacturing_Inventory_Movement__c>();

		updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);

		if(boolIsBefore)
		{
			gcSerialNumber.checkPriorMovements(listNew,oldMap);
			
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
			Set<String> setIdSerial = new Set<String>();
			if(boolIsInsert)
			{
				for(AcctSeedERP__Manufacturing_Inventory_Movement__c im : listNew)
					if(im.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(im.GMBLASERP__Serial_Number__c);
			}
			if(boolIsUpdate)
			{
				for(AcctSeedERP__Manufacturing_Inventory_Movement__c im : listNew)
					if(im.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(im.GMBLASERP__Serial_Number__c);
				for(AcctSeedERP__Manufacturing_Inventory_Movement__c im : oldMap.values())
					if(im.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(im.GMBLASERP__Serial_Number__c);
			}
			if(boolIsDelete)
			{
				for(AcctSeedERP__Manufacturing_Inventory_Movement__c im : oldMap.values())
					if(im.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(im.GMBLASERP__Serial_Number__c);
			}
			/// To update serial unit cost run time (future).
//			if(!setIdSerial.isEmpty()){
//				List<String> listId = new List<String>();
//				listId.addAll(setIdSerial);
//				gcSerialNumber.updateSerialUnitCostFuture(listId);
//			}
		}
	}

	private static void updateAndValidate
		(map<Id,AcctSeedERP__Manufacturing_Inventory_Movement__c> oldMap,
		 map<Id,AcctSeedERP__Manufacturing_Inventory_Movement__c> newMap,
		 list<AcctSeedERP__Manufacturing_Inventory_Movement__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		/// This part is to check if a serialized item is being moved alone from MFG ERP
		Id idRTMFGERP = gcConstants.idRtProjectManufacturing;
		/// This is only used in Dev Org
		Map<Id,Boolean> mapERPIsMFG = new Map<Id,Boolean>();
		if(boolIsBefore && boolIsInsert){
			for(AcctSeedERP__Manufacturing_Inventory_Movement__c move :listNew){
				if(move.GMBLASERP__Serial_Number__c != null && move.GMBLASERP__Project__c != null){
					mapERPIsMFG.put(move.GMBLASERP__Project__c,false);
				}
			}
			if(!mapERPIsMFG.isEmpty()){
				for(AcctSeed__Project__c pr : [SELECT Id FROM AcctSeed__Project__c WHERE ID IN:mapERPIsMFG.keySet() AND RecordTypeId =:idRTMFGERP]){
					mapERPIsMFG.put(pr.Id,true);
				}
			}
			for(AcctSeedERP__Manufacturing_Inventory_Movement__c move :listNew) {
				if (move.GMBLASERP__Serial_Number__c != null && move.GMBLASERP__Project__c != null) {
					if(mapERPIsMFG.get(move.GMBLASERP__Project__c) && !allowMFGERPSerialWIP)
						move.addError('Cannot move single serial number from MFG ERP.');
				}
			}
		}


		/// This is only used in Dev Org
		if(boolIsBefore && (boolIsInsert || boolIsUpdate)){
//			for(AcctSeedERP__Manufacturing_Inventory_Movement__c move :listNew)
//				move.AcctSeedERP__Ledger__c = 'a128A000003SnkCQAS';

		}
	}
}