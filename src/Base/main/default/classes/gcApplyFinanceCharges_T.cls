@isTest(seeAllData=false)
public class gcApplyFinanceCharges_T {
  final static String RECORDTYPE = 'Motor';
  final static String FAMILY = 'Remote';
  final static String SERIALNUMBER = '123450';
  final static String FNAME = 'TestFirstName';
  final static String LNAME = 'TestLastName';
  final static String TASKNAME = 'Test ERP Task';
  @TestSetup
  static void testData() {
    new Factory_TestData();
    List<Account> lstCustomerAccounts = Factory_Account.insertCustomerAccounts(5);
    List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 10);

    GMBLASERP__Serial_Number__c serialNumber = Factory_SerialNumber.insertSerialNumber(
      serializedProducts[0],
      SERIALNUMBER
    );
    Account acct = Factory_Account.insertFullPersonAccount(FNAME, LNAME);
    Id erpRecordTypeId = Schema.SObjectType.AcctSeed__Project__c.getRecordTypeInfosByName()
      .get('Project')
      .getRecordTypeId();
    AcctSeed__Project__c erp = Factory_ERPOrder.buildERP(acct, serialNumber.Id, erpRecordTypeId);
    AcctSeed__Project_Task__c erpTask = Factory_ERPOrder.buildProjectTask(erp.Id, TASKNAME);
    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    AcctSeed__Accounting_Period__c accPeriod = [SELECT Id FROM AcctSeed__Accounting_Period__c LIMIT 1];
    delete accPeriod;

    AcctSeed__Accounting_Period__c period = new AcctSeed__Accounting_Period__c();
    period.Name = Datetime.Now().format('YYYY-MM');
    period.AcctSeed__Start_Date__c = Date.Today().addMonths(-15);
    period.AcctSeed__End_Date__c = Date.Today().addDays(15);
    period.AcctSeed__Status__c = 'Open';
    insert period;

    AcctSeed__Cash_Receipt__c cashReceipt_inprocess = new AcctSeed__Cash_Receipt__c();
    cashReceipt_inprocess.AcctSeed__Accounting_Period__c = period.Id;
    cashReceipt_inprocess.AcctSeed__Amount__c = 5000;
    cashReceipt_inprocess.AcctSeed__Bank_Account__c = gcConstants.idGlBankFees;
    cashReceipt_inprocess.AcctSeed__Cash_Flow_Category__c = gcConstants.idGlRevenueCF;
    cashReceipt_inprocess.AcctSeed__Cleared_Date__c = Date.Today().addMonths(-1);
    cashReceipt_inprocess.AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
    cashReceipt_inprocess.AcctSeed__Credit_GL_Account__c = gcConstants.idGlInternalRevenue;
    cashReceipt_inprocess.AcctSeed__Account__c = lstCustomerAccounts[0].Id;
    cashReceipt_inprocess.AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales;
    cashReceipt_inprocess.AcctSeed__Ledger__c = ledger.Id;
    cashReceipt_inprocess.Payment_Method__c = 'Cash';
    cashReceipt_inprocess.AcctSeed__Status__c = 'In Process';
    cashReceipt_inprocess.AcctSeed__Product__c = serializedProducts[0].Id;
    cashReceipt_inprocess.AcctSeed__Project__c = erp.Id;
    cashReceipt_inprocess.AcctSeed__Project_Task__c = erpTask.Id;
    cashReceipt_inprocess.AcctSeed__Receipt_Date__c = Date.Today();
    cashReceipt_inprocess.AcctSeed__Purpose__c = 'Customer Receipt';
    cashReceipt_inprocess.AcctSeed__Payment_Reference__c = LGND_Utilities.generateRandomString(6)+String.valueOf(System.now());
    insert cashReceipt_inprocess;

    AcctSeed__Billing_Format__c pdfFormat = [SELECT id FROM AcctSeed__Billing_Format__c LIMIT 1];
    AcctSeed__Billing__c billing = new AcctSeed__Billing__c();
    billing.AcctSeed__Accounting_Period__c = period.Id;
    billing.AcctSeed__Billing_Format__c = pdfFormat.Id;
    billing.AcctSeed__Customer__c = lstCustomerAccounts[0].Id;
    billing.AcctSeed__Ledger__c = ledger.Id;
    billing.GMBLASERP__Project__c = erp.Id;
    billing.GL_Account_Variable_3__c = gcConstants.idGlv3Ontario;
    insert billing;

    AcctSeed__Billing_Line__c billingLine = new AcctSeed__Billing_Line__c(
      AcctSeed__Billing__c = billing.Id,
      AcctSeed__Hours_Units__c = 1,
      AcctSeed__Rate__c = 5000,
      AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund,
      AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
      AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales
    );
    insert billingLine;

    AcctSeed.BillingPostService.postBillings(new List<AcctSeed__Billing__c>{ billing });
    AcctSeed__Billing_Cash_Receipt__c billingCashReceipt = new AcctSeed__Billing_Cash_Receipt__c();
    billingCashReceipt.AcctSeed__Adjustment_GL_Account__c = gcConstants.idGlCash;
    billingCashReceipt.AcctSeed__Accounting_Period__c = period.Id;
    billingCashReceipt.AcctSeed__Billing__c = billing.Id;
    billingCashReceipt.AcctSeed__Cash_Receipt__c = cashReceipt_inprocess.Id;
    billingCashReceipt.AcctSeed__Status__c = 'Approved';
    billingCashReceipt.AcctSeed__Applied_Amount__c = 100;
    billingCashReceipt.AcctSeed__Adjustment_Amount__c = 10;
    insert billingCashReceipt;
  }

  @isTest
  static void testMethod1() {
    AcctSeed__Cash_Receipt__c cashReceipt = [SELECT Id FROM AcctSeed__Cash_Receipt__c LIMIT 1];
    AcctSeed__Billing__c accountBilling = [
      SELECT
        Id,
        Name,
        AcctSeed__Date__c,
        AcctSeed__Total__c,
        AcctSeed__Balance__c,
        AcctSeed__Customer__c,
        AcctSeed__Customer__r.Name
      FROM AcctSeed__Billing__c
      LIMIT 1
    ];
    ApexPages.standardController sc = new ApexPages.standardController(cashReceipt);
    gcApplyFinanceCharges charges = new gcApplyFinanceCharges(sc);

    AcctSeed__Cash_Receipt__c cr = gcApplyFinanceCharges.retrieveCR(cashReceipt.Id);
    system.assertEquals(4900, cr.AcctSeed__Balance__c);

    List<Map<String, String>> mapResult = gcApplyFinanceCharges.retrieveAppliedCash(cashReceipt.Id);

    Test.startTest();
    if (!mapResult.isEmpty()) {
      system.assertEquals('100.000000', mapResult[0].get('appliedAmount'));
      system.assertEquals('10.000000', mapResult[0].get('adjustedAmount'));
      system.assertEquals('5000.000000', mapResult[0].get('billingTotal'));
      system.assertEquals('4890.000000', mapResult[0].get('billingBalance')); //5000-100-10
    }

    gcApplyFinanceCharges.createFCBill(cashReceipt.Id, 50, 50);

    List<AcctSeed__Billing_Line__c> lstBillingLine = [SELECT id FROM AcctSeed__Billing_Line__c];
    System.assertEquals(false, lstBillingLine.isEmpty());

    List<AcctSeed__Billing_Cash_Receipt__c> lstBillingCashReceipt = [SELECT id FROM AcctSeed__Billing_Cash_Receipt__c];
    System.assertEquals(false, lstBillingCashReceipt.isEmpty());

    List<Map<String, String>> mapOpenBilling = gcApplyFinanceCharges.retrieveOpenBillings(cashReceipt.Id);
    system.assertEquals('4890.000000', mapOpenBilling[0].get('billBalance')); //5000-100-10
    system.assertEquals('5000.000000', mapOpenBilling[0].get('billTotal'));

    Map<String, String> mapCashReceipt = gcApplyFinanceCharges.wrapCashReceipt(accountBilling);
    system.assertEquals('5000.000000', mapCashReceipt.get('billTotal'));
    system.assertEquals('4890.000000', mapCashReceipt.get('billBalance'));

    Map<String, String> mapBCR = gcApplyFinanceCharges.applyBCR(cashReceipt.Id, accountBilling.Id, 1000);
    system.assertEquals('3890.000000', mapBCR.get('billBalance')); //As CAD 1000 applied (4890 - 1000)
    system.assertEquals('5000.000000', mapBCR.get('billTotal'));

    Test.stopTest();

    new gcApplyFinanceCharges();
    gcApplyFinanceCharges.deleteBCR(cashReceipt.Id);

    List<AcctSeed__Billing_Cash_Receipt__c> lstReceiptDeleted = [
      SELECT Id
      FROM AcctSeed__Billing_Cash_Receipt__c
      WHERE Id = :cashReceipt.Id
    ];
    system.assertEquals(true, lstReceiptDeleted.isEmpty());
  }

  @isTest
  static void testMethod2NegativeTesting() {
    AcctSeed__Cash_Receipt__c cashReceipt = [SELECT Id FROM AcctSeed__Cash_Receipt__c LIMIT 1];
    AcctSeed__Billing__c accountBilling = [
      SELECT
        Id,
        Name,
        AcctSeed__Date__c,
        AcctSeed__Total__c,
        AcctSeed__Balance__c,
        AcctSeed__Customer__c,
        AcctSeed__Customer__r.Name
      FROM AcctSeed__Billing__c
      LIMIT 1
    ];
    ApexPages.standardController sc = new ApexPages.standardController(cashReceipt);
    //AcctSeed__Balance__c = 4900 (5000-100)
    try {
      Map<String, String> mapBCR = gcApplyFinanceCharges.applyBCR(cashReceipt.Id, accountBilling.Id, 10000);
    } catch (Exception ex) {
      System.assertEquals('Applied amount cannot be greater than billing balance.', ex.getMessage());
    }

    try {
      Map<String, String> mapBCR = gcApplyFinanceCharges.applyBCR(cashReceipt.Id, accountBilling.Id, 4900);
    } catch (Exception ex) {
      //Applied amount cannot be greater than billing balance.
      //System.assertEquals('Applied amount cannot be greater than cash receipt balance.', ex.getMessage());
    }
    /*
        try{
            AcctSeed__Cash_Receipt__c cr = [SELECT Id, AcctSeed__Balance__c FROM AcctSeed__Cash_Receipt__c WHERE Id =:cashReceipt.Id][0];
            cr.AcctSeed__Amount__c  = 0;
            update cr;
            AcctSeed__Billing_Cash_Receipt__c bcr = [SELECT id, AcctSeed__Applied_Amount__c FROM AcctSeed__Billing_Cash_Receipt__c];
            bcr.AcctSeed__Applied_Amount__c = 0;
            update bcr;
            
        	Map<String,String> mapBCR = gcApplyFinanceCharges.applyBCR(cashReceipt.Id, accountBilling.Id, 10000);
        }
        catch(Exception ex){
            System.assertEquals('No more available balance for this cash receipt.', ex.getMessage());
        }*/
  }
}
