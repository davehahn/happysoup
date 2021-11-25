public without sharing class gcCashDisbursement {

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
		(map<Id,AcctSeed__Cash_Disbursement__c> oldMap,
		 map<Id,AcctSeed__Cash_Disbursement__c> newMap,
		 list<AcctSeed__Cash_Disbursement__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeed__Cash_Disbursement__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeed__Cash_Disbursement__c>();
		if(listNew == NULL) listNew = new list<AcctSeed__Cash_Disbursement__c>();

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
		(map<Id,AcctSeed__Cash_Disbursement__c> oldMap,
		 map<Id,AcctSeed__Cash_Disbursement__c> newMap,
		 list<AcctSeed__Cash_Disbursement__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(boolIsBefore && (boolIsUpdate || boolIsInsert))
		{
			retrieveStatics(listNew);
			User usr = mapUser.get(UserInfo.getUserId());
			String glv1Name = usr.GL_Account_Variable_1__c;
			for(AcctSeed__Cash_Disbursement__c cd : listNew)
			{
                //cd.AcctSeed__Ledger__c = 'a121D000001muWMQAY';
				if(!cd.GMBLASG__Posted__c){
					if(cd.AcctSeed__Reference__c != null && cd.AcctSeed__Reference__c.contains('refund')) {
						cd.AcctSeed__Cash_Flow_Category__c = gcConstants.idGlRevenueCF;
					}
					/// SFISSUES-970
					if(cd.AcctSeed__Bank_Account__c == gcConstants.idGlCCPayable && cd.AcctSeed__GL_Account_Variable_4__c == null){
						cd.addError('For Company Credit Card a GL Variable 4 must be selected.');
					}
					/// SFISSUES-778
					if(cd.AcctSeed__Check_Number__c != null && cd.AcctSeed__Bank_Account__c != null){
						cd.Unique_Check_Number__c = cd.AcctSeed__Bank_Account__c + String.valueOf(cd.AcctSeed__Check_Number__c);
					}
				}
				if(!cd.GMBLASG__Posted__c && (boolIsInsert || (boolIsUpdate && cd.AcctSeed__Bank_Account__c == null))) {
					System.debug('Not Posted');
					setBankGL(cd);
				}
				if(boolIsUpdate) {
					AcctSeed__Cash_Disbursement__c oldRec = oldMap.get(cd.Id);

					System.debug('cd');
					System.debug(cd);
					System.debug('oldRec');
					System.debug(oldRec);

					if (cd.GMBLASG__Posted__c) {
						if (cd.AcctSeed__Check_Number__c != oldRec.AcctSeed__Check_Number__c)
							cd.addError('You cannot update the Check Number on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__Reference__c != oldRec.AcctSeed__Reference__c)
							cd.addError('You cannot update the Reference on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__Type__c != oldRec.AcctSeed__Type__c)
							cd.addError('You cannot update the Type on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__Employee__c != oldRec.AcctSeed__Employee__c)
							cd.addError('You cannot update the Employee on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__Contact__c != oldRec.AcctSeed__Contact__c)
							cd.addError('You cannot update the Contact on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__Vendor__c != oldRec.AcctSeed__Vendor__c)
							cd.addError('You cannot update the Vendor on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__GL_Account_Variable_1__c != oldRec.AcctSeed__GL_Account_Variable_1__c)
							cd.addError('You cannot update the GL Variable 1 on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__GL_Account_Variable_2__c != oldRec.AcctSeed__GL_Account_Variable_2__c)
							cd.addError('You cannot update the GL Variable 2 on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__GL_Account_Variable_3__c != oldRec.AcctSeed__GL_Account_Variable_3__c)
							cd.addError('You cannot update the GL Variable 3 on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__GL_Account_Variable_4__c != oldRec.AcctSeed__GL_Account_Variable_4__c)
							cd.addError('You cannot update the GL Variable 4 on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__Bank_Account__c != oldRec.AcctSeed__Bank_Account__c)
							cd.addError('You cannot update the Bank on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__Debit_GL_Account__c != oldRec.AcctSeed__Debit_GL_Account__c)
							cd.addError('You cannot update the Debit GL on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__Disbursement_Date__c != oldRec.AcctSeed__Disbursement_Date__c)
							cd.addError('You cannot update the Disbursement Date on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__Project__c != oldRec.AcctSeed__Project__c)
							cd.addError('You cannot update the ERP on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__Project_Task__c != oldRec.AcctSeed__Project_Task__c)
							cd.addError('You cannot update the ERP Task on a posted record. You must unpost the record to edit any of these fields.');
						if (cd.AcctSeed__Source__c != oldRec.AcctSeed__Source__c)
							cd.addError('You cannot update the Source on a posted record. You must unpost the record to edit any of these fields.');
					}
				}

		        if(cd.AcctSeed__GL_Account_Variable_1__c == null
		        	&& !cd.GMBLASG__Posted__c
		        	&& glv1Name != null)
		        	cd.AcctSeed__GL_Account_Variable_1__c = mapGlv1ByName.get(glv1Name).Id;				
			}
		}
	}

	private static void setBankGL(AcctSeed__Cash_Disbursement__c cd)
	{
		String paymentMethod = cd.AcctSeed__Type__c;
        system.debug('Payment Method ---> ' + paymentMethod);
		if(paymentMethod == 'MasterCard'
			|| paymentMethod == 'Visa'
			|| paymentMethod == 'Debit'
			|| paymentMethod == 'Credit Card'
			|| paymentMethod == 'Accord D')
			cd.AcctSeed__Bank_Account__c = gcConstants.idGlMerchantDebitCredit;
		else if(paymentMethod == 'Cheque'
			|| paymentMethod == 'Check'
			|| paymentMethod == 'Draft')
			cd.AcctSeed__Bank_Account__c = gcConstants.idGlRBCCDN;
		else if(paymentMethod == 'Company Credit Card')
			cd.AcctSeed__Bank_Account__c = gcConstants.idGlCCPayable;
		else if(paymentMethod == 'Cash')
			cd.AcctSeed__Bank_Account__c = gcConstants.idGlCashFloat;
		else if(paymentMethod == 'Wire' || paymentMethod == 'US Check')
			cd.AcctSeed__Bank_Account__c = gcConstants.idGlRBCUS;
		else if(paymentMethod == 'Legend Bucks')
			cd.AcctSeed__Bank_Account__c = gcConstants.idGlLegendBucks;
		else if(paymentMethod == 'Online Store')
			cd.AcctSeed__Bank_Account__c = gcConstants.idGlMerchantOnline;
		else if(paymentMethod == 'Financed')
			cd.AcctSeed__Bank_Account__c = gcConstants.idGlWellsFargoLoan;
		else
			cd.AcctSeed__Bank_Account__c = gcConstants.idGlRBCCDN;
	}

	private static map<String,AcctSeed__Accounting_Variable__c> mapGlv1ByName;
	private static map<Id,User> mapUser;
	private static void retrieveStatics(list<AcctSeed__Cash_Disbursement__c> listNew)
	{
        set<String> setNameGlv = new set<String>();

        if(mapGlv1ByName == null)
        {
            mapGlv1ByName = new map<String,AcctSeed__Accounting_Variable__c>();
            mapUser = new map<Id,User>();
        }

        for(User u : [SELECT Id, GL_Account_Variable_1__c FROM User WHERE Id =:UserInfo.getUserId()])
        {
            if(u.GL_Account_Variable_1__c != null)
                setNameGlv.add(u.GL_Account_Variable_1__c);

            mapUser.put(u.Id, u);
        }

        if(!setNameGlv.isEmpty())
        for(AcctSeed__Accounting_Variable__c glv :
            [SELECT Id,
                    Name,
                    Tax_is_Harmonized__c,
                    Tax_Rate_Provincial__c,
                    Tax_Rate_Retail__c,
                    GL_Account_Variable_3__c,
                    AcctSeed__Type__c
             FROM AcctSeed__Accounting_Variable__c
             WHERE Name IN:setNameGlv])
        {
            if(glv.AcctSeed__Type__c.equals('GL Account Variable 1'))
                mapGlv1ByName.put(glv.Name,glv);
        }
	}
}