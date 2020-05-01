/* ----------------------------------------------------------------------------

	Contributors: Mario
	Last Modified By: Mario
	Created: August 7, 2018
	Last Modified: August 17, 2018

	This test covers:

	1) Flow_FinalizeSales

	Expected coverage: 90%

---------------------------------------------------------------------------- */

@isTest
public class Flow_FinalizeSales_Test {

	static AcctSeed__Project__c erp;
	static AcctSeedERP__Warehouse__c warehouse;
	static User user;
	static Id customerId;
	static Id locationId;
	static Id pbId;
	static Id oppId;
	static Id recTypeId;
	static Id sernoId;
	static Id salespersonId;
	static GMBLASERP__Serial_Number__c serialNumber;
	static Pricebook2 pricebook;
	static Product2 boat;
	static Id glv4Id;
	static Factory_TestData testData;

	@testSetup static void dataSetup() {
    testData = new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
		insert new JournalEntrySettings__c();
    //accountingSettings = new Factory_AccountingSettings();
  }

  public static void init() {
    // Get Warehouse
    AcctSeedERP__Warehouse__c warehouse = [SELECT Id, Name FROM AcctSeedERP__Warehouse__c WHERE Name = 'Whitefish'];

    // Create Customer
    Account customer = Factory_Account.insertCustomerAccounts( 1 )[0];
    customerId = customer.Id;

    // Create Product
    boat = Factory_Product.createSerializedProduct('Boat', 'Pontoon');

    // Pricebook
		//String pricebookString = [SELECT Id FROM Pricebook2 WHERE RecordType.Name = 'Dealer' ORDER BY CreatedDate DESC LIMIT 1];
		pricebook = [SELECT Id FROM Pricebook2 WHERE RecordType.Name = 'Dealer' ORDER BY CreatedDate DESC LIMIT 1];//(Pricebook2)JSON.deserialize( pricebookString, Pricebook2.class );
    Factory_PricebookEntry.createStandardEntries( new Set<Id>{boat.Id}, 0 );

    // Create Serial
    serialNumber = Factory_SerialNumber.insertFullSerialWithProduct('Boat', 'Pontoon', '0987654321', boat);

    // Journal Date
    AcctSeed__Accounting_Period__c entryDate = [SELECT Id,
    																									 AcctSeed__End_Date__c,
    																									 AcctSeed__Start_Date__c,
    																									 AcctSeed__Status__c,
    																									 Name
    																							FROM AcctSeed__Accounting_Period__c
    																						  LIMIT 1];
    System.debug(entryDate);

    // Create ERP
    erp = Factory_ERPOrder.insertRetailBoatSale(customer, warehouse, entryDate.AcctSeed__Start_Date__c.addDays(2), serialNumber);
		// Create CommissionRecords
		CommissionRecordERP.createRecords( new Set<Id>{ erp.Id } );
		CommissionLineItemERP.createRecordsFromERPs( new Set<Id>{ erp.Id } );
    // Create User
    user = Factory_User.newUser('Tom', 'Bombadil', 'System Administrator', warehouse);
    insert user;
    user = [SELECT Id, Name FROM User WHERE Id = :user.Id];

    AcctSeed__Accounting_Variable__c glv4 = new AcctSeed__Accounting_Variable__c(
    	AcctSeed__Type__c = 'GL Account Variable 4',
			Name = user.Name
    );
    insert glv4;

    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];

    AcctSeed__Cash_Receipt__c newCR = new AcctSeed__Cash_Receipt__c(
			AcctSeed__Account__c = customerId,
			AcctSeed__Amount__c = 45,
			AcctSeed__Bank_Account__c = gcConstants.idGlCashFloat,
			AcctSeed__Payment_Reference__c = customerId,
			Payment_Method__c = 'Cash',
			AcctSeed__Purpose__c = 'Customer Receipt',
			AcctSeed__Ledger__c = ledger.Id
		);
		insert newCR;
    //arAccountStatement.applyCashReceipts(customerId, newCR.Id, 'create');

		AcctSeed__Billing_Format__c myBF = new AcctSeed__Billing_Format__c(
			Name = 'Billing PDF Format',
			ACCTSEED__DEFAULT_EMAIL_TEMPLATE__C = 'Billing_Email_Template',
			ACCTSEED__VISUALFORCE_PDF_PAGE__C = 'gpBilling_PDF'
		);
		insert myBF;

		AcctSeed__Billing__c newBill = new AcctSeed__Billing__c(
			AcctSeed__Customer__c = newCR.AcctSeed__Account__c,
			AcctSeed__Billing_Format__c = myBF.Id,
			AcctSeed__Ledger__c = ledger.Id
		);

		insert newBill;

		Id idAccountingPeriod = [SELECT AcctSeed__Accounting_Period__c FROM AcctSeed__Billing__c WHERE Id =:newBill.Id][0].AcctSeed__Accounting_Period__c;

		/// Create a Billing Line for Each Cash Receipt
		AcctSeed__Billing_Line__c newBL = new AcctSeed__Billing_Line__c(
											AcctSeed__Billing__c = newBill.Id,
											AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund,
											AcctSeed__Hours_Units__c = 1,
											AcctSeed__Rate__c = 45,
											AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
											AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales
										);
		insert newBL;
		/// Post the new Bill
		AcctSeed.BillingPostService.postBillings(new List<AcctSeed__Billing__c>{newBill});
		/// Apply Cash Receipt on the new Bill
		AcctSeed__Billing_Cash_Receipt__c bcm = new AcctSeed__Billing_Cash_Receipt__c(
												AcctSeed__Accounting_Period__c = idAccountingPeriod,
												AcctSeed__Applied_Amount__c = 45,
												AcctSeed__Billing__c = newBill.Id,
												AcctSeed__Cash_Receipt__c = newCR.Id
											);
		insert bcm;

    // Location Id
    locationId = [SELECT GL_Account_Variable_1__c FROM AcctSeed__Project__c WHERE Id = :erp.Id].GL_Account_Variable_1__c;

    glv4Id = Flow_FinalizeSales.getGLV4(user.Id);
  }

	@isTest static void getERP_test() {
		init();
		String serializedERP = Flow_FinalizeSales.getERP( erp.Id );
		AcctSeed__Project__c project = (AcctSeed__Project__c)JSON.deserialize( serializedERP, AcctSeed__Project__c.Class);
		System.assert( project.Id != null );
	}

	@isTest static void getUserName_test() {
		init();
		Map<String, String> userMap = Flow_FinalizeSales.getUserName(user.Id);
		System.debug(userMap);
		System.assert( userMap.get('name') == 'Tom Bom' );
	}

	@isTest static void checkForExistingEntry_test() {
		init();
		Boolean exists = Flow_FinalizeSales.checkForExistingEntry(erp.Id);
		System.assert( exists == false );
	}

	@isTest static void getJournalEntrySettings_test() {
		init();
		String settingsJson = Flow_FinalizeSales.getJournalEntrySettings();
		JournalEntrySettings__c[] settings = (List<JournalEntrySettings__c>)JSON.deserialize( settingsJson, List<JournalEntrySettings__c>.Class );
		System.assert( settings[0].Line1125__c == 900 );
	}

	@isTest static void getSalesperson_test() {
		init();
		String salespersonString = Flow_FinalizeSales.getSalesperson(user.Id);
		User salesperson = (User)JSON.deserialize( salespersonString, User.class );
		System.assert( salesperson.Id == user.Id );
	}

	@isTest static void getCustomer_test() {
		init();
		String customerString = Flow_FinalizeSales.getCustomer(customerId);
		Account customer = (Account)JSON.deserialize( customerString, Account.class );
		System.assert( customer.ID == customerId) ;
	}

	@isTest static void getReceipts_test() {
		init();
		String receiptsString = Flow_FinalizeSales.getReceipts(customerId);
		AcctSeed__Cash_Receipt__c[] receipts = (List<AcctSeed__Cash_Receipt__c>)JSON.deserialize( receiptsString, List<AcctSeed__Cash_Receipt__c>.class) ;
		System.assert( receipts.size() > 0 );
	}

	@isTest static void getBillings_test() {
		init();
		Test.startTest();
		String billingsString = Flow_FinalizeSales.getBillings(customerId, 45.0, erp.Id);
		Test.stopTest();
		AcctSeed__Billing__c[] billings = (List<AcctSeed__Billing__c>)JSON.deserialize( billingsString, List<AcctSeed__Billing__c>.class );
		System.assert( billings.size() > 0 );
	}

	@isTest static void getLocation_test() {
		init();
		String locationString = Flow_FinalizeSales.getLocation(locationId);
		AcctSeed__Accounting_Variable__c location = (AcctSeed__Accounting_Variable__c)JSON.deserialize( locationString, AcctSeed__Accounting_Variable__c.class );
		System.debug('Location: ' + location);
		System.assert(location != null);
	}

	@isTest static void getOrderItems_test() {
		init();
		String orderItemsString = Flow_FinalizeSales.getOrderItems(erp.Id);
		AcctSeedERP__Material__c[] orderItems = (List<AcctSeedERP__Material__c>)JSON.deserialize( orderItemsString, List<AcctSeedERP__Material__c>.class );
		System.assert( orderItems.size() > 0 );
	}

	@isTest static void getTradeIns_test() {
		init();
		String tradeInsString = Flow_FinalizeSales.getTradeIns(oppId);
		AcctSeedERP__Material__c[] materials = (List<AcctSeedERP__Material__c>)JSON.deserialize( tradeInsString, List<AcctSeedERP__Material__c>.class );
		System.assert( materials.size() == 0 );
	}

	@isTest static void getTradeInRecordType_test() {
		init();
		String rtString = Flow_FinalizeSales.getTradeInRecordType();
		RecordType rt = (RecordType)JSON.deserialize( rtString, RecordType.class );
		System.assert( rt.Id != null );
	}

	@isTest static void getTradeInERP_test() {
		init();
		String tradeInErpString = Flow_FinalizeSales.getTradeInERP(oppId, recTypeId);
		AcctSeed__Project__c tradeInErp = (AcctSeed__Project__c)JSON.deserialize( tradeInErpString, AcctSeed__Project__c.class );
	}

	@isTest static void getInboundInventory_test() {
		init();
		String inboundString = Flow_FinalizeSales.getInboundInventory(erp.Id);
		List<AcctSeedERP__Inbound_Inventory_Movement__c> inboundInventory = (List<AcctSeedERP__Inbound_Inventory_Movement__c>)JSON.deserialize( inboundString, List<AcctSeedERP__Inbound_Inventory_Movement__c>.class );
		System.assert( inboundInventory.size() == 0 );
	}

	@isTest static void getInsuranceItems_test() {
		init();
		String insuranceString = Flow_FinalizeSales.getInsuranceItems(erp.Id);
		AcctSeedERP__Material__c[] insuranceItems = (List<AcctSeedERP__Material__c>)JSON.deserialize( insuranceString, List<AcctSeedERP__Material__c>.class);
		System.assert( insuranceItems.size() > 0 );
	}

	@isTest static void getCommissionRecords_test() {
		init();
		String recordString = Flow_FinalizeSales.getCommissionRecords(erp.Id);
		List<Flow_FinalizeSales.CommissionWrapper> commissions = (List<Flow_FinalizeSales.CommissionWrapper>)JSON.deserialize( recordString, List<Flow_FinalizeSales.CommissionWrapper>.class );
		System.assert( commissions.size() > 0 );
	}

	@isTest static void getPartnerPricebook_test() {
		init();
		String pricebookString = Flow_FinalizeSales.getPartnerPricebook(pricebook.Id);
		Pricebook2 pricebook = (Pricebook2)JSON.deserialize( pricebookString, Pricebook2.class );
		System.assert( pricebook.Id != null );
	}

	@isTest static void getMaximumMotor_test() {
		init();
		String maxMotorString = Flow_FinalizeSales.getMaximumMotor( erp.Id, pricebook.Id );
		Flow_FinalizeSales.MotorWrapper motor = (Flow_FinalizeSales.MotorWrapper)JSON.deserialize( maxMotorString, Flow_FinalizeSales.MotorWrapper.class );
		System.assert( motor != null );
	}

	@isTest static void getERPTasks_test() {
		init();
		String taskString = Flow_FinalizeSales.getErpTasks(erp.Id);
		AcctSeed__Project_Task__c[] tasks = (List<AcctSeed__Project_Task__c>)JSON.deserialize( taskString, List<AcctSeed__Project_Task__c>.class );
		System.assert( tasks.size() > 0 );
	}

	@isTest static void getBoat_test() {
		init();

		insert new PricebookEntry(
    	Pricebook2Id = pricebook.Id,
    	Product2Id = boat.Id,
    	UnitPrice = 500.0
    );

		String boatString = Flow_FinalizeSales.getBoat(boat.Id, pricebook.Id);
		PricebookEntry entry = (PricebookEntry)JSON.deserialize( boatString, PricebookEntry.class );
		System.assert( entry != null );
	}

	@isTest static void getNestedItems_test() {
		init();
		String nestedString = Flow_FinalizeSales.getNestedItems(sernoId, pbId);
		List<Flow_FinalizeSales.NestWrapper> nestList = (List<Flow_FinalizeSales.NestWrapper>)JSON.deserialize( nestedString, List<Flow_FinalizeSales.NestWrapper>.class );
		System.assert( nestList.size() == 0 );
	}

	@isTest static void getGLV4_test() {
		init();
		Id glv4Id = Flow_FinalizeSales.getGLV4(user.Id);
		AcctSeed__Accounting_Variable__c glv4 = [SELECT Name FROM AcctSeed__Accounting_Variable__c WHERE Id = :glv4Id];
		System.assert( glv4.Name == user.Name );
	}

	@isTest static void setTradeInToComplete_test() {
		init();
		String completeString = Flow_FinalizeSales.setTradeInToComplete(erp.Id);
		AcctSeed__Project__c tradein = (AcctSeed__Project__c)JSON.deserialize(completeString, AcctSeed__Project__c.class);
		System.assert( tradein.Stage__c == 'Delivered' );
	}


	@isTest static void createJournalEntry_test() {
		Test.startTest();

		init();
		Flow_FinalizeSales.getBillings(customerId, 45.0, erp.Id);
		Flow_FinalizeSales.JournalEntryLine[] lines = new List<Flow_FinalizeSales.JournalEntryLine>();
		for (Integer i = 0; i < 16; i++) {
			lines.add( new Flow_FinalizeSales.JournalEntryLine() );
		}

		lines[0].accountNumber  = '1120';
		lines[0].amount 			  = 5;
		lines[0].entryType 		  = 'debit';

		lines[1].accountNumber  = '1125';
		lines[1].amount 			  = 5;
		lines[1].entryType 		  = 'debit';

		lines[2].accountNumber  = '1130';
		lines[2].amount 			  = 5;
		lines[2].entryType 		  = 'debit';

		lines[3].accountNumber  = '1131';
		lines[3].amount			    = 5;
		lines[3].entryType 		  = 'debit';

		lines[4].accountNumber  = '2180';
		lines[4].amount 			  = 5;
		lines[4].entryType 		  = 'credit';

		lines[5].accountNumber  = '2190';
		lines[5].amount 			  = 5;
		lines[5].entryType 		  = 'credit';

		lines[6].accountNumber  = '2195';
		lines[6].amount 			  = 5;
		lines[6].entryType 		  = 'credit';

		lines[7].accountNumber  = '2300';
		lines[7].amount 			  = 5;
		lines[7].entryType 		  = 'credit';
		lines[7].who 					  = glv4Id;

		lines[8].accountNumber  = '4000';
		lines[8].amount 			  = 5;
		lines[8].entryType 		  = 'credit';

		lines[9].accountNumber  = '4100';
		lines[9].amount 			  = 5;
		lines[9].entryType 		  = 'credit';

		lines[10].accountNumber = '4905';
		lines[10].amount 			  = 15;
		lines[10].entryType		  = 'credit';

		lines[11].accountNumber = '5000';
		lines[11].amount 			  = 5;
		lines[11].entryType		  = 'debit';

		lines[12].accountNumber = '5200';
		lines[12].amount 			  = 5;
		lines[12].entryType		  = 'debit';
		lines[12].who 					= glv4Id;

		lines[13].accountNumber = '5210';
		lines[13].amount 			  = 5;
		lines[13].entryType		  = 'debit';

		lines[14].accountNumber = '5380';
		lines[14].amount 			  = 5;
		lines[14].entryType		  = 'debit';

		lines[15].accountNumber = '5420';
		lines[15].amount 			  = 5;
		lines[15].entryType		  = 'debit';

		String entries = JSON.serialize(lines);
		Test.stopTest();
		// Create Journal Entries
		Flow_FinalizeSales.createJournalEntry(entries, erp.Id);
	}

}