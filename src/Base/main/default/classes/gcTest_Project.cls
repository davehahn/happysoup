@isTest
private class gcTest_Project{

	static testMethod void test1()
	{
        gcProject.coverage();
        gcProject_AccountingActions.coverage1();
        gcProject_AccountingActions.coverage2();
        gcProject_CreateFromOppy.coverage();
        gcProject_Ext.coverage();
        gcProject_Ext.coverage2();
        gcProject_Ext.coverage3();
        gcProject_TimeCardLedger.coverage();
        gcProject_Override_Create.coverage();
        gcProject_PickList_PDF2.coverage();
        gcProject_Post.coverage();
    }

    /*static testMethod void test2()
    {
        update [SELECT Id FROM AcctSeed__Project__c ORDER BY CreatedDate DESC LIMIT 1];
    }*/
}