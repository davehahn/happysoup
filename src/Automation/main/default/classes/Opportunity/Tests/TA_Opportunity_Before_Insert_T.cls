/**
 * Created by dhavalmacbook on 31/01/22.
 */
@IsTest
public with sharing class TA_Opportunity_Before_Insert_T {

    @testSetup static void dataSetup()
    {
        TA_Opportunity_TestHelper.dataSetup();
    }

    @isTest
    static void insertOpp_Test(){
		TA_Opportunity_TestHelper.init();
        Test.startTest();
	    Account personAccount = AccountFactory.insertPersonAccount();
        Opportunity opp2;
        Decimal defaultFedTaxRate = Legend_Settings__c.getOrgDefaults().FederalTaxRate__c;
		System.runAs(TA_Opportunity_TestHelper.whitefishUser)
        {
            TA_Opportunity_TestHelper.opp = OpportunityFactory.buildBasicRetail( personAccount.id );
            TA_Opportunity_TestHelper.opp.ownerId = TA_Opportunity_TestHelper.whitefishUser.id;
            insert TA_Opportunity_TestHelper.opp;
            new TA_Opportunity_Before_Insert().beforeInsert(new List<Opportunity>{TA_Opportunity_TestHelper.opp});
          	System.assertEquals( TA_Opportunity_TestHelper.whitefishWarehouse.Id, TA_Opportunity_TestHelper.opp.Warehouse__c );
        	System.assertEquals( defaultFedTaxRate, TA_Opportunity_TestHelper.opp.Tax_Rate_Federal__c);
        }
        Test.stopTest();
    }
}