@isTest
public class TA_OppLineItem_PutInsuranceRateVal_BI_T {
	@testSetup 
    static void dataSetup()
    {
        TA_OpportunityLine_TestHelper.dataSetup();
    }
    @isTest
     static void putInsuranceRate_Test(){
    	TA_OpportunityLine_TestHelper.init();
        new TA_OppLineItem_PutInsuranceRateValue_BI().beforeInsert(TA_OpportunityLine_TestHelper.olis);
    }
}