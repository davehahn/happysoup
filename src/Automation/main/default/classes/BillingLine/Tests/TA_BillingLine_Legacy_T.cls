@isTest
public class TA_BillingLine_Legacy_T {
    static List<AcctSeed__Billing_Line__c> billingLines;
    @TestSetup
    static void testData(){
        TA_BillingLine_Legacy_Test_Helper_T.testData();
    }
    @IsTest
    static void beforeInsertTest() {
        Test.startTest();
        new TA_BillingLine_Legacy().beforeInsert(TA_BillingLine_Legacy_Test_Helper_T.getBillingLines());
        Test.stopTest();
    }
    @IsTest
    static void afterInsertTest() {
        Test.startTest();
        new TA_BillingLine_Legacy().afterInsert(TA_BillingLine_Legacy_Test_Helper_T.getBillingLines());
        Test.stopTest();
    }
    @IsTest
    static void afterUpdateTest() {
        Test.startTest();
        billingLines = TA_BillingLine_Legacy_Test_Helper_T.getBillingLines();
        AcctSeed__Billing_Line__c billingLineClone =billingLines[0].clone(true, true, true, true);
        new TA_BillingLine_Legacy().afterUpdate(new List<AcctSeed__Billing_Line__c>{billingLines[0]},new List<AcctSeed__Billing_Line__c>{billingLineClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeDeleteTest() {
        Test.startTest();
        new TA_BillingLine_Legacy().beforeDelete(TA_BillingLine_Legacy_Test_Helper_T.getBillingLines());
        Test.stopTest();
    }
    @IsTest
    static void afterDeleteTest() {
        Test.startTest();
        new TA_BillingLine_Legacy().afterDelete(TA_BillingLine_Legacy_Test_Helper_T.getBillingLines());
        Test.stopTest();
    }


}