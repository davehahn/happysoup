public with sharing class gcBilling_Clone {
	public gcBilling_Clone() {}
	
	public gcBilling_Clone(ApexPages.StandardController stc){
		idFilter = stc.getId();
		retUrl = '/'+stc.getId();
	}

	public gcBilling_Clone(ApexPages.StandardSetController ssc){
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
	 		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'No Billing was selected to Clone FROM.'));
	 		return null;					
	 	}

		if(retUrl == null && idFilter != null)
			retUrl = '/'+idFilter;
		
		return createClone();
	}
	
	private Id idFilter{get;set;}
	private String cloneType{get;set;}
	private String retUrl{get;set;}
	
	public pageReference createClone()
	{
		for(AcctSeed__Billing__c bill :
			[SELECT 
				Id, 
				Name, 
				//OwnerId,
				//AcctSeed__Accounting_Period__c, 
				//AcctSeed__Accounting_Year__c, 
				AcctSeed__Billing_City__c, 
				AcctSeed__Billing_Comment__c, 
				AcctSeed__Billing_Contact__c, 
				AcctSeed__Billing_Country__c, 
				AcctSeed__Billing_Cycle_End_Date__c, 
				AcctSeed__Billing_Cycle_Start_Date__c, 
				AcctSeed__Billing_Format__c, 
				AcctSeed__Billing_PostalCode__c, 
				AcctSeed__Billing_State__c, 
				AcctSeed__Billing_Street__c, 
				AcctSeed__Billing_Terms_Name__c, 
				AcctSeed__Customer__c, 
				//AcctSeed__Date__c, 
				//AcctSeed__Discount_Amount__c, 
				//AcctSeed__Discount_Due_Date__c, 
				AcctSeed__Discount_Percent__c, 
				//AcctSeed__Due_Date2__c, 
				//AcctSeed__Due_Date__c, 
				AcctSeed__Line_Count__c, 
				AcctSeed__Opportunity__c, 
				AcctSeed__PDF_Email_Status__c, 
				AcctSeed__PO_Number__c, 
				AcctSeed__Proprietary_Billing_Number__c, 
				AcctSeed__Recurring_Billing__c, 
				AcctSeed__Shipping_City__c, 
				AcctSeed__Shipping_Contact__c, 
				AcctSeed__Shipping_Country__c, 
				AcctSeed__Shipping_PostalCode__c, 
				AcctSeed__Shipping_State__c, 
				AcctSeed__Shipping_Street__c, 
				AcctSeed__Status__c, 
				AcctSeed__Total__c, 
				AcctSeedERP__Sales_Order__c, 
				GL_Account_Variable_3__c, 
				GMBLASERP__Project__c, 
				Tax_is_Harmonized__c, 
				Tax_Override__c, 
				Tax_Rate_Federal__c, 
				Tax_Rate_Provincial__c, 
				Tax_Rate_Retail__c,
				(SELECT 
					Id, 
					AcctSeed__Billing__c, 
					AcctSeed__Comment__c, 
					//AcctSeed__Date__c, 
					AcctSeed__Discount_Pct__c, 
					AcctSeed__Discount_Amt__c, 
					AcctSeed__Project__c, 
					GMBLASERP__Material__c, 
					AcctSeed__Project_Task__c, 
					AcctSeed__Employee__c, 
					AcctSeed__Expense_GL_Account__c, 
					AcctSeed__List_Price__c, 
					AcctSeed__Product__c, 
					AcctSeed__Product_Unit_Cost__c, 
					AcctSeed__Hours_Units__c, 
					AcctSeed__Rate__c, 
					AcctSeed__Revenue_GL_Account__c, 
					AcctSeedERP__Sales_Order_Line__c, 
					Taxable_Federal__c, 
					Taxable_Provincial__c, 
					Taxable_Retail__c, 
					AcctSeed__GL_Account_Variable_1__c, 
					AcctSeed__GL_Account_Variable_2__c, 
					AcctSeed__GL_Account_Variable_3__c, 
					AcctSeed__GL_Account_Variable_4__c, 
					AcctSeed__Time_Card_Variable_1__c, 
					AcctSeed__Time_Card_Variable_2__c, 
					AcctSeed__Total__c 
				FROM AcctSeed__Project_Billing_Lines__r)			
			FROM AcctSeed__Billing__c
			WHERE Id =:idFilter])
		{
			AcctSeed__Billing__c newBill = bill.clone(false,true);
			newBill.Tax_Override__c = true;
			insert newBill;
			List<AcctSeed__Billing_Line__c> listBL = new List<AcctSeed__Billing_Line__c>();
			for(AcctSeed__Billing_Line__c blLine : bill.AcctSeed__Project_Billing_Lines__r)
			{
				AcctSeed__Billing_Line__c newBL = blLine.clone(false,true);
				newBL.AcctSeed__Billing__c = newBill.Id;
				if(cloneType == 'reverse')
					newBL.AcctSeed__Hours_Units__c = blLine.AcctSeed__Hours_Units__c * -1;

				listBL.add(newBL);
			}
			if(!listBL.isEmpty())
				insert listBL;
			return new pageReference('/'+newBill.Id);
		}
		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'No Billing was found to clone from.'));
		return null;
	}


}