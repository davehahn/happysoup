@isTest(SeeAllData=false)
public class gcBilling_T {
  final static String RECORDTYPE = 'Motor';
  final static String FAMILY = 'Remote';
  final static String SERIALNUMBER = '123450';
  final static String FNAME = 'TestFirstName';
  final static String LNAME = 'TestLastName';
  final static String TASKNAME = 'Test ERP Task';
  @TestSetup
  static void testData() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    List<AcctSeed__Project__c> erps;
    Map<Id, AcctSeed__Project_Task__c> erp_task_map;
    Contact dealerContact;

    Date startDate = Date.today().toStartOfMonth().addMonths(-4);
    AcctSeed__Accounting_Period__c previousPeriod = new AcctSeed__Accounting_Period__c(
      AcctSeed__End_Date__c = Date.today().addMonths(-1).toStartOfMonth().addDays(-1),
      AcctSeed__Start_Date__c = startDate,
      AcctSeed__Status__c = 'Open',
      Name = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('YYYY-MM')
    );
    insert previousPeriod;
    // Account
    Account dealer = AccountFactory.buildDealerAccount('Test Dealer UnitTester');
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
    //createPartnerPartSales( dealer, serial, 3 );
    integer count = 3;

    erps = new List<AcctSeed__Project__c>();
    for (Integer i = 0; i < count; i++) {
      erps.add(Factory_ERPOrder.buildERP(dealer, serial.Id, gcConstants.idRtPartnerPartsOrder));
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

    List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 10);

    // Billing
    AcctSeed__Billing_Format__c format = [
      SELECT Id
      FROM AcctSeed__Billing_Format__c
      WHERE Name = 'Billing PDF Format'
      LIMIT 1
    ];
    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    List<AcctSeed__Billing__c> billings = new List<AcctSeed__Billing__c>();
    List<AcctSeed__Cash_Receipt__c> lstCashReceipt = new List<AcctSeed__Cash_Receipt__c>();
    for (AcctSeed__Project__c erp : erps) {
      billings.add(
        new AcctSeed__Billing__c(
          AcctSeed__Customer__c = dealer.Id,
          AcctSeed__Billing_Format__c = format.Id,
          GMBLASERP__Project__c = erp.Id,
          AcctSeed__Ledger__c = ledger.Id
        )
      );

      lstCashReceipt.add(
        new AcctSeed__Cash_Receipt__c(
          AcctSeed__Account__c = dealer.Id,
          AcctSeed__Amount__c = 5.0,
          AcctSeed__Receipt_Date__c = Date.today(),
          AcctSeed__Payment_Reference__c = 'Cash',
          AcctSeed__Ledger__c = ledger.Id,
          AcctSeed__Project__c = erp.Id,
          AcctSeed__Project_Task__c = erp_task_map.get(erp.Id).Id,
          AcctSeed__Product__c = serializedProducts[0].Id
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
    insert lstCashReceipt;
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
          AcctSeed__Project_Task__c = erp_task_map.get(billing.GMBLASERP__Project__c).Id,
          AcctSeed__List_Price__c = 50,
          AcctSeed__Product_Unit_Cost__c = 50,
          AcctSeed__Tax_Amount2__c = 1.2
        )
      );
    }
    insert billingLines;

    List<ERP_document__c> erpDocuments = new List<ERP_document__c>();
    integer i = 0;
    for (AcctSeed__Project__c erp : erps) {
      ERP_document__c doc = new ERP_document__c();
      doc.Project__c = erp.Id;
      doc.Billing__c = billings[i].Id;
      doc.Certificate_Number__c = (i + 1) * 100;
      if (i == 0) {
        doc.Document_Type__c = 'Retail';
      } else {
        doc.Document_Type__c = 'Partner';
      }
      doc.Name = 'test - ' + (i + 1);
      doc.DocumentID__c = erp.Id;
      erpDocuments.add(doc);
      i++;
    }
    insert erpDocuments;
  }

  @isTest
  static void verifyProperties() {
    gcBilling.disableTrigger = null;
    system.assertEquals(false, gcBilling.disableTrigger);
    gcBilling.disableTrigger = true;
    system.assertEquals(true, gcBilling.disableTrigger);

    gcBilling.allowBillingProjectForInternal = null;
    system.assertEquals(false, gcBilling.allowBillingProjectForInternal);
    gcBilling.allowBillingProjectForInternal = true;
    system.assertEquals(true, gcBilling.allowBillingProjectForInternal);
  }

  @isTest
  static void testPostAndUnpostBillingData() {
    List<AcctSeed__Billing__c> lstBilling = new List<AcctSeed__Billing__c>();
    lstBilling = [SELECT Id, Tax_Rate_Retail__c, Tax_Override__c FROM AcctSeed__Billing__c];

    lstBilling[0].Tax_Rate_Retail__c = 9.2;
    update lstBilling[0];
    Test.StartTest();
    AcctSeed.BillingPostService.postBillings(lstBilling);

    AcctSeed.BillingPostService.unpostBillings(lstBilling);
    Test.StopTest();
    lstBilling[0].Tax_Override__c = false;
    update lstBilling[0];

    lstBilling[0].Tax_Rate_Retail__c = 8.2;
    update lstBilling[0];

    //delete lstBilling;
  }

  @isTest
  static void testBillingData() {
    List<AcctSeed__Billing__c> lstBilling = new List<AcctSeed__Billing__c>();
    lstBilling = [SELECT Id, Tax_Rate_Retail__c, Tax_Override__c FROM AcctSeed__Billing__c];
    update lstBilling;

    Test.StartTest();
    AcctSeed.BillingPostService.postBillings(lstBilling);
    Test.StopTest();
  }
  @isTest
  static void testingthCashRceipt() {
    List<AcctSeed__Cash_Receipt__c> lstCashReceipt = new List<AcctSeed__Cash_Receipt__c>();
    lstCashReceipt = [SELECT Id, AcctSeed__Project__c, AcctSeed__Balance__c FROM AcctSeed__Cash_Receipt__c];
    List<AcctSeed__Billing__c> lstBilling = [SELECT Id, Tax_Rate_Retail__c, Tax_Override__c FROM AcctSeed__Billing__c];
    update lstBilling;
    Test.StartTest();
    AcctSeed.BillingPostService.postBillings(lstBilling);
    Test.StopTest();
  }

  @isTest
  static void testDeleteBilling() {
    Test.startTest();
    Account dealer = [SELECT Id FROM Account LIMIT 1];
    //AccountFactory.buildDealerAccount('Test Dealer UnitTester');
    List<AcctSeed__Project__c> erps = [SELECT id FROM AcctSeed__Project__c];
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
    delete billings;
    Test.stopTest();
  }
}
