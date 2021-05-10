@isTest
private class gcTest_Billing{

	static testMethod void test1()
	{
        gcBilling.coverage();
        gcBilling_PDF.coverage();
        gcBillingLine.coverage();
        gcBilling_Clone.coverage();
    }/*

    static testMethod void test2()
    {
        update [SELECT Id FROM AcctSeed__Billing__c ORDER BY CreatedDate DESC LIMIT 1];
        update [SELECT Id FROM AcctSeed__Billing_Line__c ORDER BY CreatedDate DESC LIMIT 1];
    }*/
}