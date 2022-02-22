@isTest
public class TA_OppLineItem_UpdateOpp_AD_T {
	@testSetup 
    static void dataSetup()
    {
        TA_OpportunityLine_TestHelper.dataSetup();
    }
    @isTest
     static void updateOpp_Test(){
    	TA_OpportunityLine_TestHelper.init();
        new TA_OppLineItem_UpdateOpp_AD().afterDelete(TA_OpportunityLine_TestHelper.olis);
    }
}