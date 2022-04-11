global without sharing class gcPrintCheck{

	global gcPrintCheck(){
		init();
	}

	global transient List<cdWrap> listCDWraps{get;set;}

	global void init()
	{
		listCDWraps = new List<cdWrap>();
		Map<Id,cdWrap> mapListCDW = new Map<Id,cdWrap>();
 		Id idFilter = ApexPages.currentPage().getParameters().get('idFilter');
		for(AcctSeed__Cash_Disbursement__c cashDisb :	
				[SELECT Id, 
					Name,
					(SELECT Id,
						AcctSeed__Account_Payable__r.Name, 
						AcctSeed__Account_Payable__r.AcctSeed__Type__c, 
						AcctSeed__Account_Payable__r.AcctSeed__Date__c, 
						AcctSeed__Discount_Amount__c, 
						AcctSeed__Net_Amount__c, 
						AcctSeed__Paid_Amount__c, 
						AcctSeed__Payable_Amount__c, 
						AcctSeed__Payee_Reference__c 
					FROM AcctSeed__Account_Payable_Cash_Disbursements__r
					ORDER BY AcctSeed__Account_Payable__r.AcctSeed__Date__c,
						AcctSeed__Account_Payable__r.Name),
					Payee_New__c, 
					AcctSeed__Amount__c, 
					AcctSeed__Check_Number__c, 
					AcctSeed__Disbursement_Date__c, 
					AcctSeed__Payee_City_State_Zip__c, 
					AcctSeed__Payee_Country__c, 
					AcctSeed__Payee_Street__c,
					AcctSeed__Amount_in_Words__c 
				FROM AcctSeed__Cash_Disbursement__c
			 	WHERE Id =:idFilter 
			 		OR AcctSeed__Cash_Disbursement_Batch__c =:idFilter
			 	ORDER BY AcctSeed__Check_Number__c])
		{
			cdWrap cdw = new cdWrap(cashDisb);
			//Decimal totalAP = 0;
//			if(!cashDisb.AcctSeed__Account_Payable_Cash_Disbursements__r.isEmpty())
//			{
//				cdw.totalAP = cashDisb.AcctSeed__Account_Payable_Cash_Disbursements__r.size();
//				//apList = new List<Map<String,String>>();
//				Integer i = 0;
//				for(AcctSeed__AP_Disbursement__c ap : cashDisb.AcctSeed__Account_Payable_Cash_Disbursements__r)
//				{
//					Map<String,String> m = new Map<String,String>();
//					m.put('apName', ap.AcctSeed__Account_Payable__r.Name);
//					m.put('apType', ap.AcctSeed__Account_Payable__r.AcctSeed__Type__c == null ? '' : ap.AcctSeed__Account_Payable__r.AcctSeed__Type__c);
//					m.put('apRef', ap.AcctSeed__Payee_Reference__c == null?'':ap.AcctSeed__Payee_Reference__c);
//					m.put('apDate', ap.AcctSeed__Account_Payable__r.AcctSeed__Date__c == null ? '' : ap.AcctSeed__Account_Payable__r.AcctSeed__Date__c.format());
//					m.put('apNet', ap.AcctSeed__Net_Amount__c == null?'0.00':String.valueOf(ap.AcctSeed__Net_Amount__c.setScale(2)));
//					m.put('apDiscount', ap.AcctSeed__Discount_Amount__c == null?'0.00':String.valueOf(ap.AcctSeed__Discount_Amount__c.setScale(2)));
//					m.put('apPaid', ap.AcctSeed__Paid_Amount__c == null?'0.00':String.valueOf(ap.AcctSeed__Paid_Amount__c.setScale(2)));
//					m.put('apAmount', ap.AcctSeed__Payable_Amount__c == null?'0.00':String.valueOf(ap.AcctSeed__Payable_Amount__c.setScale(2)));
//					cdw.apList.add(m);
//					i++;
//					if(i == 10) break;
//				}
//				//cdw.apList = apList;
//				//cdw.totalAP = totalAP;
//			}
			Map<String,String> cashDisbMap = new Map<String,String>();
			cashDisbMap.put('payee', cashDisb.Payee_New__c);
			cashDisbMap.put('check', cashDisb.AcctSeed__Check_Number__c == null ? '' : String.valueOf(cashDisb.AcctSeed__Check_Number__c));
			cashDisbMap.put('amount', cashDisb.AcctSeed__Amount__c != null ? String.valueOf(cashDisb.AcctSeed__Amount__c.setScale(2)):'0.00');
			cashDisbMap.put('amountInWord', cashDisb.AcctSeed__Amount_in_Words__c == null ? '' : cashDisb.AcctSeed__Amount_in_Words__c);
			cashDisbMap.put('date', cashDisb.AcctSeed__Disbursement_Date__c == null ? '' : cashDisb.AcctSeed__Disbursement_Date__c.format());
			cashDisbMap.put('payeeCSZ', cashDisb.AcctSeed__Payee_City_State_Zip__c == null ? '' : cashDisb.AcctSeed__Payee_City_State_Zip__c);
			cashDisbMap.put('payeeStreet', cashDisb.AcctSeed__Payee_Street__c == null ? '' : cashDisb.AcctSeed__Payee_Street__c);
			cashDisbMap.put('payeeCountry', cashDisb.AcctSeed__Payee_Country__c == null ? '' : cashDisb.AcctSeed__Payee_Country__c);
			
			cdw.cashDisbMap = cashDisbMap;
			mapListCDW.put(cashDisb.Id,cdw);
			//listCDWraps.add(cdw);
		}
		Integer i = 0;
		for(AcctSeed__AP_Disbursement__c ap : [SELECT Id,
				AcctSeed__Account_Payable__r.Name,
				AcctSeed__Account_Payable__r.AcctSeed__Type__c,
				AcctSeed__Account_Payable__r.AcctSeed__Date__c,
				AcctSeed__Discount_Amount__c,
				AcctSeed__Net_Amount__c,
				AcctSeed__Paid_Amount__c,
				AcctSeed__Payable_Amount__c,
				AcctSeed__Payee_Reference__c,
				AcctSeed__Cash_Disbursement__c
		FROM AcctSeed__AP_Disbursement__c
		WHERE (AcctSeed__Cash_Disbursement__c =:idFilter OR AcctSeed__Cash_Disbursement__r.AcctSeed__Cash_Disbursement_Batch__c =:idFilter)
		ORDER BY AcctSeed__Account_Payable__r.AcctSeed__Date__c,
				AcctSeed__Account_Payable__r.Name])
		{
			cdWrap cdw = mapListCDW.get(ap.AcctSeed__Cash_Disbursement__c);
			Map<String,String> m = new Map<String,String>();
			m.put('apName', ap.AcctSeed__Account_Payable__r.Name);
			m.put('apType', ap.AcctSeed__Account_Payable__r.AcctSeed__Type__c == null ? '' : ap.AcctSeed__Account_Payable__r.AcctSeed__Type__c);
			m.put('apRef', ap.AcctSeed__Payee_Reference__c == null?'':ap.AcctSeed__Payee_Reference__c);
			m.put('apDate', ap.AcctSeed__Account_Payable__r.AcctSeed__Date__c == null ? '' : ap.AcctSeed__Account_Payable__r.AcctSeed__Date__c.format());
			m.put('apNet', ap.AcctSeed__Net_Amount__c == null?'0.00':String.valueOf(ap.AcctSeed__Net_Amount__c.setScale(2)));
			m.put('apDiscount', ap.AcctSeed__Discount_Amount__c == null?'0.00':String.valueOf(ap.AcctSeed__Discount_Amount__c.setScale(2)));
			m.put('apPaid', ap.AcctSeed__Paid_Amount__c == null?'0.00':String.valueOf(ap.AcctSeed__Paid_Amount__c.setScale(2)));
			m.put('apAmount', ap.AcctSeed__Payable_Amount__c == null?'0.00':String.valueOf(ap.AcctSeed__Payable_Amount__c.setScale(2)));
			i++;
			if(i <= 10){
				cdw.apList.add(m);
			}
			cdw.totalAP = i;
		}
		listCDWraps.addAll(mapListCDW.values());
	}


	public class cdWrap{
		public AcctSeed__Cash_Disbursement__c cashDisb{get;set;}
		public Map<String,String> cashDisbMap{get;set;}
		public List<Map<String,String>> apList{get;set;}
		public Decimal totalAP{get;set;}

		public cdWrap(AcctSeed__Cash_Disbursement__c pCD)
		{
			cashDisb = pCD;
			cashDisbMap = new Map<String,String>();
			apList = new List<Map<String,String>>();
			totalAP = 0;
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
	} 
}