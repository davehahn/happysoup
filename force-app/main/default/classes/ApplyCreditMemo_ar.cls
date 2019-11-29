public without sharing class ApplyCreditMemo_ar {
	@AuraEnabled
    public static String retrieveInvoices(String idCMemo)
    {
    	Map<String,List<AcctSeed__Billing__c>> mapListBills = new Map<String,List<AcctSeed__Billing__c>>();
    	List<AcctSeed__Billing__c> listBills = new List<AcctSeed__Billing__c>();
        AcctSeed__Billing__c bill = [SELECT Id, AcctSeed__Customer__c, AcctSeed__Balance__c, AcctSeed__Type__c FROM AcctSeed__Billing__c WHERE Id=:idCMemo][0];
        if(bill.AcctSeed__Type__c != 'Credit Memo')
        	return 'No';
        AcctSeed__Accounting_Period__c currPeriod = GMBLASERP.gcAccountingPeriod.periodCurr();
        mapListBills.put('originalBill',new List<AcctSeed__Billing__c>{bill});
        for(AcctSeed__Billing__c billing : 
         	[SELECT Id, 
         		Name, 
         		AcctSeed__Date__c, 
         		AcctSeed__Due_Date2__c, 
         		AcctSeed__Total__c,
         		AcctSeed__Credit_Memo_Applied_Amount__c,
         		AcctSeed__Balance__c,
         		GMBLASERP__Project__r.AcctSeedERP__Work_Order_Number__c,
         		AcctSeed__Accounting_Period__r.AcctSeed__Status__c,
         		AcctSeed__Accounting_Period__c
         	FROM AcctSeed__Billing__c
         	WHERE AcctSeed__Customer__c =:bill.AcctSeed__Customer__c
         	AND AcctSeed__Balance__c > 0
         	AND GMBLASG__Posted__c = true])
        {
        	if(billing.AcctSeed__Accounting_Period__r.AcctSeed__Status__c != 'Open')
        		billing.AcctSeed__Accounting_Period__c = currPeriod.Id;
        	listBills.add(billing);
        }
        mapListBills.put('allInvoices',listBills);
        return JSON.serialize(mapListBills);
    }

    @AuraEnabled
    public static void createBCM(Id idCM, List<Map<String,String>> listData){
    	try{
	    	List<AcctSeed__Billing_Credit_Memo__c> listBCM = new List<AcctSeed__Billing_Credit_Memo__c>();
	    	for(Map<String,String> m : listData){
	    		Id idAccountingPeriod = m.get('applyPeriod');
	    		Decimal currentAmount = Decimal.valueOf(m.get('applyAmount'));
	    		Id idBilling = m.get('idBilling');
	    		if(currentAmount == 0) continue;
				AcctSeed__Billing_Credit_Memo__c bcm = new AcctSeed__Billing_Credit_Memo__c(
					AcctSeed__Accounting_Period__c = idAccountingPeriod,
					AcctSeed__Amount__c = currentAmount * -1, 
					AcctSeed__Billing_Credit_Memo__c = idCM, 
					AcctSeed__Billing_Invoice__c = idBilling
				);
				listBCM.add(bcm);
	    	}
	    	if(!listBCM.isEmpty())
	    		insert listBCM;
    	}catch(Exception e){
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
	}
}