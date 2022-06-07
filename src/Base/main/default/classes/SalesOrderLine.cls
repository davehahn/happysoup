public without sharing class SalesOrderLine {


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

	public static Boolean disableAutosetTaxable{
		get{
			if(disableAutosetTaxable == null) return false;
			else return disableAutosetTaxable;
		}
		set{
			if(value == null) disableAutosetTaxable = false;
			else disableAutosetTaxable = value;
		}
	}

	public static void triggerHandler
		(map<Id,AcctSeedERP__Sales_Order_Line__c> oldMap,
		 map<Id,AcctSeedERP__Sales_Order_Line__c> newMap,
		 list<AcctSeedERP__Sales_Order_Line__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeedERP__Sales_Order_Line__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeedERP__Sales_Order_Line__c>();
		if(listNew == NULL) listNew = new list<AcctSeedERP__Sales_Order_Line__c>();

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
			set<Id> setIdBill = new set<Id>();
			if(boolIsInsert)
			{
				for(AcctSeedERP__Sales_Order_Line__c b : listNew)
					setIdBill.add(b.AcctSeedERP__Sales_Order__c);
                System.debug('setIdBill insert= '+setIdBill);
			}
			if(boolIsUpdate)
			{
				for(AcctSeedERP__Sales_Order_Line__c b : listNew)
					setIdBill.add(b.AcctSeedERP__Sales_Order__c);
				for(AcctSeedERP__Sales_Order_Line__c b : oldMap.values())
					setIdBill.add(b.AcctSeedERP__Sales_Order__c);
                System.debug('setIdBill update= '+setIdBill);
			}
			if(boolIsDelete)
			{
				for(AcctSeedERP__Sales_Order_Line__c b : oldMap.values())
					setIdBill.add(b.AcctSeedERP__Sales_Order__c);
			}
			SalesOrderLine_Service.updateSalesTax(setIdBill);
		}
	}
}