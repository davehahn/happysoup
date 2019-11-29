/* ----------------------------------------------------------------------------

	Contributors: Mario
	Last Modified By: Mario
	Created: June ?, 2018
	Last Modified: October 12, 2018

---------------------------------------------------------------------------- */

public with sharing class Flow_FinalizeSales {
	//public Flow_FinalizeSales() {}

	public class JournalEntryLine {
		public String accountNumber {get; set;}
		public String entryType {get; set;}
		public Decimal amount {get; set;}
		public String who {get; set;}
	}

	public class CommissionWrapper {
		public CommissionRecord__c record {get; set;}
		public CommissionPayment__c[] payments {get; set;}
	}

	public class NestWrapper {
		public GMBLASERP__Serial_Number__c serialNumber {get; set;}
		public PricebookEntry entry {get; set;}
	}

	public class MotorWrapper {
		public Product_Option__c upgrade {get; set;}
		public PricebookEntry entry {get; set;}
	}

	@AuraEnabled
	public static String getERP(Id erpId) {
		AcctSeed__Project__c erp = [SELECT Id,
																			 AcctSeedERP__Work_Order_Number__c,
																			 AcctSeed__Account__c,
																			 AcctSeed__Opportunity__c,
																			 Boat_Product__c,
																			 Delivery_Date__c,
																			 GL_Account_Variable_1__c,
																			 GMBLASERP__Pricebook__c,
																			 GMBLASERP__Warehouse__c,
																			 Grand_Total__c,
																			 Order_Item_Total__c,
																			 Payment_Method__c,
																			 Pickup_Location__c,
																			 Salesperson__c,
																			 Serial_Number__c
																	FROM AcctSeed__Project__c
																 WHERE Id = :erpId];
		return JSON.serialize(erp);
	}

	@AuraEnabled
	public static Map<String, String> getUserName(Id userId) {
		String name = [SELECT Name FROM User WHERE Id = :userId].Name;
		String glv4 = getGLV4(userId);
		Map<String, String> userMap = new Map<String, String>();
		userMap.put('name', name);
		userMap.put('glv4', glv4);
		return userMap;
	}

	@AuraEnabled
	public static Boolean checkForExistingEntry(Id projectId) {
		AcctSeed__Project__c myERP = [SELECT Id,
																				 GL_Account_Variable_1__c,
																				 GL_Account_Variable_2__c,
																				 Delivery_Date__c,
																				 AcctSeed__Account__r.Name,
																				 AcctSeedERP__Work_Order_Number__c
																		FROM AcctSeed__Project__c
																	 WHERE Id = :projectId];

		String entryName = 'Sales Finalization - ' + myERP.AcctSeed__Account__r.Name + ' - ' + String.valueOf(myERP.AcctSeedERP__Work_Order_Number__c);

		System.debug(entryName);

		if (database.countQuery('SELECT Count() FROM AcctSeed__Journal_Entry__c WHERE Name = \'' + entryName + '\'') > 0) {
			return true;
		} else {
			return false;
		}
	}

	@AuraEnabled
	public static List<AcctSeed__Journal_Entry_Line__c> createJournalEntry (String entries, Id projectId) {
		String glAccount;

		AcctSeed__Project__c myERP = [SELECT Id,
																				 GL_Account_Variable_1__c,
																				 GL_Account_Variable_2__c,
																				 Delivery_Date__c,
																				 AcctSeed__Account__r.Name,
																				 AcctSeedERP__Work_Order_Number__c
																		FROM AcctSeed__Project__c
																	 WHERE Id = :projectId];

		List<JournalEntryLine> lines = (List<JournalEntryLine>)JSON.deserialize(entries, List<JournalEntryLine>.class);

		List<AcctSeed__GL_Account__c> glAccounts = getGlAccounts(lines);
		Map<String, AcctSeed__GL_Account__c> glAccountsMap = new Map<String, AcctSeed__GL_Account__c>();
		for (AcctSeed__GL_Account__c acct : glAccounts) {
			glAccountsMap.put(
				acct.Name.substring(0,4),
				acct
			);
		}

		Date journalDate;
		if (myERP.Delivery_Date__c != null) {
			journalDate = myERP.Delivery_Date__c.date();
		} else {
			journalDate = System.Today();
		}

		String entryName = 'Sales Finalization - ' + myERP.AcctSeed__Account__r.Name + ' - ' + String.valueOf(myERP.AcctSeedERP__Work_Order_Number__c);

		if ( checkForExistingEntry( projectId ) ) {
			throw new AuraHandledException('Journal Entry already exists.');
		}

		AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c WHERE Name = 'Actual'];

		AcctSeed__Journal_Entry__c je = new AcctSeed__Journal_Entry__c(
			Name = entryName,
			AcctSeed__Journal_Date__c = journalDate,
			AcctSeed__Status__c = 'Approved',
			Project__c = projectId,
			AcctSeed__Ledger__c = ledger.Id
		);

		Savepoint sp = Database.setSavepoint();
		try{
			insert je;

			List<AcctSeed__Journal_Entry_Line__c> listJEL = new List<AcctSeed__Journal_Entry_Line__c>();
			for (JournalEntryLine entry : lines) {
				glAccount = glAccountsMap.get( entry.accountNumber ).Id;

				if (entry.entryType == 'credit') {
					if (entry.who != null) {
						listJEL.add(
							new AcctSeed__Journal_Entry_Line__c(
								AcctSeed__Credit__c = entry.amount,
								AcctSeed__GL_Account__c = glAccount,
								AcctSeed__Project__c = null,
								AcctSeed__Project_Task__c = null,
								AcctSeed__Date__c = journalDate,
								AcctSeed__Units__c = -1,
								AcctSeed__Journal_Entry__c = je.Id,
								AcctSeed__GL_Account_Variable_1__c = myERP.GL_Account_Variable_1__c,
								AcctSeed__GL_Account_Variable_2__c = myERP.GL_Account_Variable_2__c,
								AcctSeed__GL_Account_Variable_4__c = entry.who
							)
						);
					} else {
						listJEL.add(
							new AcctSeed__Journal_Entry_Line__c(
								AcctSeed__Credit__c = entry.amount,
								AcctSeed__GL_Account__c = glAccount,
								AcctSeed__Project__c = null,
								AcctSeed__Project_Task__c = null,
								AcctSeed__Date__c = journalDate,
								AcctSeed__Units__c = -1,
								AcctSeed__Journal_Entry__c = je.Id,
								AcctSeed__GL_Account_Variable_1__c = myERP.GL_Account_Variable_1__c,
								AcctSeed__GL_Account_Variable_2__c = myERP.GL_Account_Variable_2__c
							)
						);
					}
				} else if (entry.entryType == 'debit') {
					if (entry.who != null) {
						listJEL.add(
							new AcctSeed__Journal_Entry_Line__c(
								AcctSeed__Debit__c = entry.amount,
								AcctSeed__GL_Account__c = glAccount,
								AcctSeed__Project__c = null,
								AcctSeed__Project_Task__c = null,
								AcctSeed__Date__c = journalDate,
								AcctSeed__Units__c = 1,
								AcctSeed__Journal_Entry__c = je.Id,
								AcctSeed__GL_Account_Variable_1__c = myERP.GL_Account_Variable_1__c,
								AcctSeed__GL_Account_Variable_2__c = myERP.GL_Account_Variable_2__c,
								AcctSeed__GL_Account_Variable_4__c = entry.who
							)
						);
					} else {
						listJEL.add(
							new AcctSeed__Journal_Entry_Line__c(
								AcctSeed__Debit__c = entry.amount,
								AcctSeed__GL_Account__c = glAccount,
								AcctSeed__Project__c = null,
								AcctSeed__Project_Task__c = null,
								AcctSeed__Date__c = journalDate,
								AcctSeed__Units__c = 1,
								AcctSeed__Journal_Entry__c = je.Id,
								AcctSeed__GL_Account_Variable_1__c = myERP.GL_Account_Variable_1__c,
								AcctSeed__GL_Account_Variable_2__c = myERP.GL_Account_Variable_2__c
							)
						);
					}
				}
			}
			insert listJEL;

			List<AcctSeed__Journal_Entry__c> listJE = new List<AcctSeed__Journal_Entry__c>();
			listJE.add(je);
			AcctSeed.PostResult[] postResults = AcctSeed.JournalEntryPostService.postJournalEntries(listJE);
			for (AcctSeed.PostResult theResult : postResults) {
		    if (!theResult.isSuccess) {
	        for (AcctSeed.PostResult.PostErrorResult errorResult: theResult.errors) {
	        	throw new gcException('Journal Entry was not posted. Please try again. REASON: ' + errorResult.message);
	        }
		    }
			}

			if ( !Test.isRunningTest() ) {
				myERP.AcctSeed__Status__c = 'Completed';
				update myERP;
			}

			return listJEL;
		} catch(Exception e) {
			Database.rollback(sp);
			System.debug(e.getCause());
			System.debug(e.getMessage());
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static string getJournalEntrySettings() {
		List<JournalEntrySettings__c> settingsList = new List<JournalEntrySettings__c>();
		JournalEntrySettings__c settings = [SELECT Id,
																							 Line1125__c,
																							 //Line1130__c,
																							 //Line1131__c,
																							 ManagerCommissionOnBO__c,
																							 ManagerCommissionOnRetail__c
																					FROM JournalEntrySettings__c
																				 LIMIT 1];
		settingsList.add(settings);
		return JSON.serialize(settingsList);
	}

	@AuraEnabled
	public static string getSalesperson(Id userId) {
		User u = [SELECT Id,
										 Name
								FROM User
							 WHERE Id = :userId];
		return JSON.serialize(u);
	}

	@AuraEnabled
	public static string getCustomer(Id accountId) {
		Account c = [SELECT Id,
												Name
									 FROM Account
									WHERE Id = :accountId];
		return JSON.serialize(c);
	}

	@AuraEnabled
	public static string getReceipts(Id accountId) {
		AcctSeed__Cash_Receipt__c[] receipts = [SELECT Id,
																									 Name,
																									 AcctSeed__Account__c,
																									 AcctSeed__Amount__c,
																									 AcctSeed__Balance__c,
																									 GMBLASG__Posted__c
																							FROM AcctSeed__Cash_Receipt__c
																						 WHERE AcctSeed__Account__c = :accountId
																						 	 AND AcctSeed__Balance__c != null
																						 	 AND GMBLASG__Posted__c = true];
		return JSON.serialize(receipts);
	}

	@AuraEnabled
	public static string getBillings(Id accountId, Decimal receiptsTotal, Id projectId) {
		AcctSeed__Billing__c[] billings = [SELECT Id,
																						  Name,
																						  AcctSeed__Total__c,
																						  AcctSeed__Balance__c
																				 FROM AcctSeed__Billing__c
																			  WHERE AcctSeed__Customer__c = :accountId
																			  	AND GMBLASERP__Project__c = :projectId
																			 	  AND GMBLASG__Posted__c = true];
		if (billings.size() < 1) {
			AcctSeed__Billing__c newBill = createBilling(accountId, projectId, receiptsTotal);
			//billings.add(newBill);
			billings = [SELECT Id,
											  Name,
											  AcctSeed__Total__c,
											  AcctSeed__Balance__c
									 FROM AcctSeed__Billing__c
								  WHERE AcctSeed__Customer__c = :accountId
										AND GMBLASERP__Project__c = :projectId
								 	  AND GMBLASG__Posted__c = true];
		}
		return JSON.serialize(billings);
	}

	@AuraEnabled
	public static string getLocation(Id locationId) {
		AcctSeed__Accounting_Variable__c location = [SELECT Id,
																											  Name
																									 FROM AcctSeed__Accounting_Variable__c
																								  WHERE Id = :locationId];
		return JSON.serialize(location);
	}

	@AuraEnabled
	public static string getOrderItems(Id erpId) {
		AcctSeed__Project__c erp = [SELECT GMBLASERP__Warehouse__c, Delivery_Date__c FROM AcctSeed__Project__c WHERE Id = :erpId];
		AcctSeedERP__Material__c[] orderItems = [SELECT Id,
																									  Name,
																									  AcctSeedERP__Product__c,
																									  AcctSeedERP__Project_Task__c,
																									  AcctSeedERP__Quantity_Per_Unit__c,
																									  AcctSeedERP__Quantity_Allocated__c,
																									  No_WIP__c,
																									  Product_Record_Type__c,
																									  GMBLASERP__Total_Price__c,
																									  AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c
																							 FROM AcctSeedERP__Material__c
																						  WHERE AcctSeedERP__Project__c = :erpId
																						    AND Inventory_Product__c = true];
		Boolean itemsLeftToWIP = false;
		for (AcctSeedERP__Material__c item : orderItems) {
			if (item.AcctSeedERP__Quantity_Allocated__c < item.AcctSeedERP__Quantity_Per_Unit__c && !item.No_WIP__c) {
				itemsLeftToWIP = true;
			}
		}
		if (itemsLeftToWIP) {
			postProject(erpId, erp.GMBLASERP__Warehouse__c, erp.Delivery_Date__c);
			orderItems = [SELECT Id,
												   Name,
												   AcctSeedERP__Product__c,
												   AcctSeedERP__Project_Task__c,
												   AcctSeedERP__Quantity_Per_Unit__c,
												   AcctSeedERP__Quantity_Allocated__c,
												   Product_Record_Type__c,
												   GMBLASERP__Total_Price__c
										  FROM AcctSeedERP__Material__c
									   WHERE AcctSeedERP__Project__c = :erpId];
		}
		return JSON.serialize(orderItems);
	}

	@AuraEnabled
	public static string getMaximumMotor(Id erpId, Id pbId) {
		System.debug(erpId + ' - ' + pbId);
		MotorWrapper wrappedMotor = new MotorWrapper();

		try {
			AcctSeed__Project__c project = [SELECT Id, Boat_Product__c FROM AcctSeed__Project__c WHERE Id = :erpId];

			Product_Option__c biggestMotor = [SELECT Id,
																							 From_Product__c,
																							 From_Product__r.Name,
																							 From_Product__r.Horse_Power__c,
																							 To_Product__c,
																							 To_Product__r.Name,
																							 To_Product__r.Horse_Power__c
																					FROM Product_Option__c
																				 WHERE To_Product__c = :project.Boat_Product__c
																				 	 AND isBiggestMotor__c = true];

			System.debug(biggestMotor);
			if (biggestMotor != null) {
				PricebookEntry pbe = [SELECT Id,
																		 Name,
																		 Product2Id,
																		 UnitPrice
															  FROM PricebookEntry
															 WHERE Product2Id = :biggestMotor.From_Product__c
																 AND Pricebook2Id = :pbId];
				wrappedMotor.upgrade = biggestMotor;
				wrappedMotor.entry = pbe;
				System.debug(wrappedMotor);
			}
		} catch (Exception e) {}

		return JSON.serialize(wrappedMotor);
	}

	@AuraEnabled
	public static string getTradeIns(Id oppId) {
		AcctSeedERP__Material__c[] materials = [SELECT Id, GMBLASERP__Total_Price__c
																							FROM AcctSeedERP__Material__c
																						 WHERE AcctSeedERP__Project__r.AcctSeed__Opportunity__c = :oppId
																						 	 AND Product_Name__c = 'Trade in'];

		return JSON.serialize(materials);
	}

	@AuraEnabled
	public static string getTradeInRecordType() {
		RecordType rt = [SELECT Id,
														Name,
														DeveloperName
											 FROM RecordType
										  WHERE Name = 'Legend Trade In' LIMIT 1];
		return JSON.serialize(rt);
	}

	@AuraEnabled
	public static string getTradeInERP(Id oppId, Id recTypeId) {
		AcctSeed__Project__c tradein;

		try {
			tradein = [SELECT Id,
											  Grand_Total__c
								   FROM AcctSeed__Project__c
							    WHERE AcctSeed__Opportunity__c = :oppId
							      AND RecordTypeId = :recTypeId
							    LIMIT 1];
		} catch(Exception e) {

		}
		return JSON.serialize(tradein);
	}

	@AuraEnabled
	public static string getInboundInventory(Id erpId) {
		List<AcctSeedERP__Inbound_Inventory_Movement__c> inboundInventory = [SELECT Id,
																																				 			  AcctSeedERP__Project__c,
																																				 			  GMBLASERP__Inventory_GL_Amount__c
																																				   FROM AcctSeedERP__Inbound_Inventory_Movement__c
																																			    WHERE AcctSeedERP__Project__c = :erpId];
		return JSON.serialize(inboundInventory);
	}

	@AuraEnabled
	public static string setTradeInToComplete(Id erpId) {

		AcctSeed__Project__c tradein;
		try {
			tradein = [SELECT Id,
												Stage__c
									 FROM AcctSeed__Project__c
								  WHERE Id = :erpId];
			tradein.Stage__c = 'Delivered';
			update tradein;
		} catch(Exception e) {}
		return JSON.serialize(tradein);
	}

	@AuraEnabled
	public static string getInsuranceItems(Id erpId) {
		AcctSeedERP__Material__c[] insuranceItems = [SELECT Id,
																								 			  GMBLASERP__Total_Price__c,
																								 			  Product_Name__c,
																								 			  Product_Record_Type__c
																								   FROM AcctSeedERP__Material__c
																							    WHERE AcctSeedERP__Project__c = :erpId];
		return JSON.serialize(insuranceItems);
	}

	@AuraEnabled
	public static string getCommissionRecords(Id erpId) {
		Map<Id, CommissionWrapper> commissions = new Map<Id, CommissionWrapper>();
		Set<Id> commissionIds = new Set<Id>();
		for (CommissionRecord__c record : [SELECT Id,
																							Name,
																							ReviewedBy__c,
																							ReviewedOn__c,
																							ApprovedOn__c,
																							ApprovedBy__c,
																							AcceptedBy__c,
																							AcceptedOn__c,
																							CommissionName__c,
																							CommissionTotal__c,
																							LineItemCount__c,
																							OpportunityId__c,
																							Stage__c,
																							Type__c,
																							Was_Previously_Completed__c
																				 FROM CommissionRecord__c
																				WHERE ERP_Order__c = :erpId]) {
			commissionIds.add(record.Id);
			CommissionWrapper cw = new CommissionWrapper();
			cw.record = record;
			cw.payments = new List<CommissionPayment__c>();
			commissions.put( record.Id, cw );
		}
		for (CommissionPayment__c payment : [SELECT Id,
																								Owner__c,
																								Owner__r.Name,
																								PaymentAmount__c,
																								PaymentPercent__c,
																								CommissionRecord__c,
																								CommissionRecordType__c
																					 FROM CommissionPayment__c
																			  	WHERE CommissionRecord__c IN :commissionIds]) {
			commissions.get( payment.CommissionRecord__c ).payments.add( payment );
		}
		return JSON.serialize(commissions.values());
	}

	@AuraEnabled
	public static string getPartnerPricebook(Id pbId) {
		Pricebook2 pb = [SELECT Id,
														Name,
														Description
											 FROM Pricebook2
											WHERE Id = :pbId ];
		return JSON.serialize(pb);
	}

	@AuraEnabled
	public static string getPricebooks() {
		Pricebook2[] pbs = [SELECT Id,
															Name,
															Description
												 FROM Pricebook2
												WHERE RecordType.Name != 'Supplier'];
		return JSON.serialize(pbs);
	}

	@AuraEnabled
	public static string getErpTasks(Id erpId) {
		AcctSeed__Project_Task__c[] tasks = [SELECT Id,
																							 	Name
																					 FROM AcctSeed__Project_Task__c
																				 	WHERE AcctSeed__Project__c = :erpId];
		return JSON.serialize(tasks);
	}

	@AuraEnabled
	public static string getNestedItems(Id sernoId, Id pbId) {
		System.debug(sernoId + ' - ' + pbId);
		Map<Id, NestWrapper> nestedItems = new Map<Id, NestWrapper>();
		List<Id> productIds = new List<Id>();
		for (GMBLASERP__Serial_Number__c item : [SELECT Id,
                                                        Name,
                                                        Description__c,
                                                        GMBLASERP__Product__c,
                                                        Model_Year__c,
                                                        Product_Name__c,
                                                        Product_Record_Type__c,
                                                        GMBLASERP__Product__r.AcctSeed__Unit_Cost__c,
                                                        Unit_Price__c
                                             FROM GMBLASERP__Serial_Number__c
                                            WHERE Nest__c = :sernoId
                                                AND Nest__c != null]) {
			if ( !nestedItems.containsKey(item.GMBLASERP__Product__c) ) {
				nestedItems.put(item.GMBLASERP__Product__c, new NestWrapper());
			}
			nestedItems.get(item.GMBLASERP__Product__c).serialNumber = item;
			productIds.add(item.GMBLASERP__Product__c);
		}
		for (PricebookEntry entry : [SELECT Id,
                                            Name,
                                            Product2Id,
                                            UnitPrice
                                 FROM PricebookEntry
                                WHERE Product2Id IN :productIds
                                    AND Pricebook2Id = :pbId]) {
			System.debug('entry');
			System.debug(entry);
			nestedItems.get(entry.Product2Id).entry = entry;
		}

		System.debug('nestedItems');
		System.debug(nestedItems);
		System.debug(pbId);

		List<NestWrapper> nestList = new List<NestWrapper>();
		for (NestWrapper nw : nestedItems.values()) {
			nestList.add(nw);
		}

		return JSON.serialize(nestList);
	}

	@AuraEnabled
	public static string getBoat(Id productId, Id pbId) {
		System.debug(productId + ' - ' + pbId);
		PricebookEntry entry;
		try {
			entry = [SELECT Id,
							 			  Name,
							 			  Product2Id,
							 			  UnitPrice
							   FROM PricebookEntry
							  WHERE Product2Id = :productId
							 	  AND Pricebook2Id = :pbId];
		} catch(Exception e) {}
		return JSON.serialize(entry);
	}

	@AuraEnabled
	public static Id getGLV4( Id whoId ) {
		Id glv4Id;

		Schema.SObjectType objType = whoId.getSobjectType();

		if (objType == User.getSobjectType()) {
			try {
				User u= [SELECT Id, Name FROM User WHERE Id = :whoId];
				AcctSeed__Accounting_Variable__c glv4 = [SELECT Id, Name
																								  FROM AcctSeed__Accounting_Variable__c
																								 WHERE Name = :u.Name];
				glv4Id = glv4.Id;
			} catch (Exception e) {}
		}
		return glv4Id;
	}

	/******************
		PRIVATE METHODS
	******************/

	@TestVisible
	private static List<AcctSeed__GL_Account__c> getGlAccounts(List<JournalEntryLine> lines) {
		List<String> glNames = new List<String>();
		for (JournalEntryLine line : lines) {
			glNames.add(line.accountNumber + '%');
		}
		List<AcctSeed__GL_Account__c> glAccounts = [SELECT Id, Name FROM AcctSeed__GL_Account__c WHERE Name LIKE :glNames];
		for (AcctSeed__GL_Account__c a : glAccounts) {
			System.debug( a );
		}
		return glAccounts;
	}

	private static AcctSeed__Billing__c createBilling (Id customerId, Id projectId, Decimal receiptsTotal) {
		AcctSeed__Billing_Format__c billingFormat = [SELECT Id FROM AcctSeed__Billing_Format__c WHERE Name = 'Billing PDF Format' LIMIT 1];
		AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c WHERE Name = 'Actual'];
		AcctSeed__Billing__c billing = new AcctSeed__Billing__c(
			AcctSeed__Date__c = date.Today(),
			GMBLASERP__Project__c = projectId,
			AcctSeed__Customer__c = customerId,
			AcctSeed__Billing_Format__c = billingFormat.Id,
			AcctSeed__Ledger__c = ledger.Id
		);
		insert billing;

		AcctSeed__Billing_Line__c newBL = new AcctSeed__Billing_Line__c(
			AcctSeed__Billing__c = billing.Id,
			AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund,
			AcctSeed__Hours_Units__c = 1,
			AcctSeed__Rate__c = receiptsTotal,
			AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
			AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales
		);
		insert newBL;

		AcctSeed.BillingPostService.postBillings(new List<AcctSeed__Billing__c>{billing});

		return billing;
	}

	private static List<string> postProject (Id erpId, Id warehouse, Datetime deliveryDate) {

		String dateString;

		if (deliveryDate == null) {
			dateString = System.today().format();
		} else {
			dateString = deliveryDate.date().format();
		}

		String[] wipResults = gcProject_AccountingActions.createWipRA( erpId, warehouse, dateString );

  	if (wipResults.size() > 0) {
  		String myString = '';
  		for (String r : wipResults) {
  			myString += r;
  			myString += '\n\n';
  		}
  	} else {
  		gcProject_AccountingActions.takeExpense(erpId, dateString);
  	}

		List<string> results = new List<string>();
		return results;
	}

}