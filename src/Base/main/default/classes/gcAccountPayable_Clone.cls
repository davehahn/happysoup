public with sharing class gcAccountPayable_Clone {
	public gcAccountPayable_Clone() {}
	
	public gcAccountPayable_Clone(ApexPages.StandardController stc){
		idFilter = stc.getId();
		retUrl = '/'+stc.getId();
	}

	public gcAccountPayable_Clone(ApexPages.StandardSetController ssc){
		retUrl = ApexPages.currentPage().getParameters().get('retUrl');
	}

	public pageReference back()
	{
		return new pageReference(retUrl);
	}
	
	public pageReference init()
	{
		if(idFilter == null)
			idFilter = ApexPages.currentPage().getParameters().get('idFilter');

		cloneType = ApexPages.currentPage().getParameters().get('cloneType');

		if(idFilter == null)
		{
	 		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'No AP was selected to Clone from.'));
	 		return null;					
	 	}

		if(retUrl == null && idFilter != null)
			retUrl = '/'+idFilter;
		
		return createClone();
	}
	
    @testVisible
	private Id idFilter{get;set;}
	private String cloneType{get;set;}
    @testVisible
	private String retUrl{get;set;}
	
	public pageReference createClone()
	{
		for(AcctSeed__Account_Payable__c ap :
			[SELECT 
				Id, 
				//Name, 
				//AcctSeed__Accounting_Period__c, 
				//AcctSeed__Accounting_Year__c, 
				//AcctSeed__Age__c, 
				//AcctSeed__AP_Control_Override__c, 
				//AcctSeed__AP_Disbursement_Count__c, 
				//AcctSeed__Balance__c, 
				AcctSeed__Closed_Accounting_Period__c, 
				AcctSeed__Contact__c, 
				AcctSeed__Credit_Memo_Applied_Amount__c, 
				AcctSeed__Date__c, 
				AcctSeed__Discount_Amount__c, 
				AcctSeed__Due_Date__c, 
				AcctSeed__Employee__c, 
				//AcctSeed__Line_Count__c, 
				//AcctSeed__Net_Amount__c, 
				//AcctSeed__Paid_Amount__c, 
				//AcctSeed__Payee__c, 
				AcctSeed__Payee_Reference__c, 
				AcctSeed__Payment_Status__c, 
				AcctSeed__Recurring_Account_Payable__c, 
				AcctSeed__Status__c, 
				//AcctSeed__Total__c, 
				//AcctSeed__Type__c, 
				AcctSeed__Vendor__c, 
				AcctSeedERP__Purchase_Order__c, 
				GL_Account_Variable_3__c, 
				//GMBLASG__Posted__c, 
				//Payee_New__c, 
				Tax_Amount_Federal__c, 
				Tax_Amount_Fixed__c, 
				Tax_Amount_Provincial__c, 
				Tax_Amount_Retail__c, 
				Tax_is_Harmonized__c, 
				Tax_Override__c, 
				Tax_Rate_Federal__c, 
				Tax_Rate_Provincial__c, 
				Tax_Rate_Retail__c, 
				//Vendor_Payee__c,				
				(SELECT 
					Id, 
					//Name, 
					//AcctSeed__Account__c, 
					AcctSeed__Amount__c, 
					//AcctSeed__Billable__c, 
					//AcctSeed__Credit_Card_Payee__c, 
					AcctSeed__Date__c, 
					AcctSeed__GL_Account_Variable_2__c, 
					Description__c, 
					AcctSeed__Expense_GL_Account__c, 
					Expense_Revenue_GL_Account__c, 
					AcctSeed__GL_Account_Variable_4__c, 
					AcctSeed__Internal_Comment__c, 
					AcctSeed__Invoice_Comment__c, 
					AcctSeed__GL_Account_Variable_1__c, 
					AcctSeed__Account_Payable__c, 
					AcctSeed__Product__c, 
					AcctSeed__Project__c, 
					AcctSeed__Project_Task__c, 
					AcctSeedERP__Purchase_Order_Line__c, 
					AcctSeed__Quantity__c, 
					AcctSeed__GL_Account_Variable_3__c, 
					Taxable_Federal__c, 
					Taxable_Provincial__c, 
					Taxable_Retail__c 
				FROM AcctSeed__Project_Account_Payable_Lines__r) 
 			FROM AcctSeed__Account_Payable__c 
			WHERE Id =:idFilter])
		{
			AcctSeed__Account_Payable__c newAP = ap.clone(false,true);
			newAP.AcctSeed__Date__c = Date.today();
			newAP.Tax_Override__c = true;
			newAP.AcctSeed__Payee_Reference__c = ap.AcctSeed__Payee_Reference__c + '-clone-' + System.now().format();
			try{
				insert newAP;
				List<AcctSeed__Account_Payable_Line__c> listAPL = new List<AcctSeed__Account_Payable_Line__c>();
				for(AcctSeed__Account_Payable_Line__c apl : ap.AcctSeed__Project_Account_Payable_Lines__r)
				{
					AcctSeed__Account_Payable_Line__c newAPL = apl.clone(false,true);
					newAPL.AcctSeed__Account_Payable__c = newAP.Id;
					newAPL.AcctSeed__Date__c = Date.today();
					if(cloneType == 'reverse')
						newAPL.AcctSeed__Amount__c = apl.AcctSeed__Amount__c * -1;
					listAPL.add(newAPL);
				}
				if(!listAPL.isEmpty())
					insert listAPL;
				return new pageReference('/'+newAP.Id);
			}
			catch(Exception e)
			{
				ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage()));
				return null;
			}
		}

		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'No AP was found to clone from.'));
		return null;
	}

	
}