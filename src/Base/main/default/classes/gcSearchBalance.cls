public class gcSearchBalance {
	@AuraEnabled
	public static list<AcctSeed__Accounting_Period__c> getPeriods()
	{
		return GMBLASERP.gcAccountingPeriod.periodAll();
	}
    @AuraEnabled
    public static Map<String,List<sObject>> getMatchedTxn(Decimal srcBalance, Id idPeriod) {
        Decimal balStart = srcBalance - 0.1;
        Decimal balEnd = srcBalance + 0.1;
        List<AcctSeed__Transaction__c> listTxns = new List<AcctSeed__Transaction__c>();
        for(AcctSeed__Transaction__c txn : 
        	[SELECT Id, Name, 
        		AcctSeed__Date__c, 
        		Origin_Type__c, 
        		AcctSeed__Amount__c 
        	FROM AcctSeed__Transaction__c
        	WHERE (AcctSeed__Amount__c >=:balStart
        		AND AcctSeed__Amount__c <=:balEnd)
				AND AcctSeed__Accounting_Period__c =:idPeriod
        	ORDER BY AcctSeed__Date__c DESC]){
        	listTxns.add(txn);
        }

        List<AcctSeed__Billing__c> listBills = new List<AcctSeed__Billing__c>();
        for(AcctSeed__Billing__c txn : 
        	[SELECT Id, Name, 
        		AcctSeed__Date__c, 
        		AcctSeed__Type__c, 
        		AcctSeed__Total__c 
        	FROM AcctSeed__Billing__c
        	WHERE AcctSeed__Total__c >=:balStart 
        		AND AcctSeed__Total__c <=:balEnd
				AND AcctSeed__Accounting_Period__c =:idPeriod
        	ORDER BY AcctSeed__Date__c DESC]){
        	listBills.add(txn);
        }

        List<AcctSeed__Account_Payable__c> listPayables = new List<AcctSeed__Account_Payable__c>();
        for(AcctSeed__Account_Payable__c txn : 
        	[SELECT Id, Name, 
        		AcctSeed__Date__c, 
        		AcctSeed__Type__c, 
        		AcctSeed__Total__c 
        	FROM AcctSeed__Account_Payable__c
        	WHERE AcctSeed__Total__c >=:balStart 
        		AND AcctSeed__Total__c <=:balEnd
				AND AcctSeed__Accounting_Period__c =:idPeriod
        	ORDER BY AcctSeed__Date__c DESC]){
        	listPayables.add(txn);
        }

        List<AcctSeed__Cash_Receipt__c> listReceipts = new List<AcctSeed__Cash_Receipt__c>();
        for(AcctSeed__Cash_Receipt__c txn : 
        	[SELECT Id, Name, 
        		AcctSeed__Receipt_Date__c, 
        		AcctSeed__Purpose__c, 
        		AcctSeed__Amount__c 
        	FROM AcctSeed__Cash_Receipt__c
        	WHERE AcctSeed__Amount__c >=:balStart 
        		AND AcctSeed__Amount__c <=:balEnd
				AND AcctSeed__Accounting_Period__c =:idPeriod
        	ORDER BY AcctSeed__Receipt_Date__c DESC]){
        	listReceipts.add(txn);
        }

        List<AcctSeed__Cash_Disbursement__c> listCDs = new List<AcctSeed__Cash_Disbursement__c>();
        for(AcctSeed__Cash_Disbursement__c txn : 
        	[SELECT Id, Name, 
        		AcctSeed__Disbursement_Date__c, 
        		AcctSeed__Type__c, 
        		AcctSeed__Amount__c 
        	FROM AcctSeed__Cash_Disbursement__c
        	WHERE AcctSeed__Amount__c >=:balStart 
        		AND AcctSeed__Amount__c <=:balEnd
				AND AcctSeed__Accounting_Period__c =:idPeriod
        	ORDER BY AcctSeed__Disbursement_Date__c DESC]){
        	listCDs.add(txn);
        }

        List<AcctSeed__Journal_Entry__c> listJournals = new List<AcctSeed__Journal_Entry__c>();
        for(AcctSeed__Journal_Entry__c txn : 
        	[SELECT Id, Name, 
        		AcctSeed__Journal_Date__c, 
        		AcctSeed__Total_Debits__c, 
        		AcctSeed__Total_Credits__c 
        	FROM AcctSeed__Journal_Entry__c
        	WHERE ((AcctSeed__Total_Debits__c >=:balStart
        		AND AcctSeed__Total_Debits__c <=:balEnd)
        		OR (AcctSeed__Total_Credits__c >=:balStart 
        		AND AcctSeed__Total_Credits__c <=:balEnd))
				AND AcctSeed__Accounting_Period__c =:idPeriod
        	ORDER BY AcctSeed__Journal_Date__c DESC]){
        	listJournals.add(txn);
        }

        return new Map<String,List<sObject>>{
        						'transactions'=>listTxns, 
        						'billings'=>listBills, 
        						'payables'=>listPayables, 
        						'receipts'=>listReceipts,
        						'disbursements'=>listCDs,
        						'journals'=>listJournals
        					};
    }
}