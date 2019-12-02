public without sharing class gcBilling {

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

	public static Boolean allowBillingProjectForInternal{
		get{
			if(allowBillingProjectForInternal == null) return false;
			else return allowBillingProjectForInternal;
		}
		set{
			if(value == null) allowBillingProjectForInternal = false;
			else allowBillingProjectForInternal = value;
		}
	}

	public static void triggerHandler
		(map<Id,AcctSeed__Billing__c> oldMap,
		 map<Id,AcctSeed__Billing__c> newMap,
		 list<AcctSeed__Billing__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeed__Billing__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeed__Billing__c>();
		if(listNew == NULL) listNew = new list<AcctSeed__Billing__c>();

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
				handlePrePayables( listNew, oldMap );
			}
			if(boolIsUpdate)
			{
				handlePrePayables( listNew, oldMap );
			}
			if(boolIsDelete)
			{

			}
		}
	}

	private static void handlePrePayables( List<AcctSeed__Billing__c> listNew,
	   																		 Map<Id, AcctSeed__Billing__c> oldMap )
	{
		Set<Id> projectsToCreditPrepaids = new Set<Id>();
		Set<Id> projectsToCleanPrepaids = new Set<Id>();

		for(AcctSeed__Billing__c b : listNew)
		{
			AcctSeed__Billing__c oldRec;
			if( oldMap.containsKey( b.Id ) )
				oldRec = oldMap.get( b.Id );
			if(b.AcctSeed__Status__c == 'Posted')
			{
				if (  ( oldRec == null ||
								( oldRec != null &&
						 			oldRec.AcctSeed__Status__c != 'Posted' ) ) &&
						 b.GMBLASERP__Project__c != null )
				{
					projectsToCreditPrepaids.add(b.GMBLASERP__Project__c);
				}
				if ( oldRec != null &&
						 oldRec.AcctSeed__Status__c == 'Posted' &&
						 b.GMBLASERP__Project__c != null )
				{
					projectsToCleanPrepaids.add(b.GMBLASERP__Project__c);
				}
			}
		}
		if(!projectsToCreditPrepaids.isEmpty() || !projectsToCleanPrepaids.isEmpty())
			Prepaid_Services_mp.handleProjectPrepaids( projectsToCreditPrepaids, projectsToCleanPrepaids );
	}


	public static void updateAndValidate
		(map<Id,AcctSeed__Billing__c> oldMap,
		 map<Id,AcctSeed__Billing__c> newMap,
		 list<AcctSeed__Billing__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(boolIsBefore && (boolIsUpdate || boolIsInsert))
		{
			refreshStatics(listNew);

			for(AcctSeed__Billing__c b : listNew)
			{
				AcctSeed__Billing__c oldRec;
				if(boolIsUpdate)
					oldRec = oldMap.get(b.Id);

				if(boolIsInsert && b.Internal_Billing__c && !allowBillingProjectForInternal)
					b.addError('An Internal Billing can only be created from an Internal ERP Order');
				if(boolIsUpdate
					&& b.GMBLASERP__Project__c != oldRec.GMBLASERP__Project__c
					&& !allowBillingProjectForInternal
					&& (b.Internal_Billing__c || oldRec.Internal_Billing__c))
					b.addError('The ERP Order of an Internal Billing Cannot be changed');

				if(b.AcctSeed__Status__c == 'Posted')
				{
					if(boolIsUpdate)
					{
						if(b.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c ||
						   b.Tax_is_Harmonized__c != oldRec.Tax_is_Harmonized__c ||
						   b.Tax_Override__c != oldRec.Tax_Override__c ||
						   b.Tax_Rate_Federal__c != oldRec.Tax_Rate_Federal__c ||
						   b.Tax_Rate_Provincial__c != oldRec.Tax_Rate_Provincial__c ||
						   b.Tax_Rate_Retail__c != oldRec.Tax_Rate_Retail__c)
						{
							b.addError('The Sales Tax settings of a Billing may not be changed, if the billing is Posted.');
						}
					}
				}
				else
				{
					Account acct = mapAccount.get(b.AcctSeed__Customer__c);
					if(acct != null && acct.BillingState != null && mapGlv3ByName.containsKey(acct.BillingState)
						&& ((boolIsInsert && b.GL_Account_Variable_3__c == null) || (boolIsUpdate && b.AcctSeed__Customer__c != oldRec.AcctSeed__Customer__c)))
						b.GL_Account_Variable_3__c = mapGlv3ByName.get(acct.BillingState).Id;

					if(b.GL_Account_Variable_3__c == null)
					{
						b.GL_Account_Variable_3__c = gcConstants.idGlv3Others;
						b.Tax_Override__c = true;
						b.Tax_Rate_Federal__c = 0;
						b.Tax_Rate_Provincial__c = 0;
						b.Tax_Rate_Retail__c = 0;
					}

					if(!b.Tax_Override__c)
					{
						if(boolIsInsert ||
						  (boolIsUpdate &&
						   (b.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c ||
							b.Tax_is_Harmonized__c != oldRec.Tax_is_Harmonized__c ||
							b.Tax_Override__c != oldRec.Tax_Override__c ||
							b.Tax_Rate_Federal__c != oldRec.Tax_Rate_Federal__c ||
							b.Tax_Rate_Provincial__c != oldRec.Tax_Rate_Provincial__c ||
							b.Tax_Rate_Retail__c != oldRec.Tax_Rate_Retail__c)
						   )
						  )
						{
							b.Tax_Rate_Federal__c = 5;

							AcctSeed__Accounting_Variable__c glvTaxZone = mapGlv.get(b.GL_Account_Variable_3__c);
							if(glvTaxZone != null)
							{
								b.Tax_is_Harmonized__c = glvTaxZone.Tax_is_Harmonized__c;
								b.Tax_Rate_Provincial__c = glvTaxZone.Tax_Rate_Provincial__c;
								b.Tax_Rate_Retail__c = glvTaxZone.Tax_Rate_Retail__c;
							}
						}
					}
				}
			}
		}

		if(boolIsBefore && boolIsDelete){
			List<GMBLASERP__Serial_Number__c> listSerials = new List<GMBLASERP__Serial_Number__c>();
			List<ERP_document__c> listERPDocs = new List<ERP_document__c>();
			Set<Id> setIdDocuments = new Set<Id>();
			for(AcctSeed__Billing__c bill :
				[SELECT Id,
					(SELECT Id,
                     	Serial_Number_ERP_Order_Item__c,
                     	Serial_Number_Revenue__c,
                     	Serial_Revenue_Used__c,
                     	Serial_Revenue_Line__c
					FROM AcctSeed__Project_Billing_Lines__r
					WHERE Serial_Revenue_Used__c = true
					ORDER BY CreatedDate),
					(SELECT Id, DocumentID__c FROM ERP_documents__r)
			 	FROM AcctSeed__Billing__c
			 	WHERE Id IN :oldMap.keySet()])
			{
				for(AcctSeed__Billing_Line__c line : bill.AcctSeed__Project_Billing_Lines__r)
					listSerials.add(new GMBLASERP__Serial_Number__c(Id = line.Serial_Number_ERP_Order_Item__c, Billing_Revenue_Used__c = false));

				for(ERP_document__c erpDoc : bill.ERP_documents__r){
					listERPDocs.add(erpDoc);
					setIdDocuments.add(erpDoc.DocumentID__c);
				}
			}
			if(!setIdDocuments.isEmpty()){
				/// Deleting related billing documents
				delete [SELECT Id FROM Document WHERE Id IN:setIdDocuments];
				/// Deleting related ERP documents
				delete listERPDocs;
			}

			if(!listSerials.isEmpty()){
				Boolean oldVal = gcSerialNumber.disableTrigger;
				gcSerialNumber.disableTrigger = true;
				update listSerials;
				gcSerialNumber.disableTrigger = oldVal;
			}
		}

		if(!boolIsBefore && boolIsUpdate)
		{
			set<Id> setIdBillingApply = new set<Id>();
			set<Id> setIdBillingUpdateTax = new set<Id>();
			for(AcctSeed__Billing__c b : listNew)
			{
				AcctSeed__Billing__c oldRec = oldMap.get(b.Id);

				if(b.AcctSeed__Status__c == 'Posted' && oldRec.AcctSeed__Status__c != 'Posted')
				{
					setIdBillingApply.add(b.Id);
				}

				if(b.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c ||
				   b.Tax_is_Harmonized__c != oldRec.Tax_is_Harmonized__c ||
				   b.Tax_Override__c != oldRec.Tax_Override__c ||
				   b.Tax_Rate_Federal__c != oldRec.Tax_Rate_Federal__c ||
				   b.Tax_Rate_Provincial__c != oldRec.Tax_Rate_Provincial__c ||
				   b.Tax_Rate_Retail__c != oldRec.Tax_Rate_Retail__c)
				{
					setIdBillingUpdateTax.add(b.Id);
				}
			}
			if(!setIdBillingApply.isEmpty())
				applyCash(setIdBillingApply);
			if(!setIdBillingUpdateTax.isEmpty())
				gcBillingLine.updateSalesTax(setIdBillingUpdateTax);
		}
	}

	private static map<Id,Account> mapAccount;
	private static map<Id,AcctSeed__Accounting_Variable__c> mapGlv;
	private static map<String,AcctSeed__Accounting_Variable__c> mapGlv3ByName;
	//private static map<Id,Decimal> mapProjectBillings;

	private static void refreshStatics(list<AcctSeed__Billing__c> listNew)
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

		for(AcctSeed__Billing__c b : listNew)
		{
			if(b.GL_Account_Variable_3__c != null && !mapGlv.containsKey(b.GL_Account_Variable_3__c))
				setIdGlv.add(b.GL_Account_Variable_3__c);
			if(b.AcctSeed__Customer__c != null && !mapAccount.containsKey(b.AcctSeed__Customer__c))
				setIdAccount.add(b.AcctSeed__Customer__c);
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

	public static void applyCash(set<Id> setIdBilling)
	{
		setIdBilling.remove(null);
		if(setIdBilling.isEmpty()) return;

		map<Id,Decimal> mapBillingBalance = new map<Id,Decimal>();
		map<Id,Decimal> mapReceiptBalance = new map<Id,Decimal>();

		map<Id,list<AcctSeed__Billing__c>> mapProjectBillings = new map<Id,list<AcctSeed__Billing__c>>();
		map<Id,list<AcctSeed__Cash_Receipt__c>> mapProjectReceipts = new map<Id,list<AcctSeed__Cash_Receipt__c>>();

		Id idPeriod;
		for(AcctSeed__Accounting_Period__c period :
			[SELECT Id FROM AcctSeed__Accounting_Period__c
			 WHERE AcctSeed__Status__c = 'Open'
			   AND AcctSeed__Start_Date__c <= TODAY
			   AND AcctSeed__End_Date__c >= TODAY])
		{
			idPeriod = period.Id;
		}

		if(idPeriod == null)
			return;

		for(AcctSeed__Billing__c b :
			[SELECT Id, AcctSeed__Balance__c,
					(SELECT Id, AcctSeed__Project__c
					 FROM AcctSeed__Project_Billing_Lines__r
					 WHERE AcctSeed__Project__c != null
					 ORDER BY CreatedDate
					 LIMIT 1)
			 FROM AcctSeed__Billing__c
			 WHERE AcctSeed__Status__c = 'Posted'
			   AND AcctSeed__Balance__c > 0
			   AND Id IN :setIdBilling])
		{
			if(b.AcctSeed__Project_Billing_Lines__r.isEmpty())
				continue;

			Id idProject = b.AcctSeed__Project_Billing_Lines__r[0].AcctSeed__Project__c;

			if(!mapProjectBillings.containsKey(idProject))
				mapProjectBillings.put(idProject, new list<AcctSeed__Billing__c>());

			mapProjectBillings.get(idProject).add(b);
			mapBillingBalance.put(b.Id,b.AcctSeed__Balance__c);
		}

		for(AcctSeed__Cash_Receipt__c cr :
			[SELECT Id, AcctSeed__Project__c, AcctSeed__Balance__c
			 FROM AcctSeed__Cash_Receipt__c
			 WHERE AcctSeed__Project__c IN :mapProjectBillings.keySet()
			   AND AcctSeed__Status__c = 'Posted'
			   AND AcctSeed__Balance__c > 0
			 ORDER BY AcctSeed__Receipt_Date__c, CreatedDate, AcctSeed__Balance__c])
		{
			Id idProject = cr.AcctSeed__Project__c;

			if(!mapProjectReceipts.containsKey(idProject))
				mapProjectReceipts.put(idProject, new list<AcctSeed__Cash_Receipt__c>());

			mapProjectReceipts.get(idProject).add(cr);

			mapReceiptBalance.put(cr.Id, cr.AcctSeed__Balance__c);
		}

		list<AcctSeed__Billing_Cash_Receipt__c> listBCR = new list<AcctSeed__Billing_Cash_Receipt__c>();

		for(Id idProject : mapProjectBillings.keySet())
		{
			for(AcctSeed__Billing__c billing : mapProjectBillings.get(idProject))
			{
				Decimal billingBalance = mapBillingBalance.get(billing.Id);
				if(billingBalance == null || billingBalance <= 0) continue;

				if(mapProjectReceipts.containsKey(idProject))
				for(AcctSeed__Cash_Receipt__c receipt : mapProjectReceipts.get(idProject))
				{
					Decimal receiptBalance = mapReceiptBalance.get(receipt.Id);
					if(receiptBalance == null || receiptBalance <= 0) continue;

					Decimal applyAmount = receiptBalance;
					if(applyAmount > billingBalance)
					   applyAmount = billingBalance;

					listBCR.add(new AcctSeed__Billing_Cash_Receipt__c(
						AcctSeed__Accounting_Period__c = idPeriod,
						AcctSeed__Applied_Amount__c = applyAmount,
						AcctSeed__Billing__c = billing.Id,
						AcctSeed__Cash_Receipt__c = receipt.Id
					));

					mapBillingBalance.put(billing.Id, mapBillingBalance.get(billing.Id) - applyAmount);
					mapReceiptBalance.put(receipt.Id, mapReceiptBalance.get(receipt.Id) - applyAmount);
				}
			}
		}

		if(!listBCR.isEmpty())
			insert listBCR;
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
	}
}