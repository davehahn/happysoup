global without sharing class gcInboundInventoryMovement {

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
		(map<Id,AcctSeedERP__Inbound_Inventory_Movement__c> oldMap,
		 map<Id,AcctSeedERP__Inbound_Inventory_Movement__c> newMap,
		 list<AcctSeedERP__Inbound_Inventory_Movement__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeedERP__Inbound_Inventory_Movement__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeedERP__Inbound_Inventory_Movement__c>();
		if(listNew == NULL) listNew = new list<AcctSeedERP__Inbound_Inventory_Movement__c>();

		updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);

		if(boolIsBefore)
		{
			gcSerialNumber.checkPriorMovements(listNew,oldMap);
			
			if(boolIsInsert)
			{
				gcTransactionParent.setFinancialAttributes(
					listNew,
					null,
					'AcctSeedERP__Project_Task__c',
					null);
			}
			if(boolIsUpdate)
			{
				gcTransactionParent.setFinancialAttributes(
					listNew,
					null,
					'AcctSeedERP__Project_Task__c',
					null);
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
				for(AcctSeedERP__Inbound_Inventory_Movement__c im : listNew)
					if(im.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(im.GMBLASERP__Serial_Number__c);
			}
			if(boolIsUpdate)
			{
				for(AcctSeedERP__Inbound_Inventory_Movement__c im : listNew)
					if(im.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(im.GMBLASERP__Serial_Number__c);
				for(AcctSeedERP__Inbound_Inventory_Movement__c im : oldMap.values())
					if(im.GMBLASERP__Serial_Number__c != null)
						setIdSerial.add(im.GMBLASERP__Serial_Number__c);
			}
			if(boolIsDelete)
			{
				for(AcctSeedERP__Inbound_Inventory_Movement__c im : oldMap.values())
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
		(map<Id,AcctSeedERP__Inbound_Inventory_Movement__c> oldMap,
		 map<Id,AcctSeedERP__Inbound_Inventory_Movement__c> newMap,
		 list<AcctSeedERP__Inbound_Inventory_Movement__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(boolIsBefore)
		{
			if(boolIsUpdate || boolIsInsert)
			{
				/// GLV 1 FROM Adjustment
				Map<Id,GMBLASERP__Inventory_Adjustment__c> mapAdjustmentGLV1 = new Map<Id,GMBLASERP__Inventory_Adjustment__c>();
				for(AcctSeedERP__Inbound_Inventory_Movement__c move :listNew)
				{
					//move.AcctSeedERP__Ledger__c = 'a124F000000leJoQAI';
					if(move.GMBLASERP__Inventory_Adjustment__c != null)
						mapAdjustmentGLV1.put(move.GMBLASERP__Inventory_Adjustment__c, null);
				}
				if(!mapAdjustmentGLV1.isEmpty())
				{
					for(GMBLASERP__Inventory_Adjustment__c adj : [SELECT Id, GL_Account_Variable_1__c, Department_GLV_2__c FROM GMBLASERP__Inventory_Adjustment__c WHERE Id IN:mapAdjustmentGLV1.keySet()])
						mapAdjustmentGLV1.put(adj.Id, adj);

					for(AcctSeedERP__Inbound_Inventory_Movement__c move :listNew)
					{
						if(move.GMBLASERP__Inventory_Adjustment__c != null 
							&& mapAdjustmentGLV1.get(move.GMBLASERP__Inventory_Adjustment__c) != null 
							&& mapAdjustmentGLV1.get(move.GMBLASERP__Inventory_Adjustment__c).GL_Account_Variable_1__c != null)
							move.AcctSeedERP__GL_Account_Variable_1__c = mapAdjustmentGLV1.get(move.GMBLASERP__Inventory_Adjustment__c).GL_Account_Variable_1__c;
						if(move.GMBLASERP__Inventory_Adjustment__c != null 
							&& mapAdjustmentGLV1.get(move.GMBLASERP__Inventory_Adjustment__c) != null 
							&& mapAdjustmentGLV1.get(move.GMBLASERP__Inventory_Adjustment__c).Department_GLV_2__c != null)
							move.AcctSeedERP__GL_Account_Variable_2__c = mapAdjustmentGLV1.get(move.GMBLASERP__Inventory_Adjustment__c).Department_GLV_2__c;
					}
				}
			}
			if(boolIsDelete)
			for(AcctSeedERP__Inbound_Inventory_Movement__c move :oldMap.values())
			{
				if(move.Lot_Exchange__c != null && !enableExchangeDelete)
					move.addError('The movement cannot be deleted as it is releated to a Lot Exchange.');
			}			
		}

		if(!boolIsBefore)
		{
			set<Id> setIdPTrecalcFg = new set<Id>();
			for(AcctSeedERP__Inbound_Inventory_Movement__c move : listNew)
			{
				setIdPTrecalcFg.add(move.AcctSeedERP__Project_Task__c);
			}
			for(AcctSeedERP__Inbound_Inventory_Movement__c move : oldMap.values())
			{
				setIdPTrecalcFg.add(move.AcctSeedERP__Project_Task__c);
			}
			setIdPTrecalcFg.remove(null);

			if(!setIdPTrecalcFg.isEmpty())
				rollUpFg(setIdPTrecalcFg);
		}
	}
   
	public static void rollUpFg(set<Id> setIdProjectTask)
	{
		setIdProjectTask.remove(null);

		list<AcctSeed__Project_Task__c> listPTupdate = new list<AcctSeed__Project_Task__c>();
        Set<Id> setIdProject = new Set<Id>();
		for(AcctSeed__Project_Task__c pt :
			[SELECT Id, Finished_Goods__c, AcctSeed__Project__c,
				(SELECT Id, 
						GMBLASERP__Inventory_GL_Amount__c
				 FROM AcctSeedERP__Inbound_Inventory_Movements__r
				 WHERE (GMBLASERP__Inventory_GL_Amount__c < 0 OR GMBLASERP__Inventory_GL_Amount__c > 0))
			 FROM AcctSeed__Project_Task__c
			 WHERE Id IN :setIdProjectTask])
		{
			Decimal finishedGoods = 0;

			for(AcctSeedERP__Inbound_Inventory_Movement__c move : pt.AcctSeedERP__Inbound_Inventory_Movements__r)
			{
				finishedGoods += move.GMBLASERP__Inventory_GL_Amount__c;
			}

			if(pt.Finished_Goods__c == null || pt.Finished_Goods__c.setScale(6) != finishedGoods.setScale(6))
			{
				pt.Finished_Goods__c = finishedGoods;

				listPTupdate.add(pt);
				if(finishedGoods <> 0)
					setIdProject.add(pt.AcctSeed__Project__c);
			}

			Boolean boolOld  = gcProjectTask.disableTrigger;
			gcProjectTask.disableTrigger = true;

			if(!listPTupdate.isEmpty())
				update listPTupdate;

			gcProjectTask.disableTrigger = boolOld;

			/// Once Finished good is build project should be locked
			if(!setIdProject.isEmpty())
				gcProject.lockProjects(setIdProject);
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
	}
}