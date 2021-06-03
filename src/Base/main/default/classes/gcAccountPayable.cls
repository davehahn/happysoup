public without sharing class gcAccountPayable {
	
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
		(map<Id,AcctSeed__Account_Payable__c> oldMap,
		 map<Id,AcctSeed__Account_Payable__c> newMap,
		 list<AcctSeed__Account_Payable__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeed__Account_Payable__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeed__Account_Payable__c>();
		if(listNew == NULL) listNew = new list<AcctSeed__Account_Payable__c>();

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
		(map<Id,AcctSeed__Account_Payable__c> oldMap,
		 map<Id,AcctSeed__Account_Payable__c> newMap,
		 list<AcctSeed__Account_Payable__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(boolIsBefore && (boolIsUpdate || boolIsInsert))
		{
			refreshStatics(listNew);

			for(AcctSeed__Account_Payable__c ap : listNew)
			{
				AcctSeed__Account_Payable__c oldRec;
				if(boolIsUpdate)
					oldRec = oldMap.get(ap.Id);

				if(ap.Tax_Amount_Fixed__c && !ap.Tax_Override__c)
					ap.Tax_Override__c = true;

				if(ap.AcctSeed__Status__c == 'Posted')
				{
					if(boolIsUpdate)
					{
						if(ap.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c ||
						   ap.Tax_is_Harmonized__c != oldRec.Tax_is_Harmonized__c ||
						   ap.Tax_Override__c != oldRec.Tax_Override__c ||
						   ap.Tax_Rate_Federal__c != oldRec.Tax_Rate_Federal__c ||
						   ap.Tax_Rate_Provincial__c != oldRec.Tax_Rate_Provincial__c ||
						   ap.Tax_Rate_Retail__c != oldRec.Tax_Rate_Retail__c || 
						   ap.Tax_Amount_Federal__c != oldRec.Tax_Amount_Federal__c || 
						   ap.Tax_Amount_Provincial__c != oldRec.Tax_Amount_Provincial__c || 
						   ap.Tax_Amount_Retail__c != oldRec.Tax_Amount_Retail__c)
						{
								ap.addError('The Sales Tax settings of a Payable may not be changed, if the Payable is Posted.');
						}
					}
				}
				else
				{
					Account acct = mapAccount.get(ap.AcctSeed__Vendor__c);
                 
					if(acct != null && acct.BillingState != null && mapGlv3ByName.containsKey(acct.BillingState) 
						&& ((boolIsInsert && ap.GL_Account_Variable_3__c == null) || (boolIsUpdate && ap.AcctSeed__Vendor__c != oldRec.AcctSeed__Vendor__c)))
						ap.GL_Account_Variable_3__c = mapGlv3ByName.get(acct.BillingState).Id;
					
					if(ap.GL_Account_Variable_3__c == null)
					{
						ap.GL_Account_Variable_3__c = gcConstants.idGlv3Others;
						ap.Tax_Override__c = true;
						ap.Tax_Rate_Federal__c = 0;
						ap.Tax_Rate_Provincial__c = 0;
						ap.Tax_Rate_Retail__c = 0;
						ap.Tax_Amount_Federal__c = 0;
						ap.Tax_Amount_Provincial__c = 0;
						ap.Tax_Amount_Retail__c = 0;
					}
					
                   
					if(!ap.Tax_Override__c)
					{
						if(boolIsInsert || 
						  (boolIsUpdate && 
						   (ap.Tax_is_Harmonized__c != oldRec.Tax_is_Harmonized__c ||
							ap.Tax_Override__c != oldRec.Tax_Override__c ||
							ap.Tax_Rate_Federal__c != oldRec.Tax_Rate_Federal__c ||
							ap.Tax_Rate_Provincial__c != oldRec.Tax_Rate_Provincial__c ||
							ap.Tax_Rate_Retail__c != oldRec.Tax_Rate_Retail__c ||
							ap.Tax_Amount_Federal__c != oldRec.Tax_Amount_Federal__c ||
							ap.Tax_Amount_Provincial__c != oldRec.Tax_Amount_Provincial__c ||
							ap.Tax_Amount_Retail__c != oldRec.Tax_Amount_Retail__c ||
                            ap.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c
			
                           )
						   )
						  )
						{
							ap.Tax_Rate_Federal__c = 5;
							ap.Tax_Amount_Federal__c = 0;
							ap.Tax_Amount_Provincial__c = 0;
							ap.Tax_Amount_Retail__c = 0;
							
							AcctSeed__Accounting_Variable__c glvTaxZone = mapGlv.get(ap.GL_Account_Variable_3__c);
							if(glvTaxZone != null)
							{
								ap.Tax_is_Harmonized__c = glvTaxZone.Tax_is_Harmonized__c;
								ap.Tax_Rate_Provincial__c = glvTaxZone.Tax_Rate_Provincial__c;
								ap.Tax_Rate_Retail__c = glvTaxZone.Tax_Rate_Retail__c;
							}							
						}
					}
					else
					{
						if(ap.Tax_Amount_Fixed__c)
						{
							ap.Tax_Rate_Federal__c = 0;
							ap.Tax_Rate_Provincial__c = 0;
							ap.Tax_Rate_Retail__c = 0;
						}
						else
						{
							ap.Tax_Amount_Federal__c = 0;
							ap.Tax_Amount_Provincial__c = 0;
							ap.Tax_Amount_Retail__c = 0;						
						}
					}
				}
			}
		}

		if(!boolIsBefore && boolIsUpdate)
		{
			set<Id> setIdAPayableUpdateTax = new set<Id>();
			set<Id> setIdAPayableLineUpdateDate = new set<Id>();
			for(AcctSeed__Account_Payable__c ap : listNew)
			{
				AcctSeed__Account_Payable__c oldRec = oldMap.get(ap.Id);

				if(ap.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c ||
				    ap.Tax_is_Harmonized__c != oldRec.Tax_is_Harmonized__c ||
				    ap.Tax_Override__c != oldRec.Tax_Override__c ||
				    ap.Tax_Rate_Federal__c != oldRec.Tax_Rate_Federal__c ||
				    ap.Tax_Rate_Provincial__c != oldRec.Tax_Rate_Provincial__c ||
				    ap.Tax_Rate_Retail__c != oldRec.Tax_Rate_Retail__c ||
					ap.Tax_Amount_Federal__c != oldRec.Tax_Amount_Federal__c ||
					ap.Tax_Amount_Provincial__c != oldRec.Tax_Amount_Provincial__c ||
					ap.Tax_Amount_Retail__c != oldRec.Tax_Amount_Retail__c)
				{
					setIdAPayableUpdateTax.add(ap.Id);
				}
			
				if(ap.AcctSeed__Date__c != oldRec.AcctSeed__Date__c && ap.AcctSeed__Status__c != 'Posted')
					setIdAPayableLineUpdateDate.add(ap.Id);
			}
			if(!setIdAPayableUpdateTax.isEmpty())
				gcAccountPayableLine.updateSalesTax(setIdAPayableUpdateTax);
			if(!setIdAPayableLineUpdateDate.isEmpty()){
				List<AcctSeed__Account_Payable_Line__c> listAPL = new List<AcctSeed__Account_Payable_Line__c>();
				for(AcctSeed__Account_Payable_Line__c apl : [SELECT Id, AcctSeed__Date__c, AcctSeed__Account_Payable__r.AcctSeed__Date__c FROM AcctSeed__Account_Payable_Line__c WHERE AcctSeed__Account_Payable__c IN:setIdAPayableLineUpdateDate]){
					apl.AcctSeed__Date__c = apl.AcctSeed__Account_Payable__r.AcctSeed__Date__c;
					listAPL.add(apl);
				}
				if(!listAPL.isEmpty()){
					Boolean oldV = gcAccountPayableLine.disableTrigger;
					gcAccountPayableLine.disableTrigger = true;
					update listAPL;
					gcAccountPayableLine.disableTrigger = oldV;
				}
			}
		}
	}

	private static map<Id,Account> mapAccount;
	private static map<Id,AcctSeed__Accounting_Variable__c> mapGlv;
	private static map<String,AcctSeed__Accounting_Variable__c> mapGlv3ByName;

	private static void refreshStatics(list<AcctSeed__Account_Payable__c> listNew)
	{
		if(mapGlv == null)
		{
			mapAccount = new map<Id,Account>();
			mapGlv = new map<Id,AcctSeed__Accounting_Variable__c>();
			mapGlv3ByName = new map<String,AcctSeed__Accounting_Variable__c>();
		}

		set<Id> setIdAccount = new set<Id>();
		set<Id> setIdGlv = new set<Id>();
		set<String> setNameGlv = new set<String>();
		
		if(!mapGlv.containsKey(gcConstants.idGlv3Ontario))
			setIdGlv.add(gcConstants.idGlv3Ontario);

		for(AcctSeed__Account_Payable__c ap : listNew)
		{
			if(ap.GL_Account_Variable_3__c != null && !mapGlv.containsKey(ap.GL_Account_Variable_3__c))
				setIdGlv.add(ap.GL_Account_Variable_3__c);
			if(ap.AcctSeed__Vendor__c != null && !mapAccount.containsKey(ap.AcctSeed__Vendor__c))
				setIdAccount.add(ap.AcctSeed__Vendor__c);				
		}

		if(!setIdAccount.isEmpty())
        for(Account a :
        	[SELECT Id,
        		BillingState
        	 FROM Account
        	 WHERE Id IN :setIdAccount])
        {
        	mapAccount.put(a.Id,a);
        	if(a.BillingState != null && !mapGlv3ByName.containsKey(a.BillingState))
        		setNameGlv.add(a.BillingState);
        }

		setIdGlv.remove(null);
		if(!setIdGlv.isEmpty() || !setNameGlv.isEmpty())
		{
			for(AcctSeed__Accounting_Variable__c glv : 
				[SELECT Id,
						Name,
						Tax_is_Harmonized__c,
						Tax_Rate_Provincial__c,
						Tax_Rate_Retail__c,
						AcctSeed__Type__c
				 FROM AcctSeed__Accounting_Variable__c
				 WHERE Id IN :setIdGlv OR Name IN:setNameGlv])
			{
				mapGlv.put(glv.Id,glv);
	        	if(glv.AcctSeed__Type__c.equals('GL Account Variable 3'))
	        		mapGlv3ByName.put(glv.Name,glv);
			}
		}
	}
	
}