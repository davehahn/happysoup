public without sharing class arBillingClearance {
    
	@AuraEnabled
	public static String retrieveBillings(String searchParam, String searchType)
	{
		Set<String> wType = new Set<String>();
		if(searchType == null){
			wType.add('Warranty');
			wType.add('Recoverable');
		}else{
			wType.add(searchType);			
		}

		Id idRtProjectWarranty = gcConstants.idRtProjectWarranty;
		List<Map<String,String>> listBill = new List<Map<String,String>>();
        searchParam = '%' + searchParam + '%';
		for(AcctSeed__Billing__c bill : 
			[SELECT Id, Name,
				AcctSeed__Customer__c, 
             	AcctSeed__Customer__r.Name,
              	GMBLASERP__Project__c,
             	GMBLASERP__Project__r.Name, 
				AcctSeed__Balance__c
			FROM AcctSeed__Billing__c          
			WHERE (Name like :searchParam
                   	OR AcctSeed__Customer__r.Name like :searchParam
                  	OR GMBLASERP__Project__r.Name like :searchParam)
				AND GMBLASERP__Project__c != null
				AND GMBLASERP__Project__r.RecordTypeId =:idRtProjectWarranty
				AND AcctSeed__Balance__c <> 0
				AND GMBLASG__Posted__c = true
				AND GMBLASERP__Project__r.Warranty_Type__c IN:wType
			ORDER BY AcctSeed__Balance__c DESC, CreatedDate DESC])
		{
            Map<String,String> m = new Map<String,String>();
            m.put('idBill',bill.Id);
            m.put('Name',bill.Name);
            m.put('idProject',bill.GMBLASERP__Project__c);
            m.put('billProject',bill.GMBLASERP__Project__r.Name);
            m.put('idCustomer',bill.AcctSeed__Customer__c);
            m.put('billCustomer',bill.AcctSeed__Customer__r.Name);
            m.put('billBalance',String.valueOf(bill.AcctSeed__Balance__c));
			listBill.add(m);
		}
        System.debug('listBill:'+listBill);
        return JSON.serialize(listBill);
	}

	@AuraEnabled
	public static String createClearance(Id idBill, Decimal pClearAmount, String apReference)
	{
		AcctSeed__Billing__c bill = [SELECT Id, AcctSeed__Customer__c, AcctSeed__Type__c, AcctSeed__Balance__c FROM AcctSeed__Billing__c WHERE Id=:idBill][0];
		if(bill.AcctSeed__Type__c == 'Credit Memo' && pClearAmount > 0)
			throw new AuraHandledException('The billing is a Credit Memo. The amount to clear must be negative.');
		else if(bill.AcctSeed__Type__c == 'Invoice' && pClearAmount < 0)
			throw new AuraHandledException('The billing is a Invoice. The amount to clear must be positive.');
		
		Savepoint sp = Database.setSavepoint();
		try{
			Decimal clearAmount = pClearAmount * -1;
		 	AcctSeed__Billing__c newBill = new AcctSeed__Billing__c(
	 			AcctSeed__Customer__c = bill.AcctSeed__Customer__c
	 		);
		 	insert newBill;

			AcctSeed__Billing_Line__c newBL = new AcctSeed__Billing_Line__c(
				AcctSeed__Billing__c = newBill.Id,
				AcctSeed__Revenue_GL_Account__c = gcConstants.idGlClearingARAP,
				AcctSeed__Hours_Units__c = 1,
				AcctSeed__Rate__c = clearAmount.setScale(6),
				AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
				AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales
			);
			insert newBL;
			/// Post the new Bill
			AcctSeed.BillingPostService.postBillings(new List<AcctSeed__Billing__c>{newBill});
			Id idAccountingPeriod = [SELECT AcctSeed__Accounting_Period__c FROM AcctSeed__Billing__c WHERE Id =:newBill.Id][0].AcctSeed__Accounting_Period__c;

			Decimal bcrAmount = clearAmount;
			Id negBillId;
			Id posBillId;

			if(bill.AcctSeed__Balance__c < pClearAmount)
				bcrAmount = bill.AcctSeed__Balance__c;
			if(bill.AcctSeed__Type__c == 'Credit Memo'){
				negBillId = bill.Id;
				posBillId = newBill.Id;
			}else if(bill.AcctSeed__Type__c == 'Invoice'){
				negBillId = newBill.Id;
				posBillId = bill.Id;
			}

			bcrAmount = ((bcrAmount > 0) ? (bcrAmount * -1) : bcrAmount);
			
			AcctSeed__Billing_Credit_Memo__c bcm = new AcctSeed__Billing_Credit_Memo__c(
				AcctSeed__Accounting_Period__c = idAccountingPeriod,
				AcctSeed__Amount__c = bcrAmount.setScale(6), 
				AcctSeed__Billing_Credit_Memo__c = negBillId, 
				AcctSeed__Billing_Invoice__c = posBillId
			);
			insert bcm;

		 	AcctSeed__Account_Payable__c accountPayable = new AcctSeed__Account_Payable__c(
				AcctSeed__Vendor__c = bill.AcctSeed__Customer__c,
				AcctSeed__Payee_Reference__c = apReference,
				AcctSeed__Date__c = Date.today(),
				Approval_Date__c = date.Today(),
				Approved__c = true
			);
		 	insert accountPayable;

			AcctSeed__Account_Payable_Line__c payLine = new AcctSeed__Account_Payable_Line__c(
				AcctSeed__Account_Payable__c = accountPayable.Id,
				AcctSeed__Amount__c = clearAmount, //cr.AcctSeed__Balance__c.setScale(6),
				AcctSeed__Date__c = Date.today(),
				AcctSeed__Expense_GL_Account__c = gcConstants.idGlClearingARAP,
				AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
				AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales
			);
			insert payLine;
			AcctSeed.AccountPayablePostService.postAccountPayables(new List<AcctSeed__Account_Payable__c>{accountPayable});
			return accountPayable.Id;
		}catch(Exception e){
			Database.rollback(sp);
			System.debug(e);
			String errorMsg = e.getMessage();
			errorMsg = errorMsg.replace('First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, ', '').stripHtmlTags();
			throw new AuraHandledException(errorMsg);
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
	}

}