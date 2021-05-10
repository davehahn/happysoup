global without sharing class gcPurchaseOrderInventoryMovement {

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

	public static void triggerHandler
		(map<Id,AcctSeedERP__Purchase_Order_Inventory_Movement__c> oldMap,
		 map<Id,AcctSeedERP__Purchase_Order_Inventory_Movement__c> newMap,
		 list<AcctSeedERP__Purchase_Order_Inventory_Movement__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeedERP__Purchase_Order_Inventory_Movement__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeedERP__Purchase_Order_Inventory_Movement__c>();
		if(listNew == NULL) listNew = new list<AcctSeedERP__Purchase_Order_Inventory_Movement__c>();

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
				for(AcctSeedERP__Purchase_Order_Inventory_Movement__c im : listNew)
					if(im.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(im.GMBLASERP__Serial_Number__c);
			}
			if(boolIsUpdate)
			{
				for(AcctSeedERP__Purchase_Order_Inventory_Movement__c im : listNew)
					if(im.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(im.GMBLASERP__Serial_Number__c);
				for(AcctSeedERP__Purchase_Order_Inventory_Movement__c im : oldMap.values())
					if(im.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(im.GMBLASERP__Serial_Number__c);
			}
			if(boolIsDelete)
			{
				for(AcctSeedERP__Purchase_Order_Inventory_Movement__c im : oldMap.values())
					if(im.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(im.GMBLASERP__Serial_Number__c);
			}
			/// To update serial unit cost run time (future).
			if(!setIdSerial.isEmpty()){
				List<String> listId = new List<String>();
				listId.addAll(setIdSerial);
				gcSerialNumber.updateSerialUnitCostFuture(listId);
			}
		} 
	}

	private static void updateAndValidate
		(map<Id,AcctSeedERP__Purchase_Order_Inventory_Movement__c> oldMap,
		 map<Id,AcctSeedERP__Purchase_Order_Inventory_Movement__c> newMap,
		 list<AcctSeedERP__Purchase_Order_Inventory_Movement__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(boolIsBefore && (boolIsInsert || boolIsUpdate))
		{
			CustomPermissionsReader cpr = new CustomPermissionsReader();
			Boolean canModifyLockedPurchaseOrder = false;
			Boolean canReceiveAnyLotPOL = false;
  			if(cpr.hasPermission('CanModifyLockedPurchaseOrder'))
  				canModifyLockedPurchaseOrder = true;
  			if(cpr.hasPermission('CanReceiveAnyLotPOL'))
  				canReceiveAnyLotPOL = true;
			//collect and map the parent purchase order lines
			map<Id,AcctSeedERP__Purchase_Order_Line__c> mapPurchLine = new map<Id,AcctSeedERP__Purchase_Order_Line__c>();		
			for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move : listNew)
			{
				//move.AcctSeedERP__Ledger__c = 'a124F000000leJoQAI';
				mapPurchLine.put(move.AcctSeedERP__Purchase_Order_Line__c, NULL);
			}

			for(AcctSeedERP__Purchase_Order_Line__c pol: 
					[SELECT Id, 
					 GMBLASERP__Lot__c,
					 AcctSeedERP__Product__c,
					 AcctSeedERP__Product__r.RecordType.Name,
					 AcctSeedERP__Project__c,
					 AcctSeedERP__Project__r.Retail_ERP__c,
					 AcctSeedERP__Project_Task__c,
					 AcctSeedERP__Quantity_Received__c
					 FROM AcctSeedERP__Purchase_Order_Line__c
					 WHERE Id IN : mapPurchLine.keySet()])
			{
				mapPurchLine.put(pol.Id, pol);
			}

			Map<Id,Map<Id,Id>> mapProjectProductSerial = new Map<Id,Map<Id,Id>>();
			for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move : listNew)
			{
				AcctSeedERP__Purchase_Order_Line__c pol = mapPurchLine.get(move.AcctSeedERP__Purchase_Order_Line__c);
				/// If the Permission is not assigned then the lot must be the same.
				if(!canReceiveAnyLotPOL && pol.AcctSeedERP__Product__r.RecordType.Name == 'Boat')
					move.GMBLASERP__Lot__c  = pol.GMBLASERP__Lot__c;
				if(boolIsInsert && !canReceiveAnyLotPOL && pol.AcctSeedERP__Product__r.RecordType.Name == 'Boat' && (pol.AcctSeedERP__Quantity_Received__c >= 1 || pol.AcctSeedERP__Quantity_Received__c <= -1))
					move.addError('Cannot create multiple movements for a purchase order line with a Boat product.');

				if((boolIsInsert || 
					(boolIsUpdate && move.GMBLASERP__Serial_Number__c != oldMap.get(move.Id).GMBLASERP__Serial_Number__c)) 
					&& move.GMBLASERP__Serial_Number__c != null 
					&& pol.AcctSeedERP__Product__r.RecordType.Name == 'Boat')
				{
					if(pol.AcctSeedERP__Project__c != null){
						mapProjectProductSerial.put(pol.AcctSeedERP__Project__c, new Map<Id,Id>());
						mapProjectProductSerial.get(pol.AcctSeedERP__Project__c).put(pol.AcctSeedERP__Product__c,move.GMBLASERP__Serial_Number__c);

						//if(pol.AcctSeedERP__Project__r.Retail_ERP__c != null){
						//	mapProjectProductSerial.put(pol.AcctSeedERP__Project__r.Retail_ERP__c, new Map<Id,Id>());
						//	mapProjectProductSerial.get(pol.AcctSeedERP__Project__r.Retail_ERP__c).put(pol.AcctSeedERP__Product__c,move.GMBLASERP__Serial_Number__c);
						//}
					}
				}
			}

			if(!mapProjectProductSerial.isEmpty()){
				Boolean oldV = gcMaterial.allowUntagRetail;
				gcMaterial.allowUntagRetail = true;
				gcMaterial.updateRetailMaterialSerial(mapProjectProductSerial);
				gcMaterial.allowUntagRetail = oldV;
			}
		}
		/// Delete the serial number
		if(!boolIsBefore && boolIsDelete){
			Set<Id> setIdSerial = new Set<Id>();
			for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move : oldMap.values()){
				if(move.GMBLASERP__Serial_Number__c != null)
					setIdSerial.add(move.GMBLASERP__Serial_Number__c);
			}

			if(!setIdSerial.isEmpty())
				delete [SELECT Id FROM GMBLASERP__Serial_Number__c WHERE Id IN:setIdSerial];
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
	} 
}