@isTest
public class gcBilling_Actions_T {
  final static String RECORDTYPE = 'Motor';
  final static String FAMILY = 'Remote';
  final static String SERIALNUMBER = '123450';
  final static String FNAME = 'TestFirstName';
  final static String LNAME = 'TestLastName';
  final static String TASKNAME = 'Test ERP Task';

  @TestSetup
  static void testData() {
    AcctSeed__Accounting_Period__c period;
    Map<Id, AcctSeed__Project_Task__c> erp_task_map;
    Product2[] parts;
    Account dealer;
    List<AcctSeed__Project__c> erps;
    AcctSeed__Ledger__c ledger;
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Contact dealerContact;

    AcctSeed__Accounting_Period__c accPeriod = [SELECT Id FROM AcctSeed__Accounting_Period__c LIMIT 1];
    delete accPeriod;

    Date startDate = Date.today().toStartOfMonth().addMonths(-4);
    AcctSeed__Accounting_Period__c previousPeriod = new AcctSeed__Accounting_Period__c(
      AcctSeed__End_Date__c = Date.today().addMonths(-1).toStartOfMonth().addDays(-1),
      AcctSeed__Start_Date__c = startDate,
      AcctSeed__Status__c = 'Open',
      Name = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('YYYY-MM')
    );
    insert previousPeriod;

    period = new AcctSeed__Accounting_Period__c();
    period.Name = Datetime.Now().format('YYYY-MM');
    period.AcctSeed__Start_Date__c = Date.today().addMonths(-1).toStartOfMonth().addDays(1);
    period.AcctSeed__End_Date__c = Date.Today().addDays(15);
    period.AcctSeed__Status__c = 'Open';
    insert period;
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
    parts = Factory_Product.buildNonSerializedProducts('Part', 'Hardware', 5);
    insert parts;
    List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();
    for (AcctSeed__Project_Task__c task : erp_task_map.values()) {
      for (Product2 part : parts) {
        mats.add(Factory_ERPOrder.buildMaterial(task.AcctSeed__Project__c, task.Id, part.Id));
      }
    }
    insert mats;

    // Billing
    AcctSeed__Billing_Format__c format = [
      SELECT Id
      FROM AcctSeed__Billing_Format__c
      WHERE Name = 'Billing PDF Format'
      LIMIT 1
    ];
    ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
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
          AcctSeed__Rate__c = 3000.0,
          AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
          AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales,
          AcctSeed__Project__c = billing.GMBLASERP__Project__c,
          AcctSeed__Project_Task__c = erp_task_map.get(billing.GMBLASERP__Project__c).Id
        )
      );
    }
    insert billingLines;

    AcctSeed__Cash_Receipt__c cashReceipt_inprocess = new AcctSeed__Cash_Receipt__c();
    cashReceipt_inprocess.AcctSeed__Accounting_Period__c = period.Id;
    cashReceipt_inprocess.AcctSeed__Amount__c = 3200;
    cashReceipt_inprocess.AcctSeed__Bank_Account__c = gcConstants.idGlBankFees;
    cashReceipt_inprocess.AcctSeed__Cash_Flow_Category__c = gcConstants.idGlRevenueCF;
    cashReceipt_inprocess.AcctSeed__Cleared_Date__c = Date.Today().addMonths(-1);
    cashReceipt_inprocess.AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
    cashReceipt_inprocess.AcctSeed__Credit_GL_Account__c = gcConstants.idGlInternalRevenue;
    cashReceipt_inprocess.AcctSeed__Account__c = dealer.Id;
    cashReceipt_inprocess.AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales;
    cashReceipt_inprocess.AcctSeed__Ledger__c = ledger.Id;
    cashReceipt_inprocess.Payment_Method__c = 'Cash';
    cashReceipt_inprocess.AcctSeed__Status__c = 'In Process';
    cashReceipt_inprocess.AcctSeed__Product__c = parts[0].Id;
    cashReceipt_inprocess.AcctSeed__Project__c = erps[0].Id;
    cashReceipt_inprocess.AcctSeed__Project_Task__c = erp_task_map.get(erps[0].Id).Id;
    cashReceipt_inprocess.AcctSeed__Receipt_Date__c = Date.Today();
    cashReceipt_inprocess.AcctSeed__Purpose__c = 'Customer Receipt';
    cashReceipt_inprocess.AcctSeed__Payment_Reference__c = LGND_Utilities.generateRandomString(6)+String.valueOf(System.now());
    cashReceipt_inprocess.AcctSeed__Cash_Flow_Category__c = gcConstants.idGlRevenueCF;
    insert cashReceipt_inprocess;

    Test.StartTest();
    //AcctSeed.BillingPostService.unpostBillings(billings);
    AcctSeed.BillingPostService.postBillings(billings);
    Test.StopTest();
    AcctSeed__Cash_Receipt__c cr = [
      SELECT AcctSeed__Balance__c
      FROM AcctSeed__Cash_Receipt__c
      WHERE Id = :cashReceipt_inprocess.Id
    ];
    System.debug('cr cr');
    System.debug(cr);
    /*AcctSeed__Billing_Cash_Receipt__c billingCashReceipt = new AcctSeed__Billing_Cash_Receipt__c();
        //billingCashReceipt.AcctSeed__Adjustment_GL_Account__c = gcConstants.idGlCash;
        billingCashReceipt.AcctSeed__Accounting_Period__c = period.Id;
        billingCashReceipt.AcctSeed__Billing__c = billings[0].Id;
        billingCashReceipt.AcctSeed__Cash_Receipt__c = cashReceipt_inprocess.Id;
//        billingCashReceipt.AcctSeed__Status__c = 'Approved';
        billingCashReceipt.AcctSeed__Applied_Amount__c = 2800;
//        billingCashReceipt.AcctSeed__Adjustment_Amount__c = 200;
        insert billingCashReceipt;*/
  }
  private static AcctSeed__Billing__c generateBillingCreditMemo(AcctSeed__Billing__c billing) {
    // Test Data to generate refund

    String name = Datetime.Now().format('YYYY-MM');
    Date startDate = Date.today().addMonths(-1).toStartOfMonth().addDays(1);
    Date endDate = Date.Today().addDays(15);

    AcctSeed__Accounting_Period__c period = [
      SELECT Id
      FROM AcctSeed__Accounting_Period__c
      WHERE
        Name = :name
        AND AcctSeed__Start_Date__c = :startDate
        AND AcctSeed__End_Date__c = :endDate
        AND AcctSeed__Status__c = 'Open'
    ];
    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    Account dealer = [SELECT Id FROM Account WHERE Name = 'Test Dealer UnitTester'];
    List<Product2> parts = [SELECT Id FROM Product2];
    AcctSeed__Billing__c cloneBill = billing.clone(false, true);
    insert cloneBill;
    AcctSeed__Billing__c newBill = [
      SELECT Id, GMBLASERP__Project__c, AcctSeed__Total__c, AcctSeed__Accounting_Period__c
      FROM AcctSeed__Billing__c
      WHERE Id = :cloneBill.Id
    ];
    //AcctSeed__Project_Task__c
    AcctSeed__Project_Task__c erp_task = [
      SELECT id
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c = :billing.GMBLASERP__Project__c
    ];
    //Billing line with negative amount
    AcctSeed__Billing_Line__c billingLine = new AcctSeed__Billing_Line__c();
    billingLine.AcctSeed__Billing__c = newBill.Id;
    billingLine.AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund;
    billingLine.AcctSeed__Hours_Units__c = 1;
    billingLine.AcctSeed__Rate__c = -5000.0;
    billingLine.AcctSeed__Tax_Amount2__c = 1;
    billingLine.AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
    billingLine.AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales;
    billingLine.AcctSeed__Project__c = billing.GMBLASERP__Project__c;
    billingLine.AcctSeed__Project_Task__c = erp_task.Id;
    insert billingLine;

    AcctSeed.BillingPostService.postBillings(new List<AcctSeed__Billing__c>{ newBill });

    return newBill;
  }
  @isTest
  private static void testMethod4Refund() {
    List<AcctSeed__Billing__c> billings = [
      SELECT
        Id,
        Name,
        AcctSeed__Balance__c,
        AcctSeed__Billing_City__c,
        AcctSeed__Billing_Comment__c,
        AcctSeed__Billing_Contact__c,
        AcctSeed__Billing_Country__c,
        AcctSeed__Billing_Cycle_End_Date__c,
        AcctSeed__Billing_Cycle_Start_Date__c,
        AcctSeed__Billing_Format__c,
        AcctSeed__Billing_PostalCode__c,
        AcctSeed__Billing_State__c,
        AcctSeed__Billing_Street__c,
        AcctSeed__Billing_Terms_Name__c,
        AcctSeed__Customer__c,
        AcctSeed__Opportunity__c,
        AcctSeed__PO_Number__c,
        AcctSeed__Shipping_City__c,
        AcctSeed__Shipping_Contact__c,
        AcctSeed__Shipping_Country__c,
        AcctSeed__Shipping_PostalCode__c,
        AcctSeed__Shipping_State__c,
        AcctSeed__Shipping_Street__c,
        AcctSeed__Total__c,
        AcctSeedERP__Sales_Order__c,
        GL_Account_Variable_3__c,
        GMBLASERP__Project__c,
        Tax_is_Harmonized__c,
        Tax_Override__c,
        Tax_Rate_Federal__c,
        Tax_Rate_Provincial__c,
        Tax_Rate_Retail__c,
        (
          SELECT
            Id,
            AcctSeed__Billing__c,
            AcctSeed__GL_Account_Variable_1__c,
            AcctSeed__GL_Account_Variable_2__c,
            AcctSeed__GL_Account_Variable_3__c,
            AcctSeed__GL_Account_Variable_4__c,
            AcctSeed__Project__c,
            AcctSeed__Project_Task__c,
            GMBLASERP__Material__c,
            AcctSeed__Employee__c,
            AcctSeed__Expense_GL_Account__c,
            AcctSeed__Product__c,
            AcctSeed__Product_Unit_Cost__c,
            AcctSeed__Hours_Units__c,
            AcctSeed__Rate__c,
            AcctSeed__Revenue_GL_Account__c,
            AcctSeedERP__Sales_Order_Line__c,
            Taxable_Federal__c,
            Taxable_Provincial__c,
            Taxable_Retail__c,
            AcctSeed__Total__c
          FROM AcctSeed__Project_Billing_Lines__r
        )
      FROM AcctSeed__Billing__c
    ];
    Test.startTest();
    AcctSeed__Billing__c negativeBill = generateBillingCreditMemo(billings[0]);

    Test.setCurrentPage(Page.gpBilling_Actions);
    ApexPages.currentPage().getParameters().put('retUrl', 'www.google.com');

    ApexPages.currentPage().getParameters().put('processName', 'billing');
    ApexPages.currentPage().getParameters().put('idFilter', negativeBill.Id);
    ApexPages.StandardController std = new ApexPages.StandardController(negativeBill);
    gcBilling_Actions ext = new gcBilling_Actions(std);
    ext.init();
    Test.stopTest();
  }

  @isTest
  private static void testMethod1StandardControllerBillingProcess() {
    List<AcctSeed__Billing__c> billings = [SELECT Id FROM AcctSeed__Billing__c];
    List<AcctSeed__Billing_Line__c> billingLines = [SELECT Id FROM AcctSeed__Billing_Line__c];

    Test.setCurrentPage(Page.gpBilling_Actions);
    ApexPages.currentPage().getParameters().put('retUrl', 'www.google.com');

    ApexPages.currentPage().getParameters().put('processName', 'billing');
    ApexPages.currentPage().getParameters().put('idFilter', billings[0].Id);
    ApexPages.StandardController std = new ApexPages.StandardController(billings[0]);

    Test.StartTest();
    gcBilling_Actions ext = new gcBilling_Actions(std);
    ext.init();
    Test.StopTest();
  }

  @isTest
  private static void testMethod2StandardControllerAPLine() {
    List<AcctSeed__Billing__c> billings = [SELECT Id FROM AcctSeed__Billing__c];
    List<AcctSeed__Billing_Line__c> billingLines = [SELECT Id FROM AcctSeed__Billing_Line__c];

    Test.setCurrentPage(Page.gpBilling_Actions);
    ApexPages.currentPage().getParameters().put('retUrl', 'www.google.com');

    ApexPages.currentPage().getParameters().put('idFilter', billingLines[0].Id);
    ApexPages.StandardController std = new ApexPages.StandardController(billingLines[0]);

    Test.StartTest();
    gcBilling_Actions ext = new gcBilling_Actions(std);
    ext.init();
    Test.StopTest();
  }
  @isTest
  private static void testMethod3StandardSetController() {
    List<AcctSeed__Billing__c> billings = [SELECT Id FROM AcctSeed__Billing__c];
    List<AcctSeed__Billing_Line__c> billingLines = [SELECT Id FROM AcctSeed__Billing_Line__c];

    Test.setCurrentPage(Page.gpBilling_Actions);
    ApexPages.currentPage().getParameters().put('retUrl', 'www.google.com');

    ApexPages.currentPage().getParameters().put('processName', 'billing');
    ApexPages.currentPage().getParameters().put('idFilter', billingLines[0].Id);
    ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(billingLines);
    stdSetController.setSelected(billingLines);
    Test.StartTest();
    gcBilling_Actions ext = new gcBilling_Actions(stdSetController);
    ext.init();
    ext.createAPLines();
    Test.StopTest();
  }
}
