/* ----------------------------------------------------------------------------

	Contributors: Mario
	Last Modified By: Mario
	Created: July 26, 2018
	Last Modified: October 4, 2018

---------------------------------------------------------------------------- */

public without sharing class AccountSummaries_mp {

	public class TransactionRecord implements Comparable {
		public String Name 					{ get; set; }
		public String Type 					{ get; set; }
		public String Reference			{ get; set; }
		public Decimal Credit 			{ get; set; }
		public Decimal Debit 				{ get; set; }
		public Date SortDate				{ get; set; }

		public Integer compareTo(Object compareTo) {
			TransactionRecord compareToTrx = (TransactionRecord)compareTo;
			if (SortDate == compareToTrx.SortDate) return 0;
			if (SortDate > compareToTrx.SortDate) return 1;
			return -1;
		}
	}

	public class AccountSummary {
		public Id dealerId											{ get; set; }
		public Datetime lastPaymentDate					{ get; set; }
		public Datetime paymentDueDate					{ get; set; }
		public Decimal availableCredit 					{ get; set; }
		public Decimal currentBalance 					{ get; set; }
		public Decimal creditTotal 							{ get; set; }
		public Decimal debitTotal 							{ get; set; }
		public Decimal creditLimit 							{ get; set; }
		public Decimal lastPayment 							{ get; set; }
		public TransactionRecord[] transactions	{ get; set; }
		public DocumentWrapper[] statements { get; set; }

		public AccountSummary(Id accountId) {

			if (accountId != null) {
				this.dealerId = accountId;
			} else if ( UserInfo.getUserType() == 'Standard' ) {
			  User currentUser = [SELECT Id, Warehouse__c FROM User WHERE Id = :Userinfo.getUserId() ];
			  Legend_Settings__c orgDefaults = Legend_Settings__c.getOrgDefaults();
			  Map<String, Id> wareHouseMap = new Map<String, Id>{
					'Whitefish' => orgDefaults.LegendWhitefishAccountId__c,
					'Barrie' => orgDefaults.LegendBarrieAccountId__c,
					'Montreal' => orgDefaults.LegendMontrealAccountId__c,
					'Wholesale' => orgDefaults.LegendWholesaleAccountId__c
			  };
			  if ( wareHouseMap.containsKey( currentUser.wareHouse__c ) ) {
					this.dealerId = wareHouseMap.get( currentUser.Warehouse__c );
			  }
			} else {
			  Id contactId = [SELECT ContactId FROM User WHERE Id = :Userinfo.getUserId()].ContactId;
			  Contact ct = [SELECT AccountId, Account.BillingState FROM Contact WHERE Id = :contactId];
			  this.dealerId = ct.AccountId;
			}

			this.transactions = new List<TransactionRecord>();

			this.availableCredit = 0.00;
			this.creditTotal 		 = 0.00;
			this.debitTotal  		 = 0.00;
			this.creditLimit 		 = 0.00;
			this.lastPayment 		 = 0.00;
			this.currentBalance  = 0.00;

			Integer numberOfDays = Date.daysInMonth(System.Today().year(), System.Today().month());
			this.paymentDueDate = Date.newInstance(System.Today().year(), System.Today().month(), numberOfDays).addDays(15);
		}
	}

	public class DocumentWrapper {
		public ContentDocument doc 			{ get; set; }
		public ContentVersion version		{ get; set; }
	}

	@AuraEnabled
	public static String getAccountSummary(Id accountId,
																				 Datetime startDate,
																				 Datetime endDate,
																				 Boolean includeInvoices,
																				 Boolean includeCreditMemos,
																				 Boolean includeReceipts,
																				 String recType) {

		Id projectRtId;

		if (recType == 'parts')
			projectRtId = gcConstants.idRtPartnerPartsOrder;
		else if (recType == 'boats')
			projectRtId = gcConstants.idRtProjectPartnerBoatSale;

		/* TRANSACTIONS */

		if (startDate == null)
			startDate = Datetime.now().addDays(-30);

		if (endDate == null)
			endDate = Datetime.now();

		AccountSummary summary  = new AccountSummary(accountId);

		if (includeReceipts) {
			List<AcctSeed__Billing_Cash_Receipt__c> receipts;

			if (recType == 'parts') {
				receipts = [SELECT Id,
													Name,
													AcctSeed__Applied_Amount__c,
													AcctSeed__Cash_Receipt__r.AcctSeed__Account__c,
													AcctSeed__Cash_Receipt__r.AcctSeed__Amount__c,
													AcctSeed__Cash_Receipt__r.AcctSeed__Receipt_Date__c,
													AcctSeed__Cash_Receipt__r.Name,
													AcctSeed__Billing__r.GMBLASERP__Project__c,
													AcctSeed__Billing__r.GMBLASERP__Project__r.RecordTypeId,
													AcctSeed__Billing__r.GMBLASERP__Project__r.Partner_External_PO_Number__c
										 FROM AcctSeed__Billing_Cash_Receipt__c
										WHERE AcctSeed__Cash_Receipt__r.AcctSeed__Account__c = :summary.dealerId
											AND (CreatedDate >= :startDate AND CreatedDate <= :endDate)
											AND (AcctSeed__Billing__r.GMBLASERP__Project__r.RecordTypeId = :projectRtId OR AcctSeed__Billing__r.GMBLASERP__Project__c = null)
								 ORDER BY CreatedDate];
			} else {
				receipts = [SELECT Id,
													Name,
													AcctSeed__Applied_Amount__c,
													AcctSeed__Cash_Receipt__r.AcctSeed__Account__c,
													AcctSeed__Cash_Receipt__r.AcctSeed__Amount__c,
													AcctSeed__Cash_Receipt__r.AcctSeed__Receipt_Date__c,
													AcctSeed__Cash_Receipt__r.Name,
													AcctSeed__Billing__r.GMBLASERP__Project__r.RecordTypeId,
													AcctSeed__Billing__r.GMBLASERP__Project__r.Partner_External_PO_Number__c
										 FROM AcctSeed__Billing_Cash_Receipt__c
										WHERE AcctSeed__Cash_Receipt__r.AcctSeed__Account__c = :summary.dealerId
											AND (CreatedDate >= :startDate AND CreatedDate <= :endDate)
											AND AcctSeed__Billing__r.GMBLASERP__Project__r.RecordTypeId = :projectRtId
								 ORDER BY CreatedDate];
			}

			for (AcctSeed__Billing_Cash_Receipt__c receipt : receipts) {
				TransactionRecord tr = new TransactionRecord();
				tr.Name = receipt.Name;
				tr.Type = 'Receipt # ' + receipt.AcctSeed__Cash_Receipt__r.Name;
				tr.Reference = receipt.AcctSeed__Billing__r.GMBLASERP__Project__r.Partner_External_PO_Number__c;
				tr.Credit = receipt.AcctSeed__Applied_Amount__c;
				tr.SortDate = receipt.AcctSeed__Cash_Receipt__r.AcctSeed__Receipt_Date__c;
				summary.creditTotal += tr.Credit;
				summary.transactions.add( tr );
			}
		}

		List<AcctSeed__Billing__c> billings;

		if (recType == 'parts') {
			billings = [SELECT Id,
												Name,
												AcctSeed__Balance__c,
												AcctSeed__Date__c,
												AcctSeed__Due_Date2__c,
												AcctSeed__Total__c,
												AcctSeed__Received_Amount__c,
												AcctSeed__Cash_Application_Adjustment_Amount__c,
												AcctSeed__Credit_Memo_Applied_Amount__c,
												AcctSeed__Type__c,
												GMBLASERP__Project__c,
												GMBLASERP__Project__r.Name,
												GMBLASERP__Project__r.Partner_External_PO_Number__c
									 FROM AcctSeed__Billing__c
									WHERE AcctSeed__Customer__c = :summary.dealerId
										AND (CreatedDate >= :startDate AND CreatedDate <= :endDate)
										AND GMBLASERP__Project__r.RecordTypeId = :projectRtId
							 ORDER BY CreatedDate];
		} else {
			billings = [SELECT Id,
												Name,
												AcctSeed__Balance__c,
												AcctSeed__Date__c,
												AcctSeed__Due_Date2__c,
												AcctSeed__Total__c,
												AcctSeed__Received_Amount__c,
												AcctSeed__Cash_Application_Adjustment_Amount__c,
												AcctSeed__Credit_Memo_Applied_Amount__c,
												AcctSeed__Type__c,
												GMBLASERP__Project__c,
												GMBLASERP__Project__r.Name,
												GMBLASERP__Project__r.Partner_External_PO_Number__c
									 FROM AcctSeed__Billing__c
									WHERE AcctSeed__Customer__c = :summary.dealerId
										AND (CreatedDate >= :startDate AND CreatedDate <= :endDate)
										AND (GMBLASERP__Project__r.RecordTypeId = :projectRtId OR GMBLASERP__Project__c = null)
							 ORDER BY CreatedDate];

		}

		for (AcctSeed__Billing__c billing : billings) {
			if ( (includeCreditMemos && billing.AcctSeed__Type__c == 'Credit Memo') || (includeInvoices && billing.AcctSeed__Type__c == 'Invoice') ) {
				TransactionRecord tr = new TransactionRecord();
				tr.Name = billing.Name;
				tr.Type = billing.AcctSeed__Type__c + ' # ' + billing.GMBLASERP__Project__r.Name;
				tr.Reference = billing.GMBLASERP__Project__r.Partner_External_PO_Number__c;
				if (billing.AcctSeed__Type__c == 'Credit Memo') {
					tr.Credit = billing.AcctSeed__Total__c;
					summary.creditTotal += tr.Credit;
				} else {
					tr.Debit = billing.AcctSeed__Total__c;
					summary.debitTotal += tr.Debit;
				}
				tr.SortDate = billing.AcctSeed__Date__c;
				summary.transactions.add( tr );
			}
		}

		summary.transactions.sort();

		/* DETAILS */

		try {
			Account_Number_Detail__c accountDetails = [SELECT Id, Credit_Limit__c, Type__c FROM Account_Number_Detail__c WHERE Dealer__c = :summary.dealerId AND Type__c = 'Parts' LIMIT 1];
			summary.creditLimit = accountDetails.Credit_Limit__c;
		} catch(Exception e) {}

		try {
			AcctSeed__Cash_Receipt__c lastReceipt = [SELECT Id, AcctSeed__Amount__c, AcctSeed__Balance__c, CreatedDate FROM AcctSeed__Cash_Receipt__c WHERE AcctSeed__Account__c = :summary.dealerId ORDER BY CreatedDate DESC LIMIT 1];
			summary.lastPayment = lastReceipt.AcctSeed__Amount__c;
			summary.lastPaymentDate = lastReceipt.CreatedDate;
			summary.currentBalance = lastReceipt.AcctSeed__Balance__c;
			summary.availableCredit = summary.creditLimit - summary.currentBalance;
		} catch(Exception e) {}

		try {
			summary.statements = getStatements('Parts Order Statement', summary.dealerId);
			System.debug(summary.statements);
		} catch(Exception e) {
			System.debug( e );
		}

		/* DONE */

		System.debug(summary);
		return JSON.serialize(summary);
	}

	public static DocumentWrapper[] getStatements(String recType, Id AccountId) {
		System.debug('getStatements: begin for ' + AccountId + ' and ' + recType);
    Id rtId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get(recType).getRecordTypeId();
    System.debug('rtId: ' + rtId);
    Map<String, DocumentWrapper> docMap = new Map<String, DocumentWrapper>();
    Set<Id> docIds = new Set<Id>();
		for (ContentDocumentLink link : [SELECT Id, ContentDocumentId
																			 FROM ContentDocumentLink
																			WHERE LinkedEntityId = :AccountId]) { // and RecordTypeId = :rtId];
			docIds.add( link.ContentDocumentId );
		}
		for (ContentVersion version : [SELECT Id, ContentDocumentId, ContentDocument.CreatedDate
																		 FROM ContentVersion
																		WHERE ContentDocumentId IN :docIds
																			AND RecordTypeId = :rtId
																		ORDER BY CreatedDate DESC]) {
			if ( !docMap.containsKey( version.ContentDocumentId ) ) {
				docMap.put( version.ContentDocumentId, new DocumentWrapper() );
			}
			docMap.get( version.ContentDocumentId ).version = version;
		}
		for (ContentDocument doc : [SELECT Id, Title FROM ContentDocument WHERE Id IN :docMap.keySet()] ) {
			docMap.get( doc.Id ).doc = doc;
		}

		System.debug( docMap.values() );

		System.debug('getStatements: end');

		return docMap.values();
	}
}