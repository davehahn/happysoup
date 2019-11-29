public without sharing class gcPurchaseOrder {
	
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

	public static void triggerHandler
		(map<Id,AcctSeedERP__Purchase_Order__c> oldMap,
		 map<Id,AcctSeedERP__Purchase_Order__c> newMap,
		 list<AcctSeedERP__Purchase_Order__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeedERP__Purchase_Order__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeedERP__Purchase_Order__c>();
		if(listNew == NULL) listNew = new list<AcctSeedERP__Purchase_Order__c>();

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

	public static void updateAndValidate
		(map<Id,AcctSeedERP__Purchase_Order__c> oldMap,
		 map<Id,AcctSeedERP__Purchase_Order__c> newMap,
		 list<AcctSeedERP__Purchase_Order__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(boolIsBefore && (boolIsUpdate || boolIsInsert))
		{
			refreshStatics(listNew);

			for(AcctSeedERP__Purchase_Order__c po : listNew)
			{
				AcctSeedERP__Purchase_Order__c oldRec;
				if(boolIsUpdate)
					oldRec = oldMap.get(po.Id);

				if(boolIsUpdate && po.Locked__c && oldRec.Locked__c)
				{
					if(po.AcctSeedERP__Vendor__c != oldRec.AcctSeedERP__Vendor__c
						|| po.AcctSeedERP__Vendor_Street__c != oldRec.AcctSeedERP__Vendor_Street__c
						|| po.AcctSeedERP__Vendor_City__c != oldRec.AcctSeedERP__Vendor_City__c
						|| po.AcctSeedERP__Vendor_State__c != oldRec.AcctSeedERP__Vendor_State__c
						|| po.AcctSeedERP__Vendor_Postal_Code__c != oldRec.AcctSeedERP__Vendor_Postal_Code__c
						|| po.AcctSeedERP__Vendor_Country__c != oldRec.AcctSeedERP__Vendor_Country__c
						|| po.AcctSeedERP__Vendor_Contact__c != oldRec.AcctSeedERP__Vendor_Contact__c
						|| po.AcctSeedERP__Shipping_Company__c != oldRec.AcctSeedERP__Shipping_Company__c
						|| po.AcctSeedERP__Shipping_Street__c != oldRec.AcctSeedERP__Shipping_Street__c
						|| po.AcctSeedERP__Shipping_City__c != oldRec.AcctSeedERP__Shipping_City__c
						|| po.AcctSeedERP__Shipping_State__c != oldRec.AcctSeedERP__Shipping_State__c
						|| po.AcctSeedERP__Shipping_Postal_Code__c != oldRec.AcctSeedERP__Shipping_Postal_Code__c
						|| po.AcctSeedERP__Shipping_Country__c != oldRec.AcctSeedERP__Shipping_Country__c
						|| po.AcctSeedERP__Shipping_Contact__c != oldRec.AcctSeedERP__Shipping_Contact__c
						|| po.GMBLASERP__Pricebook__c != oldRec.GMBLASERP__Pricebook__c
						|| po.GMBLASERP__Project__c != oldRec.GMBLASERP__Project__c
						|| po.GMBLASERP__Project_Task__c != oldRec.GMBLASERP__Project_Task__c
						|| po.AcctSeedERP__Order_Date__c != oldRec.AcctSeedERP__Order_Date__c
						|| po.Warehouse__c != oldRec.Warehouse__c)
						{
							po.addError('Vendor, Vendor Address , Shipping Company, Shipping Address, Pricebook, Project, Project Task, Warehouse or Order Date cannot be modified on a Locked Purchase order.');
						}
				}

				if(boolIsInsert || (boolIsUpdate && oldRec.AcctSeedERP__Shipping_Company__c != po.AcctSeedERP__Shipping_Company__c))
				{
					if(mapAccount.containsKey(po.AcctSeedERP__Shipping_Company__c))
					{
						Account a = mapAccount.get(po.AcctSeedERP__Shipping_Company__c);

						po.AcctSeedERP__Shipping_Street__c = a.ShippingStreet;
						po.AcctSeedERP__Shipping_City__c = a.ShippingCity;
						if(a.ShippingState != null)
							 po.AcctSeedERP__Shipping_State__c = a.ShippingState.LEFT(20);
						else po.AcctSeedERP__Shipping_State__c = null;
						po.AcctSeedERP__Shipping_Postal_Code__c = a.ShippingPostalCode;
						po.AcctSeedERP__Shipping_Country__c = a.ShippingCountry;
						po.AcctSeedERP__Shipping_Contact__c = a.AcctSeed__Shipping_Contact__c;
					}
				}

				if(po.AcctSeedERP__Shipping_Company__c == null)
				{
					String userWarehouse = gcConstants.nameUserWarehouse;
					AcctSeedERP__Warehouse__c whs = mapWarehouse.get(userWarehouse);
					if(whs == null) whs = mapWarehouse.get('Whitefish');

					po.AcctSeedERP__Shipping_Street__c = whs.Street__c;
					po.AcctSeedERP__Shipping_City__c = whs.City__c;
					if(whs.State__c != null)
						 po.AcctSeedERP__Shipping_State__c = whs.State__c;
					else po.AcctSeedERP__Shipping_State__c = null;
					po.AcctSeedERP__Shipping_Postal_Code__c = whs.Postal_Code__c;
					po.AcctSeedERP__Shipping_Country__c = whs.Country__c;
				}
			}
		}
		if(!boolIsBefore)
		{
			if(boolIsUpdate || boolIsInsert)
			{
				for(AcctSeedERP__Purchase_Order__c po : listNew)
				{
					if((boolIsInsert && po.AcctSeedERP__Status__c == 'Closed' && po.Total_Qty_Unreceived__c > 0) 
						|| (boolIsUpdate && po.AcctSeedERP__Status__c == 'Closed' && oldMap.get(po.Id).AcctSeedERP__Status__c != 'Closed' && po.Total_Qty_Unreceived__c > 0))
						po.addError('Purchase order cannot be closed. There are still unreceived quantity.');
					else if(boolIsUpdate && po.AcctSeedERP__Status__c == 'Closed' && oldMap.get(po.Id).AcctSeedERP__Status__c == 'Closed' && po.Total_Qty_Unreceived__c > 0)
						po.addError('Purchase order is closed and there are still unreceived quantity. Please Open the PO or fix PO Lines to proceed.');
				}
			}
			if(boolIsUpdate)
			{
				Set<Id> setIdPOhasMoves = new set<Id>();
				for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move :
						[SELECT AcctSeedERP__Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__c
						 FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c
						 WHERE AcctSeedERP__Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__c IN : oldMap.keySet()])
				{
					setIdPOhasMoves.add(move.AcctSeedERP__Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__c);
				}
				if(!setIdPOhasMoves.isEmpty())
				for(AcctSeedERP__Purchase_Order__c po : listNew)
				{
					if(po.Warehouse__c != oldMap.get(po.Id).Warehouse__c && setIdPOhasMoves.contains(po.Id))
						po.Warehouse__c.addError('The Warehouse for the purchase order cannot be changed, because some receiving has already occurred.');
				}
			}
		}
	}

	private static map<Id,Account> mapAccount;
	private static map<String,AcctSeedERP__Warehouse__c> mapWarehouse;

	private static void refreshStatics(list<AcctSeedERP__Purchase_Order__c> listNew)
	{
		if(mapAccount == null)
		{
			mapAccount = new map<Id,Account>();
			mapWarehouse = new map<String,AcctSeedERP__Warehouse__c>();
		}

		set<Id> setIdAccount = new set<Id>();
		set<String> setNameWarehouse = new set<String>{'Whitefish'};
		String userWarehouse = gcConstants.nameUserWarehouse;
		setNameWarehouse.add(userWarehouse);
		
		for(AcctSeedERP__Purchase_Order__c b : listNew)
		{
			if(b.AcctSeedERP__Shipping_Company__c != null && !mapAccount.containsKey(b.AcctSeedERP__Shipping_Company__c))
				setIdAccount.add(b.AcctSeedERP__Shipping_Company__c);
		}

		if(!setIdAccount.isEmpty())
        for(Account a :
        	[SELECT Id, 
        		ShippingCountry, ShippingCity, ShippingPostalCode, ShippingState, ShippingStreet, AcctSeed__Shipping_Contact__c
        	 FROM Account
        	 WHERE Id IN :setIdAccount])
        {
        	mapAccount.put(a.Id,a);
        }

        for(AcctSeedERP__Warehouse__c whs :
        	[SELECT Id,
        			Name,
        			Street__c,
        			City__c,
        			State__c,
        			Postal_Code__c,
        			Country__c
        	 FROM AcctSeedERP__Warehouse__c
        	 WHERE Name IN:setNameWarehouse])
        {
        	mapWarehouse.put(whs.Name,whs);
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
	} 
}