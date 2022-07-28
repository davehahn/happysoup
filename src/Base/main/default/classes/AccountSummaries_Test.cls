/* ----------------------------------------------------------------------------

	Contributors: Mario
	Last Modified By: Mario
	Created: July 30, 2018
	Last Modified: September 12, 2018

	This test covers:                            Expected Coverage:
	1) AccountSummaries_mp											 88%

---------------------------------------------------------------------------- */

@isTest
private class AccountSummaries_Test {
  static AcctSeed__Project__c erp;
  static AcctSeed__Project_Task__c task;
  static Account dealer;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static void init() {
    // Accounting Variables
    Factory_AccountingVariables acctVars = new Factory_AccountingVariables();

    // Account
    dealer = AccountFactory.buildDealerAccount('Test Dealer UnitTester');
    insert dealer;

    // Serial
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial(
      'Boat',
      'Pontoon',
      '1234567890-UNIT-TESTER'
    );

    // Ledger

    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];

    // Project
    Product2[] products = Factory_Product.createSerializedProducts('Boat', 'Pontoon', 12);
    erp = Factory_ERPOrder.createPartnerBoatSales(dealer, products, new List<String>{ 'Delivered' })[0];
    task = [SELECT Id FROM AcctSeed__Project_Task__c WHERE AcctSeed__Project__c = :erp.Id LIMIT 1];

    // Billing
    AcctSeed__Billing_Format__c format = [
      SELECT Id
      FROM AcctSeed__Billing_Format__c
      WHERE Name = 'Billing PDF Format'
      LIMIT 1
    ];
    AcctSeed__Billing__c newBill = new AcctSeed__Billing__c(
      AcctSeed__Customer__c = dealer.Id,
      AcctSeed__Billing_Format__c = format.Id,
      GMBLASERP__Project__c = erp.Id,
      AcctSeed__Ledger__c = ledger.Id
    );
    insert newBill;
    AcctSeed__Billing_Line__c newBL = new AcctSeed__Billing_Line__c(
      AcctSeed__Billing__c = newBill.Id,
      AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund,
      AcctSeed__Hours_Units__c = 1,
      AcctSeed__Rate__c = 5.0,
      AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
      AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales,
      AcctSeed__Project__c = erp.Id,
      AcctSeed__Project_Task__c = task.Id
    );
    insert newBL;
    AcctSeed__Cash_Receipt__c cr = new AcctSeed__Cash_Receipt__c(
      AcctSeed__Account__c = dealer.Id,
      AcctSeed__Amount__c = 5.0,
      AcctSeed__Receipt_Date__c = Date.today(),
      AcctSeed__Payment_Reference__c = LGND_Utilities.generateRandomString(6)+String.valueOf(System.now()),
      AcctSeed__Ledger__c = ledger.Id
    );
    insert cr;
    AcctSeed__Billing_Cash_Receipt__c bcr = new AcctSeed__Billing_Cash_Receipt__c(
      AcctSeed__Cash_Receipt__c = cr.Id,
      AcctSeed__Billing__c = newBill.Id,
      AcctSeed__Applied_Amount__c = 5.0
    );
    insert bcr;
    Test.setCreatedDate(newBill.Id, Date.today().toStartOfMonth().addDays(-15));
    Test.setCreatedDate(newBL.Id, Date.today().toStartOfMonth().addDays(-15));

    List<Id> dealerIds = new List<Id>();
    dealerIds.add(dealer.Id);
    DealerPartOrdersStatement_Controller.attachStatements(dealerIds);
  }

  @isTest
  static void getAccountSummary_Test1() {
    init();

    Datetime startDate = Datetime.now().addDays(-60);

    String summaryString = AccountSummaries_mp.getAccountSummary(dealer.Id, startDate, null, true, true, true, 'boats');
    AccountSummaries_mp.AccountSummary summary = (AccountSummaries_mp.AccountSummary) JSON.deserialize(
      summaryString,
      AccountSummaries_mp.AccountSummary.class
    );
    System.assert(summary.transactions != null);
  }

  @isTest
  static void getAccountSummary_Test_AccountNull() {
    init();

    Datetime startDate = Datetime.now().addDays(-60);

    String summaryString = AccountSummaries_mp.getAccountSummary(null, startDate, null, true, true, true, 'boats');
    AccountSummaries_mp.AccountSummary summary = (AccountSummaries_mp.AccountSummary) JSON.deserialize(
      summaryString,
      AccountSummaries_mp.AccountSummary.class
    );
    System.assert(summary.transactions != null);
  }
}
