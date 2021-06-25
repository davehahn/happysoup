@IsTest(SeeAllData=false)
public class gcCashDisbursement_T {
    final static String RECORDTYPE = 'Insurance';
    final static String FAMILY = 'Insurance';
    final static String SERIALNUMBER = '123450';
    @TestSetup
    static void testData(){
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        AcctSeed__Cash_Disbursement_Batch__c cdb = new AcctSeed__Cash_Disbursement_Batch__c(
                Name = 'Test'
        );
        insert cdb;

        AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
        //AcctSeed__Cash_Disbursement_Batch__c cdb = [SELECT Id FROM AcctSeed__Cash_Disbursement_Batch__c LIMIT 1][0];
        AcctSeed__Accounting_Period__c period = [SELECT Id FROM AcctSeed__Accounting_Period__c LIMIT 1];
        AcctSeed__GL_Account__c bank = [SELECT Id FROM AcctSeed__GL_Account__c WHERE AcctSeed__Bank__c = true LIMIT 1];
        Account supplier = Factory_Account.insertSupplierAccounts(1)[0];
        AcctSeed__Cash_Disbursement__c cd = new AcctSeed__Cash_Disbursement__c(
                AcctSeed__Amount__c = 10,
                AcctSeed__Accounting_Period__c = period.Id,
                AcctSeed__Bank_Account__c = bank.Id,
                AcctSeed__Cash_Disbursement_Batch__c = cdb.Id,
                AcctSeed__Ledger__c = ledger.Id,
                AcctSeed__Vendor__c = supplier.Id,
                AcctSeed__Status__c = 'Approved',
                AcctSeed__Disbursement_Date__c = Date.today(),
                AcctSeed__Debit_GL_Account__c = null
        );
        insert cd;
    }

    @IsTest
    static void testProperties() {
        gcCashDisbursement.disableTrigger = null;
        boolean flag = gcCashDisbursement.disableTrigger;
        System.assertEquals(false, flag);

        gcCashDisbursement.disableTrigger = true;
        flag = gcCashDisbursement.disableTrigger;
        System.assertEquals(true, flag);
    }

    @IsTest
    static void testUpdateCheckNumber(){
        AcctSeed__Cash_Disbursement__c cashDisbursement = [
                SELECT
                        Id, AcctSeed__Amount__c, AcctSeed__Accounting_Period__c,
                        AcctSeed__Bank_Account__c,   AcctSeed__Cash_Disbursement_Batch__c,
                        AcctSeed__Ledger__c, AcctSeed__Vendor__c, AcctSeed__Status__c,
                        AcctSeed__Disbursement_Date__c, AcctSeed__Debit_GL_Account__c, AcctSeed__Check_Number__c
                FROM
                        AcctSeed__Cash_Disbursement__c
                LIMIT 1
        ];
        Test.startTest();
        AcctSeed__Cash_Disbursement__c cd = cashDisbursement.clone();
        cd.AcctSeed__Status__c = 'Approved';
        cd.AcctSeed__Disbursement_Date__c = Date.today();
        cd.AcctSeed__Debit_GL_Account__c = gcConstants.idGlCustomerRefund;
        cd.AcctSeed__Payment_Status__c = 'Paid';
        cd.AcctSeed__Check_Number__c = 100;
        insert cd;
        AcctSeed.PostResult[] postResults = AcctSeed.CashDisbursementPostService.unpostCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{cd});

        AcctSeed__Cash_Disbursement__c cd2 = [
                SELECT
                        Id, AcctSeed__Check_Number__c
                FROM
                        AcctSeed__Cash_Disbursement__c
                WHERE
                        Id =: cd.Id
                LIMIT 1
        ];
        cd2.AcctSeed__Check_Number__c = 101;
        update cd2;

        Test.stopTest();
    }

    @IsTest
    static void testPaymentMethodCC(){
        AcctSeed__Cash_Disbursement__c cd = [
                SELECT
                        Id, AcctSeed__Amount__c, AcctSeed__Accounting_Period__c,
                        AcctSeed__Bank_Account__c,   AcctSeed__Cash_Disbursement_Batch__c,
                        AcctSeed__Ledger__c, AcctSeed__Vendor__c, AcctSeed__Status__c,
                        AcctSeed__Disbursement_Date__c, AcctSeed__Debit_GL_Account__c, GMBLASG__Posted__c,
                        AcctSeed__Type__c
                FROM
                        AcctSeed__Cash_Disbursement__c
                LIMIT 1
        ];
        Test.startTest();
        AcctSeed.CashDisbursementPostService.unpostCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{cd});
        List<AcctSeed__Cash_Disbursement__c> lstWithPaymentMethod = new List<AcctSeed__Cash_Disbursement__c>();

        AcctSeed__Cash_Disbursement__c typeCC = cd.clone();
        typeCC.AcctSeed__Type__c = 'Credit Card';
        lstWithPaymentMethod.add(typeCC);

        Insert lstWithPaymentMethod;

        Test.stopTest();
    }

    @IsTest
    static void testPaymentMethodDraft(){
        AcctSeed__Cash_Disbursement__c cd = [
                SELECT
                        Id, AcctSeed__Amount__c, AcctSeed__Accounting_Period__c,
                        AcctSeed__Bank_Account__c,   AcctSeed__Cash_Disbursement_Batch__c,
                        AcctSeed__Ledger__c, AcctSeed__Vendor__c, AcctSeed__Status__c,
                        AcctSeed__Disbursement_Date__c, AcctSeed__Debit_GL_Account__c, GMBLASG__Posted__c,
                        AcctSeed__Type__c
                FROM
                        AcctSeed__Cash_Disbursement__c
                LIMIT 1
        ];
        Test.startTest();
        AcctSeed.CashDisbursementPostService.unpostCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{cd});
        List<AcctSeed__Cash_Disbursement__c> lstWithPaymentMethod = new List<AcctSeed__Cash_Disbursement__c>();

        AcctSeed__Cash_Disbursement__c typeDraft = cd.clone();
        typeDraft.AcctSeed__Type__c = 'Draft';
        lstWithPaymentMethod.add(typeDraft);

        Insert lstWithPaymentMethod;

        Test.stopTest();
    }

    @IsTest
    static void testPaymentMethodCCC(){
        AcctSeed__Cash_Disbursement__c cd = [
                SELECT
                        Id, AcctSeed__Amount__c, AcctSeed__Accounting_Period__c,
                        AcctSeed__Bank_Account__c,   AcctSeed__Cash_Disbursement_Batch__c,
                        AcctSeed__Ledger__c, AcctSeed__Vendor__c, AcctSeed__Status__c,
                        AcctSeed__Disbursement_Date__c, AcctSeed__Debit_GL_Account__c, GMBLASG__Posted__c,
                        AcctSeed__Type__c
                FROM
                        AcctSeed__Cash_Disbursement__c
                LIMIT 1
        ];
        Test.startTest();
        AcctSeed.CashDisbursementPostService.unpostCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{cd});
        List<AcctSeed__Cash_Disbursement__c> lstWithPaymentMethod = new List<AcctSeed__Cash_Disbursement__c>();

        AcctSeed__Cash_Disbursement__c typeCCC = cd.clone();
        typeCCC.AcctSeed__Type__c = 'Company Credit Card';
        lstWithPaymentMethod.add(typeCCC);

        Insert lstWithPaymentMethod;

        Test.stopTest();
    }


    @IsTest
    static void testPaymentMethodCash(){
        AcctSeed__Cash_Disbursement__c cd = [
                SELECT
                        Id, AcctSeed__Amount__c, AcctSeed__Accounting_Period__c,
                        AcctSeed__Bank_Account__c,   AcctSeed__Cash_Disbursement_Batch__c,
                        AcctSeed__Ledger__c, AcctSeed__Vendor__c, AcctSeed__Status__c,
                        AcctSeed__Disbursement_Date__c, AcctSeed__Debit_GL_Account__c, GMBLASG__Posted__c,
                        AcctSeed__Type__c
                FROM
                        AcctSeed__Cash_Disbursement__c
                LIMIT 1
        ];
        Test.startTest();
        AcctSeed.CashDisbursementPostService.unpostCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{cd});
        List<AcctSeed__Cash_Disbursement__c> lstWithPaymentMethod = new List<AcctSeed__Cash_Disbursement__c>();

        AcctSeed__Cash_Disbursement__c typeCash = cd.clone();
        typeCash.AcctSeed__Type__c = 'Cash';
        lstWithPaymentMethod.add(typeCash);

        Insert lstWithPaymentMethod;

        Test.stopTest();
    }

    @IsTest
    static void testPaymentMethodWire(){
        AcctSeed__Cash_Disbursement__c cd = [
                SELECT
                        Id, AcctSeed__Amount__c, AcctSeed__Accounting_Period__c,
                        AcctSeed__Bank_Account__c,   AcctSeed__Cash_Disbursement_Batch__c,
                        AcctSeed__Ledger__c, AcctSeed__Vendor__c, AcctSeed__Status__c,
                        AcctSeed__Disbursement_Date__c, AcctSeed__Debit_GL_Account__c, GMBLASG__Posted__c,
                        AcctSeed__Type__c
                FROM
                        AcctSeed__Cash_Disbursement__c
                LIMIT 1
        ];
        Test.startTest();
        AcctSeed.CashDisbursementPostService.unpostCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{cd});
        List<AcctSeed__Cash_Disbursement__c> lstWithPaymentMethod = new List<AcctSeed__Cash_Disbursement__c>();


        AcctSeed__Cash_Disbursement__c typeWire = cd.clone();
        typeWire.AcctSeed__Type__c = 'Wire';
        lstWithPaymentMethod.add(typeWire);

        Insert lstWithPaymentMethod;

        Test.stopTest();
    }


//    @IsTest
//    static void testPaymentMethodLB(){
//        AcctSeed__Cash_Disbursement__c cd = [
//                SELECT
//                        Id, AcctSeed__Amount__c, AcctSeed__Accounting_Period__c,
//                        AcctSeed__Bank_Account__c,   AcctSeed__Cash_Disbursement_Batch__c,
//                        AcctSeed__Ledger__c, AcctSeed__Vendor__c, AcctSeed__Status__c,
//                        AcctSeed__Disbursement_Date__c, AcctSeed__Debit_GL_Account__c, GMBLASG__Posted__c,
//                        AcctSeed__Type__c
//                FROM
//                        AcctSeed__Cash_Disbursement__c
//                LIMIT 1
//        ];
//        Test.startTest();
//        AcctSeed.CashDisbursementPostService.unpostCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{cd});
//        List<AcctSeed__Cash_Disbursement__c> lstWithPaymentMethod = new List<AcctSeed__Cash_Disbursement__c>();
//
//
//        AcctSeed__Cash_Disbursement__c typeLB = cd.clone();
//        typeLB.AcctSeed__Type__c = 'Legend Bucks';
//        lstWithPaymentMethod.add(typeLB);
//
//        Insert lstWithPaymentMethod;
//
//        Test.stopTest();
//    }

    @IsTest
    static void testPaymentMethodOS(){
        AcctSeed__Cash_Disbursement__c cd = [
                SELECT
                        Id, AcctSeed__Amount__c, AcctSeed__Accounting_Period__c,
                        AcctSeed__Bank_Account__c,   AcctSeed__Cash_Disbursement_Batch__c,
                        AcctSeed__Ledger__c, AcctSeed__Vendor__c, AcctSeed__Status__c,
                        AcctSeed__Disbursement_Date__c, AcctSeed__Debit_GL_Account__c, GMBLASG__Posted__c,
                        AcctSeed__Type__c
                FROM
                        AcctSeed__Cash_Disbursement__c
                LIMIT 1
        ];
        Test.startTest();
        AcctSeed.CashDisbursementPostService.unpostCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{cd});
        List<AcctSeed__Cash_Disbursement__c> lstWithPaymentMethod = new List<AcctSeed__Cash_Disbursement__c>();

        AcctSeed__Cash_Disbursement__c typeOS = cd.clone();
        typeOS.AcctSeed__Type__c = 'Online Store';
        lstWithPaymentMethod.add(typeOS);

        Insert lstWithPaymentMethod;

        Test.stopTest();
    }

    @IsTest
    static void testPaymentMethodFinanced(){
        AcctSeed__Cash_Disbursement__c cd = [
                SELECT
                        Id, AcctSeed__Amount__c, AcctSeed__Accounting_Period__c,
                        AcctSeed__Bank_Account__c,   AcctSeed__Cash_Disbursement_Batch__c,
                        AcctSeed__Ledger__c, AcctSeed__Vendor__c, AcctSeed__Status__c,
                        AcctSeed__Disbursement_Date__c, AcctSeed__Debit_GL_Account__c, GMBLASG__Posted__c,
                        AcctSeed__Type__c
                FROM
                        AcctSeed__Cash_Disbursement__c
                LIMIT 1
        ];
        Test.startTest();
        AcctSeed.CashDisbursementPostService.unpostCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{cd});
        List<AcctSeed__Cash_Disbursement__c> lstWithPaymentMethod = new List<AcctSeed__Cash_Disbursement__c>();


        AcctSeed__Cash_Disbursement__c typeFinanced = cd.clone();
        typeFinanced.AcctSeed__Type__c = 'Financed';
        lstWithPaymentMethod.add(typeFinanced);

        Insert lstWithPaymentMethod;

        Test.stopTest();
    }
    @IsTest
    static void testPostDisbursement()
    {
        AcctSeed__Cash_Disbursement__c cashDisbursement = [
                SELECT
                    Id, AcctSeed__Amount__c, AcctSeed__Accounting_Period__c,
                        AcctSeed__Bank_Account__c,   AcctSeed__Cash_Disbursement_Batch__c,
                        AcctSeed__Ledger__c, AcctSeed__Vendor__c, AcctSeed__Status__c,
                        AcctSeed__Disbursement_Date__c, AcctSeed__Debit_GL_Account__c, GMBLASG__Posted__c
                FROM
                        AcctSeed__Cash_Disbursement__c
                LIMIT 1
        ];
        Test.startTest();
        AcctSeed__Cash_Disbursement__c cd = cashDisbursement.clone();
        cd.AcctSeed__Status__c = 'Approved';
        cd.AcctSeed__Disbursement_Date__c = Date.today();
        cd.AcctSeed__Debit_GL_Account__c = null;
        insert cd;
        AcctSeed.PostResult[] postResults = AcctSeed.CashDisbursementPostService.postCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{cd});
        String errorMsg = '';
        for (AcctSeed.PostResult theResult : postResults) {
            if (!theResult.isSuccess) {
                for (AcctSeed.PostResult.PostErrorResult errorResult: theResult.errors) {
                    errorMsg += errorResult.message;
                }
            }
        }
        System.assertEquals( cd.GMBLASG__Posted__c, false, errorMsg);
        Test.stopTest();
    }

    @IsTest
    static void testDisbursementInsert()
    {
        AcctSeed__Cash_Disbursement__c cashDisbursement = [
                SELECT
                        Id, AcctSeed__Amount__c, AcctSeed__Accounting_Period__c,
                        AcctSeed__Bank_Account__c,   AcctSeed__Cash_Disbursement_Batch__c,
                        AcctSeed__Ledger__c, AcctSeed__Vendor__c, AcctSeed__Status__c,
                        AcctSeed__Disbursement_Date__c, AcctSeed__Debit_GL_Account__c
                FROM
                        AcctSeed__Cash_Disbursement__c
                LIMIT 1
        ];
        Test.startTest();
        AcctSeed__Cash_Disbursement__c cd = cashDisbursement.clone();
        cd.AcctSeed__Status__c = 'Approved';
        cd.AcctSeed__Disbursement_Date__c = Date.today();
        cd.AcctSeed__Debit_GL_Account__c = gcConstants.idGlCustomerRefund;
        cd.AcctSeed__Payment_Status__c = 'Paid';
        insert cd;
        AcctSeed.PostResult[] postResults = AcctSeed.CashDisbursementPostService.postCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{cd});
        String errorMsg = '';
        for (AcctSeed.PostResult theResult : postResults) {
            if (!theResult.isSuccess) {
                for (AcctSeed.PostResult.PostErrorResult errorResult: theResult.errors) {
                    errorMsg += errorResult.message;
                }
            }
        }
        AcctSeed__Cash_Disbursement__c cdUpd = [SELECT  Id, GMBLASG__Posted__c, AcctSeed__Disbursement_Date__c FROM AcctSeed__Cash_Disbursement__c WHERE Id=:cd.Id][0];
        System.assertEquals( cdUpd.GMBLASG__Posted__c, true);
        Test.stopTest();
    }

    @IsTest
    static void testDisbursementUpdate()
    {
        AcctSeed__Cash_Disbursement__c cashDisbursement = [
                SELECT
                        Id, AcctSeed__Amount__c, AcctSeed__Accounting_Period__c,
                        AcctSeed__Bank_Account__c,   AcctSeed__Cash_Disbursement_Batch__c,
                        AcctSeed__Ledger__c, AcctSeed__Vendor__c, AcctSeed__Status__c,
                        AcctSeed__Disbursement_Date__c, AcctSeed__Debit_GL_Account__c
                FROM
                        AcctSeed__Cash_Disbursement__c
                LIMIT 1
        ];
        Test.startTest();
        AcctSeed__Cash_Disbursement__c cd = cashDisbursement.clone();
        cd.AcctSeed__Status__c = 'Approved';
        cd.AcctSeed__Disbursement_Date__c = Date.today();
        cd.AcctSeed__Debit_GL_Account__c = gcConstants.idGlCustomerRefund;
        cd.AcctSeed__Payment_Status__c = 'Paid';
        insert cd;
        AcctSeed.PostResult[] postResults = AcctSeed.CashDisbursementPostService.postCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{cd});
        String errorMsg = '';
        for (AcctSeed.PostResult theResult : postResults) {
            if (!theResult.isSuccess) {
                for (AcctSeed.PostResult.PostErrorResult errorResult: theResult.errors) {
                    errorMsg += errorResult.message;
                }
            }
        }
        cd.AcctSeed__Disbursement_Date__c = Date.today()-1;
        try {
            update cd;
        }catch( Exception ex ){
            System.assertEquals( ex.getMessage().contains('You cannot update the Posting Status, Payment Status'),true);
        }
        Test.stopTest();
    }
}