@IsTest(SeeAllData=false)
private class gcDealerReseved_Receipt_T {
    Static String businessAccountName = 'Test Business Account';
    final static String RECORDTYPE = 'Motor';
    final static String FAMILY = 'Remote';
    final static String SERIALNUMBER = '123450';
    final static String FNAME = 'TestFirstName';
    final static String LNAME = 'TestLastName';
    final static String TASKNAME = 'Test ERP Task';
    @TestSetup
    static void testData() {
        Test.startTest();
        new Factory_TestData();
        new Factory_AccountingVariables();
        Account businessAccount = Factory_Account.insertBusinessAccountWithContacts(businessAccountName, 1);
        businessAccount = [SELECT Id, AcctSeed__Accounting_Active__c, IsPersonAccount FROM Account WHERE id=: businessAccount.Id LIMIT 1];
        businessAccount.AcctSeed__Accounting_Active__c = true;
        update businessAccount;

        AcctSeed__Accounting_Period__c accPeriod = [SELECT Id FROM AcctSeed__Accounting_Period__c LIMIT 1];
        delete accPeriod;

        Date startDate = Date.today().toStartOfMonth().addMonths(-4);
        AcctSeed__Accounting_Period__c previousPeriod = new AcctSeed__Accounting_Period__c(
                AcctSeed__End_Date__c = Date.today().addMonths(-1).toStartOfMonth().addDays(-1),
                AcctSeed__Start_Date__c = startDate,
                AcctSeed__Status__c = 'Open',
                Name = Datetime.newInstance( startDate.year(),
                        startDate.month(),
                        startDate.day() ).format('YYYY-MM')
        );
        insert previousPeriod;

        AcctSeed__Accounting_Period__c period = new AcctSeed__Accounting_Period__c();
        period.Name = Datetime.Now().format('YYYY-MM');
        period.AcctSeed__Start_Date__c = Date.today().addMonths(-1).toStartOfMonth().addDays(1);
        period.AcctSeed__End_Date__c = Date.Today().addDays(15);
        period.AcctSeed__Status__c = 'Open';
        insert period;
        AcctSeed__GL_Account__c glAccount = new AcctSeed__GL_Account__c(
                AcctSeed__Bank__c = true,
                AcctSeed__Active__c = true,
                name = '1050-TestBankAccount',
                AcctSeed__Type__c = 'Balance Sheet',
                AcctSeed__Sub_Type_1__c = 'Assets',
                AcctSeed__Sub_Type_2__c = 'Cash'
        );
        insert glAccount;
        List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 10);
        GMBLASERP__Serial_Number__c serialNumber = Factory_SerialNumber.insertSerialNumber(serializedProducts[0], SERIALNUMBER);
        Account acct = Factory_Account.insertFullPersonAccount(FNAME, LNAME);
        Id erpRecordTypeId = Schema.SObjectType.AcctSeed__Project__c.getRecordTypeInfosByName().get('Project').getRecordTypeId();
        AcctSeed__Project__c erp = Factory_ERPOrder.buildERP(acct, serialNumber.Id, erpRecordTypeId);
        gcProject.disableTrigger = true;
        insert erp;
        AcctSeed__Project_Task__c erpTask = Factory_ERPOrder.buildProjectTask(erp.Id, TASKNAME);
        insert erpTask;
        Account dealer = AccountFactory.buildDealerAccount('Test Dealer UnitTester');
        insert dealer;

        // Billing
        AcctSeed__Billing_Format__c format = [SELECT Id FROM AcctSeed__Billing_Format__c WHERE Name = 'Billing PDF Format' LIMIT 1];
        AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
        AcctSeed__Billing__c billings = new AcctSeed__Billing__c(
                    AcctSeed__Customer__c = dealer.Id,
                    AcctSeed__Billing_Format__c = format.Id,
                    GMBLASERP__Project__c = erp.Id,
                    AcctSeed__Ledger__c = ledger.Id
            );

        Date thisMonth = Date.today();
        Date lastMonth = Date.today().toStartOfMonth().addMonths(-1);
        Date nextMonth = Date.today().toStartOfMonth().addMonths(1);
        //current
        billings.Lgnd_Due_Date__c = Date.newInstance(thisMonth.year(), thisMonth.month(), 15);

        insert billings;
        AcctSeed__Billing_Line__c billingLines = new AcctSeed__Billing_Line__c(
                    AcctSeed__Billing__c = billings.Id,
                    AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund,
                    AcctSeed__Hours_Units__c = 1,
                    AcctSeed__Rate__c = 3000.0,
                    AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
                    AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales,
                    AcctSeed__Project__c = billings.GMBLASERP__Project__c,
                    AcctSeed__Project_Task__c = erpTask.Id
            );

        insert billingLines;

        AcctSeed__Cash_Receipt__c cashReceipt_inprocess = new AcctSeed__Cash_Receipt__c();
        cashReceipt_inprocess.AcctSeed__Accounting_Period__c = period.Id;
        cashReceipt_inprocess.AcctSeed__Amount__c = 3000;
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
        cashReceipt_inprocess.AcctSeed__Product__c = serializedProducts[0].Id;
        cashReceipt_inprocess.AcctSeed__Project__c = erp.Id;
        cashReceipt_inprocess.AcctSeed__Project_Task__c = erpTask.Id;
        cashReceipt_inprocess.AcctSeed__Receipt_Date__c = Date.Today();
        cashReceipt_inprocess.AcctSeed__Purpose__c = 'Customer Receipt';
        cashReceipt_inprocess.AcctSeed__Payment_Reference__c = 'Test Payment Reference';
        insert cashReceipt_inprocess;

//        Test.StartTest();
//        AcctSeed.BillingPostService.postBillings(billings);
//        Test.StopTest();

        AcctSeed__Billing_Cash_Receipt__c billingCashReceipt = new AcctSeed__Billing_Cash_Receipt__c();
        billingCashReceipt.AcctSeed__Adjustment_GL_Account__c = gcConstants.idGlCash;
        billingCashReceipt.AcctSeed__Accounting_Period__c = period.Id;
        billingCashReceipt.AcctSeed__Billing__c = billings.Id;
        billingCashReceipt.AcctSeed__Cash_Receipt__c = cashReceipt_inprocess.Id;
        billingCashReceipt.AcctSeed__Status__c = 'Approved';
        billingCashReceipt.AcctSeed__Applied_Amount__c = 2800;
        billingCashReceipt.AcctSeed__Adjustment_Amount__c = 200;
        insert billingCashReceipt;
        gcProject.disableTrigger = false;
        Test.stopTest();
    }

    @IsTest
    static void testCreateFCBill(){
        //createFCBill(Id idAccount, Id idBankAccount, Id idBankGLAccount, String paymentRef, Decimal receiptAmount,
        // Decimal financeCharge, Decimal bankCharge, Boolean checkExisting, String effectDate, Id idERP, Id idGLV1)
        Test.startTest();
        AcctSeed__Project__c erp = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
        Id idBankGLAccount = gcConstants.idGlBankFees;
        Id idBankAccount = gcConstants.idGlBankFees;
        Id idAccount  = [SELECT Id FROM Account WHERE Name= 'Test Dealer UnitTester'][0].Id;
        String retValue = gcDealerReseved_Receipt.createFCBill(idAccount, idAccount, idBankGLAccount, 'test',2800,
                200, 1,true,Date.today().format(),erp.id, gcConstants.idGlv1Barrie);
        Test.stopTest();
    }

    @IsTest
    static void testRetrieveBankAccounts(){
        Test.startTest();
        List<SelectOption> options = gcDealerReseved_Receipt.getRetrieveBankAccounts();
        gcDealerReseved_Receipt obj = new gcDealerReseved_Receipt();
        string locale = gcDealerReseved_Receipt.locale;
        Test.stopTest();
    }

    @IsTest
    static void testCreateFCBillFinanceCharge0(){
        //createFCBill(Id idAccount, Id idBankAccount, Id idBankGLAccount, String paymentRef, Decimal receiptAmount,
        // Decimal financeCharge, Decimal bankCharge, Boolean checkExisting, String effectDate, Id idERP, Id idGLV1)
        Test.startTest();
        AcctSeed__Project__c erp = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
        Id idBankGLAccount = gcConstants.idGlBankFees;
        Id idBankAccount = gcConstants.idGlBankFees;
        Id idAccount  = [SELECT Id FROM Account WHERE Name= 'Test Dealer UnitTester'][0].Id;
        try {
            String retValue = gcDealerReseved_Receipt.createFCBill(idAccount, idAccount, idBankGLAccount, 'test', 2800,
                    0, -1, true, Date.today().format(), erp.id, gcConstants.idGlv1Barrie);
        }catch(Exception ex){}
        Test.stopTest();
    }
    @IsTest
    static void testCheckExistingReceipt(){
        Test.startTest();
        Id idBankGLAccount = gcConstants.idGlBankFees;
        Id idBankAccount = gcConstants.idGlBankFees;
        Id idAccount  = [SELECT Id FROM Account WHERE Name= 'Test Dealer UnitTester'][0].Id;
        Boolean flag = gcDealerReseved_Receipt.checkExistingReceipt(idAccount, idBankAccount, idBankGLAccount);
        system.debug('### flag: ' + flag);
        Test.stopTest();
    }

    @IsTest
    static void testSearchGLVAccount(){
        Test.startTest();
        List<AcctSeed__Accounting_Variable__c> lstAccVariable = [SELECT Id, Name FROM AcctSeed__Accounting_Variable__c WHERE Name=:'Retail Barrie' AND AcctSeed__Type__c = 'GL Account Variable 1'];
        List<AcctSeed__Accounting_Variable__c> results = gcDealerReseved_Receipt.searchGLVAccount('Barrie');

        system.assertEquals(lstAccVariable[0].Name, results[0].Name);
        Test.stopTest();
    }

    @IsTest
    static void testSearchERPAccount(){
        Test.startTest();
        Account personAccount = [SELECT Id, FirstName, LastName, Name FROM Account WHERE FirstName=:FNAME AND LastName=:LNAME];
        List<AcctSeed__Project__c> lstErp = gcDealerReseved_Receipt.searchERPAccount(personAccount.Id, 'Test');
        System.debug('##### lstErp: ' + lstErp);
        system.assertEquals(personAccount.FirstName + '_' + personAccount.LastName, lstErp[0].Name);
        Test.stopTest();
    }
    @IsTest
    static void getRetrieveBankGLAccounts() {
        Test.startTest();
        List<AcctSeed__GL_Account__c> glAccounts = [SELECT Id, Name FROM AcctSeed__GL_Account__c];
        List<SelectOption> listOptions = gcDealerReseved_Receipt.getRetrieveBankGLAccounts();
        system.debug('### selectOption: ' + listOptions);
        //system.assertEquals(listOptions[0].getValue(), glAccounts[0].Id);
        //system.assertEquals(listOptions[0].getLabel(), glAccounts[0].Name);
        test.stopTest();
    }

    @IsTest
    static void testSearchBankAccount(){
        Test.startTest();
        List<Account> lstAccount = gcDealerReseved_Receipt.searchBankAccount('Test Business');
        System.assertEquals(businessAccountName, lstAccount[0].Name);
        test.stopTest();
    }
}