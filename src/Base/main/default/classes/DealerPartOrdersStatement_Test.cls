/* ----------------------------------------------------------------------------

	Contributors: Mario, Dave, Rubel
	Last Modified By: Mario
	Created: July 30, 2018
	Last Modified: September 7, 2018

	This test covers:                            Expected Coverage:
	1) DealerPartOrdersStatement_Controller      90%
	2) DealerPartOrdersStatement_Batch           100%
	3) DealerPartOrdersStatement_Schedule        100%
  4) AddPDFtoRecord                            88%

---------------------------------------------------------------------------- */

@isTest
private class DealerPartOrdersStatement_Test {
  /* SETUP & PUBLIC VARIABLES */

  static AcctSeed__Project__c[] erps;
  static Map<Id, AcctSeed__Project_Task__c> erp_task_map;
  static Account dealer;
  static Contact dealerContact;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static void init() {
    //Periods
    //we have created period during Factory_TestData()
    //so we need one for previous period
    Date startDate = Date.today().toStartOfMonth().addMonths(-4);
    AcctSeed__Accounting_Period__c previousPeriod = new AcctSeed__Accounting_Period__c(
      AcctSeed__End_Date__c = Date.today().addMonths(-1).toStartOfMonth().addDays(-1),
      AcctSeed__Start_Date__c = startDate,
      AcctSeed__Status__c = 'Open',
      Name = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('YYYY-MM')
    );
    insert previousPeriod;

    // Account
    dealer = AccountFactory.buildDealerAccount('Test Dealer UnitTester');
    insert dealer;
    String email = LGND_Utilities.generateRandomString(5) + '@' + LGND_Utilities.generateRandomString(5) + '.org';
    dealerContact = Factory_Contact.buildContact(dealer.Id, 'My Amazing', 'Tester', email);
    dealerContact.Receives_Monthly_Statements__c = true;
    update dealerContact;

    // Serial
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial(
      'Boat',
      'Pontoon',
      '1234567890-UNIT-TESTER'
    );

    // Projects
    createPartnerPartSales(dealer, serial, 3);

    // Billing
    AcctSeed__Billing_Format__c format = [
      SELECT Id
      FROM AcctSeed__Billing_Format__c
      WHERE Name = 'Billing PDF Format'
      LIMIT 1
    ];
    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    List<AcctSeed__Billing__c> billings = new List<AcctSeed__Billing__c>();
    for (AcctSeed__Project__c erp : erps) {
      billings.add(
        new AcctSeed__Billing__c(
          AcctSeed__Customer__c = dealer.Id,
          AcctSeed__Billing_Format__c = format.Id,
          GMBLASERP__Project__c = erp.Id,
          AcctSeed__Ledger__c = ledger.Id
        )
      );
    }
    Date thisMonth = Date.today();
    Date lastMonth = Date.today().toStartOfMonth().addMonths(-1);
    Date nextMonth = Date.today().toStartOfMonth().addMonths(1);
    //current
    billings[0].Lgnd_Due_Date__c = Date.newInstance(thisMonth.year(), thisMonth.month(), 15);
    //overdue
    billings[1].Lgnd_Due_Date__c = Date.newInstance(lastMonth.year(), lastMonth.month(), 15);
    //future
    billings[2].Lgnd_Due_Date__c = Date.newInstance(nextMonth.year(), nextMonth.month(), 16);
    insert billings;

    List<AcctSeed__Billing_Line__c> billingLines = new List<AcctSeed__Billing_Line__c>();
    for (AcctSeed__Billing__c billing : billings) {
      billingLines.add(
        new AcctSeed__Billing_Line__c(
          AcctSeed__Billing__c = billing.Id,
          AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund,
          AcctSeed__Hours_Units__c = 1,
          AcctSeed__Rate__c = 5.0,
          AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
          AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales,
          AcctSeed__Project__c = billing.GMBLASERP__Project__c,
          AcctSeed__Project_Task__c = erp_task_map.get(billing.GMBLASERP__Project__c).Id
        )
      );
    }
    insert billingLines;
  }

  /* CONTROLLER TESTS */

  @isTest
  static void instantiateStatement() {
    init();
    Test.startTest();
    PageReference pageRef = new PageReference('/apex/DealerPartOrdersStatement');
    pageRef.getParameters().put('Account', dealer.Id);
    Test.setCurrentPage(pageRef);
    ApexPages.StandardController sc = new ApexPages.StandardController(dealer);
    DealerPartOrdersStatement_Controller statement = new DealerPartOrdersStatement_Controller(sc);
    Test.stopTest();

    System.assertEquals(1, statement.overdueItems.count, 'Should have 1 overdue item');
    System.assertEquals(1, statement.currentItems.count, 'Should have 1 current item');
    System.assertEquals(1, statement.futureItems.count, 'Should have 1 future item');
  }

  @isTest
  static void attachStatements_And_notifyDealers_Test() {
    init();
    Test.startTest();
    ContentDocumentLink[] statements = DealerPartOrdersStatement_Controller.attachStatements(new List<Id>{ dealer.Id });
    DealerPartOrdersStatement_Controller.notifyDealers(statements);
    Test.stopTest();
  }

  @isTest
  static void testSchedule() {
    init();
    Test.StartTest();
    String jobName = 'Parts Order Statememnt Schedule Test ';
    jobName += LGND_Utilities.generateRandomString(5);
    DealerPartOrdersStatement_Schedule schedule = new DealerPartOrdersStatement_Schedule();
    System.schedule(jobName, '0 0 23 * * ?', schedule);
    Test.StopTest();
  }

  private static void createPartnerPartSales(Account acct, GMBLASERP__Serial_Number__c serial, Integer count) {
    erps = new List<AcctSeed__Project__c>();
    for (Integer i = 0; i < count; i++) {
      erps.add(Factory_ERPOrder.buildERP(acct, serial.Id, gcConstants.idRtPartnerPartsOrder));
    }
    Boolean origTrig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    insert erps;
    gcProject.disableTrigger = origTrig;
    erp_task_map = new Map<Id, AcctSeed__Project_Task__c>();
    for (AcctSeed__Project__c erp : erps) {
      erp_task_map.put(erp.Id, Factory_ERPOrder.buildProjectTask(erp.Id, 'Dealer Order'));
    }
    insert erp_task_map.values();
    Product2[] parts = Factory_Product.buildNonSerializedProducts('Part', 'Hardware', 5);
    insert parts;
    List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();
    for (AcctSeed__Project_Task__c task : erp_task_map.values()) {
      for (Product2 part : parts) {
        mats.add(Factory_ERPOrder.buildMaterial(task.AcctSeed__Project__c, task.Id, part.Id));
      }
    }
    insert mats;
  }
}
