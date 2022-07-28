@IsTest
public class gcCashReceipt_Refund_T {
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
    period.AcctSeed__Start_Date__c = Date.today().addMonths(-1);
    period.AcctSeed__End_Date__c = Date.Today().addMonths(2);
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
    AcctSeed__Cash_Receipt__c cashReceipt = new AcctSeed__Cash_Receipt__c(
      AcctSeed__Account__c = dealer.Id,
      AcctSeed__Amount__c = 500.0,
      AcctSeed__Receipt_Date__c = Date.today(),
      AcctSeed__Payment_Reference__c = LGND_Utilities.generateRandomString(6)+String.valueOf(System.now()),
      AcctSeed__Ledger__c = ledger.Id,
      AcctSeed__Project__c = erps[0].Id,
      AcctSeed__Project_Task__c = erp_task_map.get(erps[0].Id).Id,
      AcctSeed__Product__c = parts[0].Id,
      Payment_Method__c = 'Visa',
      AcctSeed__Cash_Flow_Category__c = gcConstants.idGlRevenueCF
    );
    insert cashReceipt;
  }

  @IsTest
  static void testRefundAmount() {
    List<AcctSeed__Cash_Receipt__c> lstCashReceipt = [
      SELECT
        Id,
        AcctSeed__Balance__c,
        AcctSeed__Status__c,
        GMBLASG__Posted__c,
        AcctSeed__Applied_Amount__c,
        AcctSeed__Amount__c
      FROM AcctSeed__Cash_Receipt__c
    ];

    ApexPages.StandardController sc = new ApexPages.StandardController(lstCashReceipt[0]);
    gcCashReceipt_Refund refund = new gcCashReceipt_Refund(sc);

    Test.startTest();
    String returnString = gcCashReceipt_Refund.createRefund(lstCashReceipt[0].Id, 4);

    AcctSeed__Account_Payable__c verifyResult = [
      SELECT Id, AcctSeed__Payee_Reference__c, AcctSeed__Date__c
      FROM AcctSeed__Account_Payable__c
      WHERE ID = :returnString
    ];
    System.assertNotEquals(null, verifyResult);
    System.assertEquals(Date.today(), verifyResult.AcctSeed__Date__c);

    Test.stopTest();
  }
}
