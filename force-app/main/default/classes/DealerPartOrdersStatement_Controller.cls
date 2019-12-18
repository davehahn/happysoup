public with sharing class DealerPartOrdersStatement_Controller {

	public Id accountId {get; set;}
	public BillingsWrapper overdueItems {get; set;}
	public BillingsWrapper currentItems {get; set;}
	public BillingsWrapper futureItems {get; set;}
	public String month {get; set;}
	public Account acct {get; set;}
	public Date firstOfMonth {get; set;}
	public Date dueDate {get; set;}

	public Class BillingWrapper {
		public AcctSeed__Billing__c billing {get; set;}
		public AcctSeed__Billing_Line__c[] lines {get; set;}
		public AcctSeed__Project__c erp {get; set;}
	}

	public Class BillingsWrapper {
		public BillingWrapper[] billings {get; set;}
		public Integer count {get; set;}
		public Decimal balance {get; set;}
		public BillingsWrapper() {
			this.count = 0;
			this.balance = 0.00;
		}
	}

	public DealerPartOrdersStatement_Controller(ApexPages.StandardController c) {
		accountId = ApexPages.currentPage().getParameters().get('Account');
		firstOfMonth = System.Date.today().toStartOfMonth();
		dueDate = firstOfMonth.addDays(14);
		getAccount(accountId);
		getMonth();
		getBillings();
	}

  public static ContentDocumentLink[] attachStatements(List<Id> accountIds){
  	System.debug('++++++++++++++++ DealerPartOrdersStatement_Controller.attachStatements ++++++++++++++++');
  	System.debug(accountIds);
    ContentDocumentLink[] statements = AddPDFtoRecord.doPost(accountIds, 'DealerPartOrdersStatement', 'Parts Order Statement');
    return statements;
  }

  public static void notifyDealers(List<ContentDocumentLink> statements) {
		System.debug('++++++++++++++++ DealerPartOrdersStatement_Controller.notifyDealers ++++++++++++++++');
  	Set<Id> accountIds = new Set<Id>();
  	Map<Id, ContentDocumentLink> linkMap = new Map<Id, ContentDocumentLink>();
  	for (ContentDocumentLink link : statements) {
  		accountIds.add(link.LinkedEntityId);
  		linkMap.put( link.LinkedEntityId, link );
  	}

  	Contact[] contacts = [SELECT Id, AccountId, Account.Language__c, Account.Preferred_Language__c, Email, Receives_Monthly_Statements__c
  													FROM Contact
  												 WHERE AccountId IN :accountIds
  												   AND Receives_Monthly_Statements__c = true];

  	/* Email */

  	List<Messaging.SingleEmailMessage> msgList= new List<Messaging.SingleEmailMessage>();
  	Id orgEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Dealer Care' LIMIT 1].Id;

  	for (Contact c : contacts) {
	    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	    mail.setOrgWideEmailAddressId( orgEmailId );
      mail.setWhatId( c.AccountId );
      mail.setSaveAsActivity(true);
	    String[] toAddresses = new List<String>();
	    Boolean french = false;

	    toAddresses.add( c.Email );

		  if (c.Account.Language__c == 'French' || c.Account.Preferred_Language__c == 'French') {
		  	french = true;
		  }

		  if (toAddresses.size() > 0) {
				toAddresses.add( 'dealercare@legendboats.com' );
		    String url = 'https://partner.legendboats.com/s/contentdocument/' + linkMap.get(c.AccountId).ContentDocumentId;
		    String msg;
		    String subject;
		    if (french) {
		    	subject = 'Votre relevé mensuel de pièces est prêt.';
		    	msg = '<p>Voici le lien menant à votre relevé mensuel: <a href="' + url + '">'+url+'</a></p>' +
						 '<p>Les paiements peuvent être faits sur votre compte de pièces en utilisant l\'une des méthodes suivantes:</p>' +
						 '<p><strong>Virement Interac</strong>: svp adresser à accounting@legendboats.com <br/>' +
						 '<strong>Dépôt Direct ou Virement Bancaire</strong>:<br/>'+
						 'Banque #003 (Banque Royale de Canada)<br/>'+
						 'Transit #04982<br/>'+
						 'Compte #103 111 1 <br/>'+
						 '<strong>Chèque</strong>: svp envoyez par courrier à 4795 Regional Road 55, Whitefish, Ontario P0M 3E0<br/>'+
						 '<strong>Carte de Crédit</strong>: veuillez communiquer avec votre équipe de Support aux Concessionnaires au 1-888-345-4756. Un frais de 2% sera appliqué sur les montant de plus de 2 000 $.</p>'+
						 '<p>Toutes les questions peuvent être adressées au Département de Support aux Concessionnaires en cliquant ici dealercare@legendboats.com. </p>'+
						 '<p>Merci et bonne journée!</p>';
		    } else {
		    	subject = 'Your monthly Parts Account statement is ready.';
		    	msg = '<p>Your monthly parts account statement is ready for download in the Partner Community. <br/>'+
						 'View it here: <a href="' + url + '">'+url+'</a></p>' +
						 '<p>Payments can be made on your Legend Boats account using the following methods:</p>' +
						 '<p><strong>Interac e-Transfers</strong>: can be directed to accounting@legendboats.com <br/>' +
						 '<strong>Electronic transfer of funds or wire transfer</strong>:<br/>'+
						 'Bank # 003 (Royal Bank of Canada)<br/>'+
						 'Transit # 04982<br/>'+
						 'Account # 103 111 1 <br/>'+
						 '<strong>By cheque</strong>: sent to 4795 Regional Road 55, Whitefish, Ontario P0M 3E0<br/>'+
						 '<strong>By credit card</strong>: call the Dealer Department at 1.888.345.4756.  Please be advised that a 2% processing fee will be applied for amounts over $2000.</p>'+
						 '<p>Any questions you may have should be directed to the Dealer Department at Legend Boats by clicking here dealercare@legendboats.com.  </p>'+
						 '<p>Please do not respond to this email.</p>'+
						 '<p>Thank you and have a great day.</p>';
		    }

		    mail.setToAddresses( toAddresses );
		    mail.setSubject( subject );
		    mail.setHtmlBody( msg );
		    msgList.add( mail );

		  }
	  }
		if( !Test.isRunningTest() )
		{
			Messaging.SendEmailResult[] results = Messaging.sendEmail(msgList, false);
			System.debug(results);
		}
  }

	private void getAccount(Id accountId) {
		acct = [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
							FROM Account
						 WHERE Id = :accountId];
	}

	private void getMonth() {
		month = Datetime.Now().format('MMMMM');
	}

	private void getBillings() {
		System.debug( 'ACCOUNT ID: ' + accountId);
		BillingWrapper[] wrappedBillings = new List<BillingWrapper>();

		AcctSeed__Billing__c[] billings = [SELECT Id,
												Name,
												AcctSeed__Balance__c,
												AcctSeed__Date__c,
												Lgnd_Due_Date__c,
												AcctSeed__Total__c,
												AcctSeed__Received_Amount__c,
												AcctSeed__Cash_Application_Adjustment_Amount__c,
												AcctSeed__Credit_Memo_Applied_Amount__c,
												AcctSeed__Type__c,
												GMBLASERP__Project__c
									 FROM AcctSeed__Billing__c
									WHERE AcctSeed__Customer__c = :accountId
										AND (CreatedDate >= LAST_MONTH OR AcctSeed__Balance__c != 0)
										AND (
											GMBLASERP__Project__r.RecordTypeId = :gcConstants.idRtPartnerPartsOrder OR
											GMBLASERP__Project__r.RecordTypeId = :gcConstants.idRtProjectWarranty OR
											GMBLASERP__Project__c = null
											)
							 ORDER BY AcctSeed__Due_Date2__c];

		Set<Id> billingIds = new Set<Id>();
		Set<Id> projectIds = new Set<Id>();
		for (AcctSeed__Billing__c billing : billings) {
			billingIds.add(billing.Id);
			projectIds.add(billing.GMBLASERP__Project__c);
		}

		AcctSeed__Billing_Line__c[] lines = [SELECT Id, AcctSeed__Billing__c
											 FROM AcctSeed__Billing_Line__c
											 WHERE AcctSeed__Billing__c IN :billingIds];

		AcctSeed__Project__c[] projects = [SELECT Id,
												 Name,
												 AcctSeedERP__Work_Order_Number__c,
												 Partner_External_PO_Number__c
									      FROM AcctSeed__Project__c
									      WHERE Id IN :projectIds];

		for (AcctSeed__Billing__c billing : billings) {
			BillingWrapper bl = new BillingWrapper();
			bl.billing = billing;

			bl.lines = new List<AcctSeed__Billing_Line__c>();
			for (AcctSeed__Billing_Line__c line : lines) {
				if (line.AcctSeed__Billing__c == billing.Id) {
					bl.lines.add(line);
				}
			}

			for (AcctSeed__Project__c project : projects) {
				if (billing.GMBLASERP__Project__c == project.Id) {
					bl.erp = project;
				}
			}
			wrappedBillings.add(bl);
		}

		overdueItems = new BillingsWrapper();
		currentItems = new BillingsWrapper();
		futureItems = new BillingsWrapper();
		overdueItems.billings = new List<BillingWrapper>();
		currentItems.billings = new List<BillingWrapper>();
		futureItems.billings = new List<BillingWrapper>();

		Date overDueDate = dueDate.addMonths( -1 );

		for (BillingWrapper bw : wrappedBillings) {
			if ( bw.billing.AcctSeed__Balance__c != 0 ) {
				if ( bw.billing.Lgnd_Due_Date__c > dueDate )
				{
					futureItems.billings.add(bw);
					futureItems.balance += bw.billing.AcctSeed__Balance__c;
				}
				else if ( bw.billing.Lgnd_Due_Date__c < overDueDate )
				{
					overdueItems.billings.add(bw);
					overdueItems.balance += bw.billing.AcctSeed__Balance__c;
				}
				else
				{
					currentItems.billings.add(bw);
					currentItems.balance += bw.billing.AcctSeed__Balance__c;
				}
			}
		}
		overdueItems.count = overdueItems.billings.size();
		currentItems.count = currentItems.billings.size();
		futureItems.count = futureItems.billings.size();
	}
}