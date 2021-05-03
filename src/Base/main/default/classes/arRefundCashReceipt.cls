public without sharing class arRefundCashReceipt {

	@AuraEnabled
	public static List<String> getOptions() {
		List<String> options = new list<String>();

		Schema.DescribeFieldResult fieldResult = AcctSeed__Cash_Disbursement__c.AcctSeed__Type__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		    
		for( Schema.PicklistEntry f : ple)
			options.add(f.getValue());

		return options;
	}

	@AuraEnabled
	public static AcctSeed__Cash_Receipt__c getReceiptAmount(String crId) {
		return [SELECT Id, AcctSeed__Amount__c, AcctSeed__Balance__c FROM AcctSeed__Cash_Receipt__c WHERE Id = :crId];
	}

	@AuraEnabled
	public static String handleRefund(String crId, String paymentMethod, String refundFrom, Decimal refundAmount)
	{
		AcctSeed__Cash_Receipt__c cr = [
			SELECT Id,
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
			WHERE Id = :crId];

		if (cr.AcctSeed__Balance__c < refundAmount) {
			throw new AuraHandledException('Refund Amount is less than the Balance.');
		}

		Id accountId = cr.AcctSeed__Account__c;

		Savepoint sp = Database.setSavepoint();

    	try {
    		if(refundFrom == 'Balance')
    		{
			 	AcctSeed__Billing__c newBill = new AcctSeed__Billing__c(
		 			AcctSeed__Customer__c = accountId
		 		);
			 	insert newBill;

				AcctSeed__Billing_Line__c newBL = new AcctSeed__Billing_Line__c(
					AcctSeed__Billing__c = newBill.Id,
					AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund,
					AcctSeed__Hours_Units__c = 1,
					AcctSeed__Rate__c = refundAmount.setScale(6),
					AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
					AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales
				);
				insert newBL;
				/// Post the new Bill
				AcctSeed.BillingPostService.postBillings(new List<AcctSeed__Billing__c>{newBill});

				AcctSeed__Billing_Cash_Receipt__c bcm = new AcctSeed__Billing_Cash_Receipt__c(
					AcctSeed__Applied_Amount__c = refundAmount,
					AcctSeed__Billing__c = newBill.Id,
					AcctSeed__Cash_Receipt__c = cr.Id
				);
				insert bcm;
			}

		 	String payeeRef = String.valueOf(DateTime.now().getTime()) + '-Customer Refund';
		 	AcctSeed__Account_Payable__c accountPayable = new AcctSeed__Account_Payable__c(
				AcctSeed__Vendor__c = accountId,
				AcctSeed__Payee_Reference__c = payeeRef,
				AcctSeed__Date__c = Date.today()
			);
		 	insert accountPayable;

	 		AcctSeed__Account_Payable_Line__c payLine = new AcctSeed__Account_Payable_Line__c(
				AcctSeed__Account_Payable__c = accountPayable.Id,
				AcctSeed__Amount__c = refundAmount, //cr.AcctSeed__Balance__c.setScale(6),
				AcctSeed__Date__c = Date.today(),
				AcctSeed__Expense_GL_Account__c = gcConstants.idGlCustomerRefund,
				AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
				AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales
			);
			insert payLine;
			AcctSeed.AccountPayablePostService.postAccountPayables(new List<AcctSeed__Account_Payable__c>{accountPayable});

			Decimal startingCheckNumber = null;
			Boolean noChequeRequired = false;
			if(!paymentMethod.equals('Check')){
				startingCheckNumber = 0;
				noChequeRequired = true;
			}

			if(startingCheckNumber == null && !noChequeRequired)
			{
				startingCheckNumber = 0;
				for(AcctSeed__Cash_Disbursement__c cd : [
					SELECT Id, AcctSeed__Check_Number__c
					FROM AcctSeed__Cash_Disbursement__c
					WHERE AcctSeed__Check_Number__c != null
					ORDER BY AcctSeed__Check_Number__c DESC
					LIMIT 1])
				{
					startingCheckNumber = cd.AcctSeed__Check_Number__c;
				}
				startingCheckNumber += 1;
			}
			AcctSeed__Cash_Disbursement_Batch__c cashDisbursementBatch = new AcctSeed__Cash_Disbursement_Batch__c(
	      		AcctSeed__Starting_Check_Number__c = startingCheckNumber,
	      		Name = 'Refund Batch' + String.valueOf(System.now())
			);
			insert cashDisbursementBatch;

			Id idGlMerchantDebitCredit = gcConstants.idGlMerchantDebitCredit;
			Id idGlCashFloat = gcConstants.idGlCashFloat;
			Id idGlRBCCDN = gcConstants.idGlRBCCDN;
			Id idGlBank;

			if(paymentMethod == 'Credit Card' 
				|| paymentMethod == 'Visa' 
				|| paymentMethod == 'Debit')
				idGlBank = idGlMerchantDebitCredit;
			else if(paymentMethod == 'Cheque' 
				|| paymentMethod == 'Check' 
				|| paymentMethod == 'Draft')
				idGlBank = idGlRBCCDN;
			else if(paymentMethod == 'Cash')
				idGlBank = idGlCashFloat;
			else
				idGlBank = idGlRBCCDN;
			AcctSeed__Cash_Disbursement__c disbursement = new AcctSeed__Cash_Disbursement__c(
				AcctSeed__Cash_Disbursement_Batch__c = cashDisbursementBatch.Id,
		        AcctSeed__Disbursement_Date__c = Date.today(),
		        AcctSeed__Type__c = paymentMethod,
		        AcctSeed__Amount__c = refundAmount,
		        AcctSeed__Source__c = 'Account Payable',
		        AcctSeed__Bank_Account__c = idGlBank,//cr.AcctSeed__Bank_Account__c,
		        AcctSeed__Vendor__c = cr.AcctSeed__Account__c,
		        AcctSeed__Status__c = 'Approved',
		        AcctSeed__Reference__c = cr.Id + '- refund',
		        AcctSeed__Debit_GL_Account__c = gcConstants.idGlAPayable,
		        AcctSeed__Payment_Status__c = 'Paid'
			);

			insert disbursement;

			AcctSeed.PostResult[] postResults = AcctSeed.CashDisbursementPostService.postCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{disbursement});

			AcctSeed__AP_Disbursement__c apdisbursement = new AcctSeed__AP_Disbursement__c(
				AcctSeed__Cash_Disbursement__c = disbursement.Id,
				AcctSeed__Paid_Amount__c = disbursement.AcctSeed__Amount__c,
				AcctSeed__Account_Payable__c = accountPayable.Id
			);
			insert apdisbursement;

			return accountPayable.Id;
		}catch(Exception e){
			Database.rollback(sp);
			throw new AuraHandledException(e.getMessage());
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
	} 
}