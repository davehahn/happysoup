@isTest
public class TA_AccountPayableLine_Legacy_T {

    final static String RECORDTYPE = 'Insurance';
    final static String FAMILY = 'Insurance';
    static List<AcctSeed__Account_Payable_Line__c> lstApLines;

    @TestSetup
    static void testData(){
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        Factory_AccountPayable.insertAccountPayable(5);
        new Factory_AccountingVariables();
        List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 10);
    }


    @IsTest
    static void beforeInsertTest() {
        Test.startTest();
        lstApLines = getData();
        new TA_AccountPayableLine_Legacy().beforeInsert(lstApLines);
        Test.stopTest();
    }
    @IsTest
    static void afterInsertTest() {
        Test.startTest();
        new TA_AccountPayableLine_Legacy().afterInsert(getData());
        Test.stopTest();
    }
    @IsTest
    static void afterUpdateTest() {
        Test.startTest();
        lstApLines = getData();
        AcctSeed__Account_Payable_Line__c accPayableClone =lstApLines[0].clone(true, true, true, true);
        new TA_AccountPayableLine_Legacy().afterUpdate(new List<AcctSeed__Account_Payable_Line__c>{lstApLines[0]},new List<AcctSeed__Account_Payable_Line__c>{accPayableClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeUpdateTest() {
        Test.startTest();
        lstApLines = getData();
        AcctSeed__Account_Payable_Line__c accPayableClone =lstApLines[0].clone(true, true, true, true);
        new TA_AccountPayableLine_Legacy().beforeUpdate(new List<AcctSeed__Account_Payable_Line__c>{lstApLines[0]},new List<AcctSeed__Account_Payable_Line__c>{accPayableClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeDeleteTest() {
        Test.startTest();
        new TA_AccountPayableLine_Legacy().beforeDelete(getData());
        Test.stopTest();
    }
    @IsTest
    static void afterDeleteTest() {
        Test.startTest();
        new TA_AccountPayableLine_Legacy().afterDelete(getData());
        Test.stopTest();
    }

    static private List<AcctSeed__Account_Payable_Line__c> getData(){
        return lstApLines =
        [
                SELECT
                        Id, APL_GL_Account__c, AcctSeed__Account_Payable__c,
                        AcctSeed__Product__c, AcctSeed__Quantity__c,
                        Taxable_Federal__c, Taxable_Provincial__c, Expense_Revenue_GL_Account__c,AcctSeed__Project__c,
                        AcctSeed__Expense_GL_Account__c,AcctSeed__Parent_Status__c,AcctSeed__GL_Account_Variable_1__c,
                        AcctSeed__GL_Account_Variable_2__c,AcctSeed__GL_Account_Variable_3__c
                FROM
                        AcctSeed__Account_Payable_Line__c
        ];

    }

}