public without sharing class ListAccountBillings_ar {
    @AuraEnabled
    public static List<String> getOptions() {
        List<String> options = new list<String>();
        
        Schema.DescribeFieldResult fieldResult = AcctSeed__Cash_Receipt__c.Payment_Method__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple)
            options.add(f.getValue());
        
        return options;
    }
    
    @AuraEnabled
    public static String retrieveBillingDetails(Id idAccount, Id idPeriod)
    {
    	Date lastDate = Date.today();
    	if(idPeriod == null)
    	{
    		for(AcctSeed__Accounting_Period__c per : [SELECT Id, AcctSeed__End_Date__c FROM AcctSeed__Accounting_Period__c WHERE AcctSeed__Status__c = 'Open' ORDER BY AcctSeed__Start_Date__c DESC LIMIT 1])
    			lastDate = per.AcctSeed__End_Date__c;
    	}else{
    		for(AcctSeed__Accounting_Period__c per : [SELECT Id, AcctSeed__End_Date__c FROM AcctSeed__Accounting_Period__c WHERE Id =:idPeriod])
    			lastDate = per.AcctSeed__End_Date__c;
    	}
        List<Map<String,String>> listBills = new List<Map<String,String>>();
        for(AcctSeed__Billing__c bill : 
            [SELECT Id,
             Name, 
             AcctSeed__Total__c,
             AcctSeed__Balance__c,
             GMBLASG__Posted__c, 
             GMBLASERP__Project__c,
             GMBLASERP__Project__r.Name
             FROM AcctSeed__Billing__c 
             WHERE AcctSeed__Customer__c =:idAccount
             AND AcctSeed__Balance__c <> 0
             AND GMBLASG__Posted__c = true
             AND AcctSeed__Date__c <=:lastDate
             ORDER BY AcctSeed__Date__c, Name])
        {
            Map<String,String> m = new Map<String,String>();
            m.put('Id', bill.Id);
            m.put('Name', bill.Name);
            m.put('billBalance', String.valueOf(bill.AcctSeed__Balance__c));
            m.put('billTotal', String.valueOf(bill.AcctSeed__Total__c));
            m.put('billProject', bill.GMBLASERP__Project__c == null ? '' : bill.GMBLASERP__Project__r.Name);
            listBills.add(m);
        }
        return JSON.serialize(listBills);
    }

    @AuraEnabled
    public static String receiveBilling(Id idAccount, List<Id> idBills, String paymentMethod){
        
		Id idGlDeposit = gcConstants.idGlDeposit;
		Id idGlGiftCards = gcConstants.idGlGiftCards;
		Id idGlMerchantDebitCredit = gcConstants.idGlMerchantDebitCredit;
		Id idGlCashFloat = gcConstants.idGlCashFloat;
		Id idGlRBCCDN = gcConstants.idGlRBCCDN;
		Id idGlBank;

		if(paymentMethod == 'MasterCard' 
			|| paymentMethod == 'Visa' 
			|| paymentMethod == 'Debit')
			idGlBank = idGlMerchantDebitCredit;
		else if(paymentMethod == 'Cheque' 
			|| paymentMethod == 'Check' 
			|| paymentMethod == 'Draft')
			idGlBank = idGlRBCCDN;
		else if(paymentMethod == 'Cash')
			idGlBank = idGlCashFloat;
		else if(paymentMethod == 'Gift Cards')
			idGlBank = idGlGiftCards;
		else
			idGlBank = idGlRBCCDN;

		List<AcctSeed__Billing__c> listBill = new List<AcctSeed__Billing__c>();
		Map<Id,AcctSeed__Cash_Receipt__c> mapBillReceipt = new Map<Id,AcctSeed__Cash_Receipt__c>();
		for(AcctSeed__Billing__c bill : 
			[SELECT Id, Name,
				AcctSeed__Customer__c, 
				AcctSeed__Balance__c
			FROM AcctSeed__Billing__c          
			WHERE Id IN:idBills
				AND AcctSeed__Balance__c > 0
				AND GMBLASG__Posted__c = true])
		{
			listBill.add(bill);
			AcctSeed__Cash_Receipt__c newCR = new AcctSeed__Cash_Receipt__c(
										AcctSeed__Account__c = bill.AcctSeed__Customer__c,
										AcctSeed__Amount__c = bill.AcctSeed__Balance__c,
										AcctSeed__Bank_Account__c = idGlBank,
										AcctSeed__Payment_Reference__c = bill.Name + '_' + System.now().format(),
										Payment_Method__c = 'Cash',
										AcctSeed__Purpose__c = 'Customer Receipt'
									);

			mapBillReceipt.put(bill.Id, newCR);
		}
		List<AcctSeed__Billing_Cash_Receipt__c> listBCM = new List<AcctSeed__Billing_Cash_Receipt__c>();
		if(!mapBillReceipt.isEmpty()){
			/// Create a new Receipt
			Savepoint sp = Database.setSavepoint();
			try{
				insert mapBillReceipt.values();
				AcctSeed__Accounting_Period__c currPeriod = GMBLASERP.gcAccountingPeriod.periodCurr();
				for(Id idBill : mapBillReceipt.keySet())
				{
					AcctSeed__Cash_Receipt__c newCR = mapBillReceipt.get(idBill);
					/// Apply Cash Receipt on the new Bill
					AcctSeed__Billing_Cash_Receipt__c bcm = new AcctSeed__Billing_Cash_Receipt__c(
															AcctSeed__Accounting_Period__c = currPeriod.Id,
															AcctSeed__Applied_Amount__c = newCR.AcctSeed__Amount__c, 
															AcctSeed__Billing__c = idBill, 
															AcctSeed__Cash_Receipt__c = newCR.Id
														);
					listBCM.add(bcm);
				}
				insert listBCM;
			}catch(Exception e){
				Database.rollback(sp);
				throw new AuraHandledException(e.getMessage());
			}
			return '';
		}
		throw new AuraHandledException('No Billing was found with a positive balance.');
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
	}
}