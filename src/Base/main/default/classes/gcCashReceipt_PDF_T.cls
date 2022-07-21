@IsTest(SeeAllData=false)
public class gcCashReceipt_PDF_T {
  final static String RECORDTYPE = 'Insurance';
  final static String FAMILY = 'Insurance';
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

    insert lstCashReceipt;
  }

  @IsTest
  static void testProperties() {
    Test.startTest();
    AcctSeed__Cash_Receipt__c cashReceipt = [
      SELECT
        AcctSeed__Account__c,
        AcctSeed__Amount__c,
        AcctSeed__Receipt_Date__c,
        AcctSeed__Payment_Reference__c,
        AcctSeed__Ledger__c,
        AcctSeed__Project__c,
        AcctSeed__Project_Task__c,
        AcctSeed__Product__c
      FROM AcctSeed__Cash_Receipt__c
      LIMIT 1
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(cashReceipt);
    gcCashReceipt_PDF cashReceiptPDF = new gcCashReceipt_PDF(sc);
    Test.stopTest();
  }
}
