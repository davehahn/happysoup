@isTest
public class TA_CashDisbursement_Legacy_T {

    final static String RECORDTYPE = 'Insurance';
    final static String FAMILY = 'Insurance';
    final static String SERIALNUMBER = '123450';
    static List<AcctSeed__Cash_Disbursement__c> cdList;
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

    private static List<AcctSeed__Cash_Disbursement__c>  getData(){
        return [
                SELECT
                        Id, AcctSeed__Amount__c, AcctSeed__Accounting_Period__c,
                        AcctSeed__Bank_Account__c,   AcctSeed__Cash_Disbursement_Batch__c,
                        AcctSeed__Ledger__c, AcctSeed__Vendor__c, AcctSeed__Status__c,
                        AcctSeed__Disbursement_Date__c, AcctSeed__Debit_GL_Account__c, GMBLASG__Posted__c,
                        AcctSeed__Type__c,AcctSeed__Reference__c,AcctSeed__GL_Account_Variable_1__c
                FROM
                        AcctSeed__Cash_Disbursement__c
        ];
    }

    @IsTest
    static void beforeInsertTest() {
        Test.startTest();
        cdList = getData();
        new TA_CashDisbursement_Legacy().beforeInsert(cdList);
        Test.stopTest();
    }
    @IsTest
    static void afterInsertTest() {
        Test.startTest();
        new TA_CashDisbursement_Legacy().afterInsert(getData());
        Test.stopTest();
    }
    @IsTest
    static void afterUpdateTest() {
        Test.startTest();
        cdList = getData();
        AcctSeed__Cash_Disbursement__c cdClone =cdList[0].clone(true, true, true, true);
        new TA_CashDisbursement_Legacy().afterUpdate(new List<AcctSeed__Cash_Disbursement__c>{cdList[0]},new List<AcctSeed__Cash_Disbursement__c>{cdClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeUpdateTest() {
        Test.startTest();
        cdList = getData();
        AcctSeed__Cash_Disbursement__c cdClone =cdList[0].clone(true, true, true, true);
        new TA_CashDisbursement_Legacy().beforeUpdate(new List<AcctSeed__Cash_Disbursement__c>{cdList[0]},new List<AcctSeed__Cash_Disbursement__c>{cdClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeDeleteTest() {
        Test.startTest();
        new TA_CashDisbursement_Legacy().beforeDelete(getData());
        Test.stopTest();
    }
    @IsTest
    static void afterDeleteTest() {
        Test.startTest();
        new TA_CashDisbursement_Legacy().afterDelete(getData());
        Test.stopTest();
    }

}