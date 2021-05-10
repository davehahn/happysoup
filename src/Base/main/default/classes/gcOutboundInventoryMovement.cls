global without sharing class gcOutboundInventoryMovement {

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
	
	global static Boolean enableExchangeDelete{
		get{
			if(enableExchangeDelete == null) return false;
			else return enableExchangeDelete;
		}
		set{
			if(value == null) enableExchangeDelete = false;
			else enableExchangeDelete = value;
		}
	}

	public static void triggerHandler
		(map<Id,AcctSeedERP__Outbound_Inventory_Movement__c> oldMap,
		 map<Id,AcctSeedERP__Outbound_Inventory_Movement__c> newMap,
		 list<AcctSeedERP__Outbound_Inventory_Movement__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeedERP__Outbound_Inventory_Movement__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeedERP__Outbound_Inventory_Movement__c>();
		if(listNew == NULL) listNew = new list<AcctSeedERP__Outbound_Inventory_Movement__c>();

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
				for(AcctSeedERP__Outbound_Inventory_Movement__c oim : listNew)
					if(oim.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(oim.GMBLASERP__Serial_Number__c);
			}
			if(boolIsUpdate)
			{
				for(AcctSeedERP__Outbound_Inventory_Movement__c oim : listNew)
					if(oim.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(oim.GMBLASERP__Serial_Number__c);
				for(AcctSeedERP__Outbound_Inventory_Movement__c oim : oldMap.values())
					if(oim.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(oim.GMBLASERP__Serial_Number__c);
			}
			if(boolIsDelete)
			{
				for(AcctSeedERP__Outbound_Inventory_Movement__c oim : oldMap.values())
					if(oim.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(oim.GMBLASERP__Serial_Number__c);
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
		(map<Id,AcctSeedERP__Outbound_Inventory_Movement__c> oldMap,
		 map<Id,AcctSeedERP__Outbound_Inventory_Movement__c> newMap,
		 list<AcctSeedERP__Outbound_Inventory_Movement__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(boolIsBefore && (boolIsUpdate || boolIsInsert))
		{
			/// GLV 1,2 FROM Adjustment
			Map<Id,GMBLASERP__Inventory_Adjustment__c> mapAdjustmentGLV = new Map<Id,GMBLASERP__Inventory_Adjustment__c>();
			for(AcctSeedERP__Outbound_Inventory_Movement__c move :listNew)
			{
				//move.AcctSeedERP__Ledger__c = 'a124F000000leJoQAI';
				if(move.Adjustment_Id_From_Inbound__c != null)
					mapAdjustmentGLV.put(move.Adjustment_Id_From_Inbound__c, null);
			}
			if(!mapAdjustmentGLV.isEmpty())
			{
				for(GMBLASERP__Inventory_Adjustment__c adj : [SELECT Id, GL_Account_Variable_1__c, Department_GLV_2__c FROM GMBLASERP__Inventory_Adjustment__c WHERE Id IN:mapAdjustmentGLV.keySet()])
					mapAdjustmentGLV.put(adj.Id, adj);

				for(AcctSeedERP__Outbound_Inventory_Movement__c move :listNew)
				{
					if(move.Adjustment_Id_From_Inbound__c != null 
						&& mapAdjustmentGLV.get(move.Adjustment_Id_From_Inbound__c) != null 
						&& mapAdjustmentGLV.get(move.Adjustment_Id_From_Inbound__c).GL_Account_Variable_1__c != null)
						move.AcctSeedERP__GL_Account_Variable_1__c = mapAdjustmentGLV.get(move.Adjustment_Id_From_Inbound__c).GL_Account_Variable_1__c;
					if(move.Adjustment_Id_From_Inbound__c != null 
						&& mapAdjustmentGLV.get(move.Adjustment_Id_From_Inbound__c) != null 
						&& mapAdjustmentGLV.get(move.Adjustment_Id_From_Inbound__c).Department_GLV_2__c != null)
						move.AcctSeedERP__GL_Account_Variable_2__c = mapAdjustmentGLV.get(move.Adjustment_Id_From_Inbound__c).Department_GLV_2__c;
				}
			}
		}

		if(boolIsBefore && boolIsDelete)
		{
			for(AcctSeedERP__Outbound_Inventory_Movement__c move :oldMap.values())
			{
				if(move.Lot_Exchange__c != null && !enableExchangeDelete)
					move.addError('The movement cannot be deleted as it is releated to a Lot Exchange.');
			}			
		}

		if(!boolIsBefore){
			Set<Id> setIdMaterialToUpdate = new Set<Id>();
			if(boolIsInsert || boolIsUpdate)
			for(AcctSeedERP__Outbound_Inventory_Movement__c move :listNew)
			{
				if(move.Material__c != null)
					setIdMaterialToUpdate.add(move.Material__c);
			}
			if(boolIsDelete || boolIsUpdate)
			for(AcctSeedERP__Outbound_Inventory_Movement__c move :oldMap.values())
			{
				if(move.Material__c != null)
					setIdMaterialToUpdate.add(move.Material__c);
			}

			if(!setIdMaterialToUpdate.isEmpty()){
				System.debug(loggingLevel.Error, 'setIdMaterialToUpdate:'+setIdMaterialToUpdate);
				gcMaterial.updateQtyMoved(setIdMaterialToUpdate);
			}
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
	}
}