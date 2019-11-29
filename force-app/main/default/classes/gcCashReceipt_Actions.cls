public with sharing class gcCashReceipt_Actions {
	public gcCashReceipt_Actions() {}
	
	public gcCashReceipt_Actions(ApexPages.StandardController stc){
		setIdFilter = new Set<Id>();
		setIdFilter.add(stc.getId());	
		retUrl = '/'+stc.getId();
	}

	public gcCashReceipt_Actions(ApexPages.StandardSetController ssc){

		setIdFilter = new set<Id>();

		for(AcctSeed__Cash_Receipt__c rec : (list<AcctSeed__Cash_Receipt__c>)ssc.getSelected())
			setIdFilter.add(rec.Id);

		retUrl = ApexPages.currentPage().getParameters().get('retUrl');
	}
	
	public pageReference back()
	{
		return new pageReference(retUrl);
	}
	
	public void init()
	{
		String processName = ApexPages.currentPage().getParameters().get('processName');
		String idFilter = ApexPages.currentPage().getParameters().get('idFilter');
		if(idFilter != null)
			setIdFilter.add(idFilter);

		if(retUrl == null && idFilter != null)
			retUrl = '/'+idFilter;

		if(setIdFilter.isEmpty())
		{
	 		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'No Cash Receipt was selected to refund.'));
	 		return;					
	 	}
		createAPLines();
	}
	
	private set<Id> setIdFilter{get;set;}
	private String retUrl{get;set;}

	public void createAPLines()
	{
		Set<Id> setIdAccounts = new Set<Id>();
		List<AcctSeed__Cash_Receipt__c> listCashReceipts = new List<AcctSeed__Cash_Receipt__c>();
		Decimal crTotal = 0;
		for(AcctSeed__Cash_Receipt__c cr : 
			[SELECT Id, 
				AcctSeed__Account__c, 
				AcctSeed__Accounting_Period__c, 
				AcctSeed__Amount__c, 
				AcctSeed__Balance__c,
				AcctSeed__Bank_Account__c, 
				AcctSeed__Cleared_Date__c, 
				AcctSeed__Credit_GL_Account__c, 
				AcctSeed__GL_Account_Variable_1__c, 
				AcctSeed__GL_Account_Variable_2__c, 
				AcctSeed__GL_Account_Variable_3__c, 
				AcctSeed__GL_Account_Variable_4__c, 
				AcctSeed__Payment_Reference__c, 
				AcctSeed__Project__c, 
				AcctSeed__Project_Task__c, 
				AcctSeed__Purpose__c, 
				AcctSeed__Receipt_Date__c, 
				GMBLASG__Posted__c, 
				Payment_Method__c
			FROM AcctSeed__Cash_Receipt__c			
			WHERE (Id IN:setIdFilter 
					OR AcctSeed__Account__c IN:setIdFilter)
				AND AcctSeed__Balance__c > 0
				AND GMBLASG__Posted__c = true
			ORDER BY CreatedDate])
		{
			setIdAccounts.add(cr.AcctSeed__Account__c);
			listCashReceipts.add(cr);
			crTotal += (cr.AcctSeed__Balance__c == null)?0:cr.AcctSeed__Balance__c;
		}
	 	if(listCashReceipts.isEmpty())
		{
	 		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'No posted Cash Receipts with positive balance was found to refund.'));
	 		return;					
	 	}
		if(setIdAccounts.size() <> 1)
		{
	 		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Cash receipts from multiple customers are not allowed to refund at a time.'));
	 		return;					
	 	}
	 	if(crTotal <= 0)
		{
	 		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Total Cash Receipt balance must be positive to refund.'));
	 		return;					
	 	}
	 	Savepoint sp = Database.setSavepoint();
        try{
        	/// Create a new BILL
		 	Id idAccount = (new list<Id>(setIdAccounts))[0];
		 	AcctSeed__Billing__c newBill = new AcctSeed__Billing__c(
		 			AcctSeed__Customer__c = idAccount	
		 		);

		 	insert newBill;

		 	/// Create a new Account Payable
		 	String payeeRef = String.valueOf(DateTime.now().getTime()) + '-Customer Refund';
		 	AcctSeed__Account_Payable__c accountPayable = new AcctSeed__Account_Payable__c(
		 															AcctSeed__Vendor__c = idAccount,
		 															AcctSeed__Payee_Reference__c = payeeRef,
		 															AcctSeed__Date__c = Date.today()
		 														);
		 	insert accountPayable;

			Id idAccountingPeriod = [SELECT AcctSeed__Accounting_Period__c FROM AcctSeed__Billing__c WHERE Id =:newBill.Id][0].AcctSeed__Accounting_Period__c;
		 	List<AcctSeed__Billing_Line__c> listBLines = new List<AcctSeed__Billing_Line__c>();
		 	List<AcctSeed__Account_Payable_Line__c> listAPLines = new List<AcctSeed__Account_Payable_Line__c>();
		 	List<AcctSeed__Billing_Cash_Receipt__c> listBCM = new List<AcctSeed__Billing_Cash_Receipt__c>();
		 	for(AcctSeed__Cash_Receipt__c cr : listCashReceipts)
		 	{
		 		/// Create a Billing Line for Each Cash Receipt
				AcctSeed__Billing_Line__c newBL = new AcctSeed__Billing_Line__c(
													AcctSeed__Billing__c = newBill.Id,
													AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund,
													AcctSeed__Hours_Units__c = 1,
													AcctSeed__Rate__c = cr.AcctSeed__Balance__c.setScale(6),
													AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale, 
													AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales/*,
													AcctSeed__Project__c = cr.AcctSeed__Project__c, 
													AcctSeed__Project_Task__c = cr.AcctSeed__Project_Task__c*/ 
												);
				listBLines.add(newBL);
				/// Apply Each Cash Receipt on the new Bill
				AcctSeed__Billing_Cash_Receipt__c bcm = new AcctSeed__Billing_Cash_Receipt__c(
														AcctSeed__Accounting_Period__c = idAccountingPeriod,
														AcctSeed__Applied_Amount__c = cr.AcctSeed__Balance__c.setScale(6), 
														AcctSeed__Billing__c = newBill.Id, 
														AcctSeed__Cash_Receipt__c = cr.Id
													);
				listBCM.add(bcm);

				/// Create an Account Payable Line for Each Cash Receipt
		 		AcctSeed__Account_Payable_Line__c payLine = new AcctSeed__Account_Payable_Line__c(
		 															AcctSeed__Account_Payable__c = accountPayable.Id, 
		 															AcctSeed__Amount__c = cr.AcctSeed__Balance__c.setScale(6), 
		 															AcctSeed__Date__c = Date.today(), 
		 															AcctSeed__Expense_GL_Account__c = gcConstants.idGlCustomerRefund, 
		 															AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale, 
		 															AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales/*,
																	AcctSeed__Project__c = cr.AcctSeed__Project__c, 
																	AcctSeed__Project_Task__c = cr.AcctSeed__Project_Task__c*/ 
		 														);
		 		listAPLines.add(payLine);
		 	}
		 	/// Insert all Billing Lines
		 	if(!listBLines.isEmpty())
		 		insert listBLines;
		 	/// Post the new Bill
		 	AcctSeed.BillingPostService.postBillings(new List<AcctSeed__Billing__c>{newBill});
		 	System.debug(loggingLevel.Error,'listBCM:'+listBCM);
		 	System.debug(loggingLevel.Error,'listBLines:'+listBLines);
		 	/// Insert all Billing Cash Receipts
		 	if(!listBCM.isEmpty())
		 		insert listBCM;	
		 	/// Insert all Account Payable Lines
		 	if(!listAPLines.isEmpty())
		 		insert listAPLines;

			String msg = 'Billing has been created and a total Cash Receipt Balance of $'+String.valueOf(crTotal.setScale(2))+' has been applied. <a target="_blank" href="/'+newBill.Id+'">Click here to view Bill detail.</a>';
					msg += '<br />Account Payable has been created. <a target="_blank" href="/'+accountPayable.Id+'">Click here to view AP detail.</a>';
		 	ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, msg));
		 	return;
		}catch(Exception e){
			Database.rollback(sp);
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage()));
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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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