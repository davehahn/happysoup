global without sharing class gcInventoryAdjustment {

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
			(map<Id,GMBLASERP__Inventory_Adjustment__c> oldMap,
					map<Id,GMBLASERP__Inventory_Adjustment__c> newMap,
					list<GMBLASERP__Inventory_Adjustment__c> listNew,
					Boolean boolIsBefore,
					Boolean boolIsInsert,
					Boolean boolIsUpdate,
					Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,GMBLASERP__Inventory_Adjustment__c>();
		if(newMap == NULL) newMap = new map<Id,GMBLASERP__Inventory_Adjustment__c>();
		if(listNew == NULL) listNew = new list<GMBLASERP__Inventory_Adjustment__c>();

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

			}
			if(boolIsDelete)
			{

			}
		}
	}

	private static void updateAndValidate
			(map<Id,GMBLASERP__Inventory_Adjustment__c> oldMap,
					map<Id,GMBLASERP__Inventory_Adjustment__c> newMap,
					list<GMBLASERP__Inventory_Adjustment__c> listNew,
					Boolean boolIsBefore,
					Boolean boolIsInsert,
					Boolean boolIsUpdate,
					Boolean boolIsDelete)
	{
		if (boolIsBefore && (boolIsUpdate || boolIsInsert)) {
			retrieveStatics(listNew);
			for(GMBLASERP__Inventory_Adjustment__c adj : listNew)
			{
				if(adj.GL_Account_Variable_1__c == null )
				{
					User u = mapUser.get(adj.OwnerId);
					if(u != null && u.GL_Account_Variable_1__c != null && mapGlv1ByName.containsKey(u.GL_Account_Variable_1__c))
						adj.GL_Account_Variable_1__c = mapGlv1ByName.get(u.GL_Account_Variable_1__c).Id;
				}
			}
		}
	}
	private static map<String,AcctSeed__Accounting_Variable__c> mapGlv1ByName;
	private static map<Id,User> mapUser;

	private static void retrieveStatics(list<GMBLASERP__Inventory_Adjustment__c> listNew)
	{
		set<String> setNameGlv = new set<String>();
		set<Id> setIdUser = new set<Id>();

		if(mapUser == null)
		{
			mapGlv1ByName = new map<String,AcctSeed__Accounting_Variable__c>();
			mapUser = new map<Id,User>();
		}

		for(GMBLASERP__Inventory_Adjustment__c adj : listNew)
		{
			if(adj.OwnerId != null && !mapUser.containsKey(adj.OwnerId))
				setIdUser.add(adj.OwnerId);
		}

		if(!setIdUser.isEmpty())
			for(User u : [SELECT Id, GL_Account_Variable_1__c FROM User WHERE Id IN:setIdUser])
			{
				if(u.GL_Account_Variable_1__c != null)
					setNameGlv.add(u.GL_Account_Variable_1__c);

				mapUser.put(u.Id, u);
			}

		if(!setNameGlv.isEmpty())
			for(AcctSeed__Accounting_Variable__c glv :
			[SELECT Id,
					Name,
					AcctSeed__Type__c
			FROM AcctSeed__Accounting_Variable__c
			WHERE Name IN:setNameGlv])
			{
				if(glv.AcctSeed__Type__c.equals('GL Account Variable 1'))
					mapGlv1ByName.put(glv.Name,glv);
			}
	}

	public static void cascadeDeleteChildrenOfInbound(set<Id> setIdMoveIn)
	{
		System.debug('cascadeDeleteChildrenOfInbound');
		list<AcctSeedERP__Inbound_Inventory_Movement__c> listMoveInUpdate = new list<AcctSeedERP__Inbound_Inventory_Movement__c>();
		list<AcctSeedERP__Outbound_Inventory_Movement__c> listMoveOutDelete = new list<AcctSeedERP__Outbound_Inventory_Movement__c>();

		for(AcctSeedERP__Inbound_Inventory_Movement__c moveIn :
		[SELECT Id, AcctSeedERP__Quantity__c, GMBLASERP__Serial_Number__c,
		(SELECT Id FROM AcctSeedERP__Outbound_Inventory_Movements__r)
		FROM AcctSeedERP__Inbound_Inventory_Movement__c
		WHERE Id IN :setIdMoveIn
		AND GMBLASERP__Inventory_Adjustment__c != null])
		{
			//if the inbound move is for a serialized item, and if it has children, first update the quantity to zero.
			if(moveIn.AcctSeedERP__Outbound_Inventory_Movements__r.size() > 0)
			{
				if(moveIn.GMBLASERP__Serial_Number__c != null && moveIn.AcctSeedERP__Quantity__c != 0)
				{
					moveIn.AcctSeedERP__Quantity__c = 0;
					listMoveInUpdate.add(moveIn);
				}
				listMoveOutDelete.addAll(moveIn.AcctSeedERP__Outbound_Inventory_Movements__r);
			}
		}
		if(listMoveInUpdate.size() > 0)
			update listMoveInUpdate;
		if(listMoveOutDelete.size() > 0)
			delete listMoveOutDelete;
	}

	public static void coverage(){}
}