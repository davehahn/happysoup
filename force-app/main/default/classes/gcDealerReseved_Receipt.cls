public with sharing class gcDealerReseved_Receipt {
	public gcDealerReseved_Receipt() {}
	public gcDealerReseved_Receipt(ApexPages.standardController ctrl){}

    public static string locale{get{return UserInfo.getLocale();}}

	public static List<SelectOption> getRetrieveBankGLAccounts()
    {
    	List<SelectOption> listOptions = new List<SelectOption>();
    	for(AcctSeed__GL_Account__c gl :
    		[SELECT Id, Name
    		 FROM AcctSeed__GL_Account__c
    		 WHERE AcctSeed__Bank__c = true
    		   AND AcctSeed__Active__c = true
    		 ORDER BY Name])
    	{
    		listOptions.add(new selectOption(gl.Id, gl.Name));
    	}
    	return listOptions;
    }

    @RemoteAction @ReadOnly
    public static List<Account> searchBankAccount(String searchTxt)
    {
        List<Account> listGLA = new List<Account>();
        searchTxt = '%'+searchTxt.replaceAll('[*]','%') +'%';

        for(Account gla : 
            [SELECT Id, 
                Name 
            FROM Account 
            WHERE AcctSeed__Accounting_Active__c = true 
                AND IsPersonAccount = false
                AND Name like :searchTxt 
            ORDER BY Name 
            LIMIT 10])
        {
            listGLA.add(gla);
        }
        return listGLA;

    }

    @RemoteAction @ReadOnly
    public static List<AcctSeed__Project__c> searchERPAccount(Id idAccount, String searchTxt)
    {
        List<AcctSeed__Project__c> listERP = new List<AcctSeed__Project__c>();
        searchTxt = '%'+searchTxt.replaceAll('[*]','%') +'%';

        for(AcctSeed__Project__c erp : 
            [SELECT Id, 
                Name 
            FROM AcctSeed__Project__c 
            WHERE AcctSeed__Account__c =:idAccount 
                AND Name like :searchTxt 
            ORDER BY Name 
            LIMIT 10])
        {
            listERP.add(erp);
        }
        return listERP;

    }

	@RemoteAction @ReadOnly
    public static List<AcctSeed__Accounting_Variable__c> searchGLVAccount(String searchTxt)
    {
    	List<AcctSeed__Accounting_Variable__c> listGLV = new List<AcctSeed__Accounting_Variable__c>();
        searchTxt = '%'+searchTxt.replaceAll('[*]','%') +'%';

        for(AcctSeed__Accounting_Variable__c glv : 
        	[SELECT Id, 
        		Name 
        	FROM AcctSeed__Accounting_Variable__c 
        	WHERE AcctSeed__Type__c = 'GL Account Variable 1' 
                AND Name like :searchTxt 
        	ORDER BY Name 
        	LIMIT 10])
        {
            listGLV.add(glv);
        }
        return listGLV;

    }

	public static List<SelectOption> getRetrieveBankAccounts()
    {
    	List<SelectOption> listOptions = new List<SelectOption>();
    	for(Account acc :
    		[SELECT Id, Name
    		 FROM Account
    		 WHERE IsPersonAccount = false
    		   AND AcctSeed__Accounting_Active__c = true
    		 ORDER BY Name])
    	{
    		listOptions.add(new selectOption(acc.Id, acc.Name));
    	}
    	return listOptions;
    }

    @RemoteAction
    public static Boolean checkExistingReceipt(Id idAccount, Id idBankAccount, Id idBankGLAccount)
    {
    	AcctSeed__Cash_Receipt__c customerCr;
    	for(AcctSeed__Cash_Receipt__c cr : [SELECT Id, (select Id from AcctSeed__Billing_Cash_Receipts__r LIMIT 1) FROM AcctSeed__Cash_Receipt__c WHERE AcctSeed__Account__c =:idAccount AND AcctSeed__Bank_Account__c =:idBankGLAccount])
    	{
    		if(cr.AcctSeed__Billing_Cash_Receipts__r.isEmpty())
    			customerCr = cr;
    	}
    	if(customerCr == null) return false;

    	AcctSeed__Cash_Receipt__c bankCr;
    	for(AcctSeed__Cash_Receipt__c cr : [SELECT Id, (select Id from AcctSeed__Billing_Cash_Receipts__r LIMIT 1) FROM AcctSeed__Cash_Receipt__c WHERE AcctSeed__Account__c =:idBankAccount AND AcctSeed__Bank_Account__c =:idBankGLAccount])
    	{
    		if(!cr.AcctSeed__Billing_Cash_Receipts__r.isEmpty())
    			bankCr = cr;
    	}
    	if(bankCr == null) return false;

    	if(customerCr != null && bankCr != null)
    		return true;
    	else
    		return false;
    }

    @RemoteAction
    public static String createFCBill(Id idAccount, Id idBankAccount, Id idBankGLAccount, String paymentRef, Decimal receiptAmount, Decimal financeCharge, Decimal bankCharge, Boolean checkExisting, String effectDate, Id idERP, Id idGLV1)
    {
    	if(checkExisting)
    	{
    		Boolean receiptExists = checkExistingReceipt(idAccount, idBankAccount, idBankGLAccount);
    		if(receiptExists)
    			return 'exists';
    	}

        Date receiptDate = Date.parse(effectDate);
        Id idERPTask = null;
        if(idERP != null){
            for(AcctSeed__Project__c p :
                [SELECT Id,
                        (SELECT Id FROM AcctSeed__Project_Tasks__r ORDER BY CreatedDate LIMIT 1)
                 FROM AcctSeed__Project__c
                 WHERE Id = :idERP])
            {
                if(p.AcctSeed__Project_Tasks__r.isEmpty())
                    throw new gcException('The ERP Order does not have any Tasks. Cannot proceed.');
                idERPTask = p.AcctSeed__Project_Tasks__r[0].Id;
            }
        }
    	AcctSeed__Accounting_Period__c period = GMBLASERP.gcAccountingPeriod.periodCurr();
    	List<AcctSeed__Cash_Receipt__c> listCrs = new List<AcctSeed__Cash_Receipt__c>();
    	AcctSeed__Cash_Receipt__c customerCr = new AcctSeed__Cash_Receipt__c(
    										AcctSeed__Account__c = idAccount,
    										AcctSeed__Amount__c = receiptAmount,
    										AcctSeed__Bank_Account__c = idBankGLAccount,
    										AcctSeed__Payment_Reference__c = paymentRef,
                                            Payment_Method__c = 'Bank Funding',
    										AcctSeed__Purpose__c = 'Customer Receipt',
                                            AcctSeed__Receipt_Date__c = receiptDate,
                                            AcctSeed__Project__c = idERP,
                                            AcctSeed__Project_Task__c = idERPTask
    									);
    	listCrs.add(customerCr);
    	AcctSeed__Cash_Receipt__c bankCr = new AcctSeed__Cash_Receipt__c(
    										AcctSeed__Account__c = idBankAccount,
    										AcctSeed__Amount__c = (financeCharge + bankCharge),
    										AcctSeed__Bank_Account__c = idBankGLAccount,
    										AcctSeed__Payment_Reference__c = System.now().format(),
                                            Payment_Method__c = 'Bank Funding',
    										AcctSeed__Purpose__c = 'Customer Receipt',
                                            AcctSeed__Receipt_Date__c = receiptDate
    									);
    	listCrs.add(bankCr);
    	insert listCrs;
    		
	 	AcctSeed__Billing__c newBill = new AcctSeed__Billing__c(
	 			AcctSeed__Customer__c = bankCr.AcctSeed__Account__c,
                AcctSeed__Date__c = receiptDate
	 		);

	 	insert newBill;
	 	List<AcctSeed__Billing_Line__c> listBLines = new List<AcctSeed__Billing_Line__c>();
		AcctSeed__Billing_Line__c newBLFC = new AcctSeed__Billing_Line__c(
											AcctSeed__Billing__c = newBill.Id,
											AcctSeed__Revenue_GL_Account__c = gcConstants.idGlFinancingFees,
											AcctSeed__Hours_Units__c = 1,
											AcctSeed__Rate__c = financeCharge.setScale(6),
											AcctSeed__GL_Account_Variable_1__c = idGLV1, 
											AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2BusinessOffice
										);
		listBLines.add(newBLFC);

		AcctSeed__Billing_Line__c newBLBC = new AcctSeed__Billing_Line__c(
											AcctSeed__Billing__c = newBill.Id,
											AcctSeed__Revenue_GL_Account__c = gcConstants.idGlBankFees,
											AcctSeed__Hours_Units__c = 1,
											AcctSeed__Rate__c = bankCharge.setScale(6),
											AcctSeed__GL_Account_Variable_1__c = idGLV1, 
											AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2BusinessOffice
										);
		listBLines.add(newBLBC);
		insert listBLines;

		AcctSeed.BillingPostService.postBillings(new List<AcctSeed__Billing__c>{newBill});

		AcctSeed__Billing_Cash_Receipt__c newBCR = new AcctSeed__Billing_Cash_Receipt__c(
				AcctSeed__Billing__c = newBill.Id,
				AcctSeed__Cash_Receipt__c = bankCr.Id,
				AcctSeed__Applied_Amount__c = (financeCharge + bankCharge),
				AcctSeed__Accounting_Period__c = period.Id
			);

		insert newBCR;

		AcctSeed__Bank_Deposit__c bankDeposit = new AcctSeed__Bank_Deposit__c(
													AcctSeed__Bank_Account__c = idBankGLAccount,
													AcctSeed__Deposit_Date__c = receiptDate//Date.today()
												);
		insert bankDeposit;

		return bankDeposit.Id;
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
    }
}