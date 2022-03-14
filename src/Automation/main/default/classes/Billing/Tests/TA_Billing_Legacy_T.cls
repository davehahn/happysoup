@isTest
public class TA_Billing_Legacy_T {
    public static List<AcctSeed__Billing__c> billings;
    @TestSetup
    static void testData(){

        TA_Billing_Test_Helper_T.testData();
        billings = TA_Billing_Test_Helper_T.getBillings();
    }
    @IsTest
    static void beforeInsertTest() {
        Test.startTest();
        new TA_Billing_Legacy().beforeInsert(TA_Billing_Test_Helper_T.getBillings());
        Test.stopTest();
    }
    @IsTest
    static void afterInsertTest() {
        Test.startTest();
        new TA_Billing_Legacy().afterInsert(TA_Billing_Test_Helper_T.getBillings());
        Test.stopTest();
    }
    @IsTest
    static void afterUpdateTest() {
        Test.startTest();
        billings = TA_Billing_Test_Helper_T.getBillings();
        AcctSeed__Billing__c billingClone =billings[0].clone(true, true, true, true);
        new TA_Billing_Legacy().afterUpdate(new List<AcctSeed__Billing__c>{billings[0]},new List<AcctSeed__Billing__c>{billingClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeDeleteTest() {
        Test.startTest();
        new TA_Billing_Legacy().beforeDelete(TA_Billing_Test_Helper_T.getBillings());
        Test.stopTest();
    }
    @IsTest
    static void afterDeleteTest() {
        Test.startTest();
        new TA_Billing_Legacy().afterDelete(TA_Billing_Test_Helper_T.getBillings());
        Test.stopTest();
    }


}