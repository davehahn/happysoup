@isTest
public class TA_OppLineItem_PutInsuranceRateVal_BU_T {
	@testSetup 
    static void dataSetup()
    {
        TA_OpportunityLine_TestHelper.dataSetup();
    }
    @isTest
     static void putInsuranceRate_Test(){
    	TA_OpportunityLine_TestHelper.init();
        List<OpportunityLineItem> oldLineItem = TA_OpportunityLine_TestHelper.getOldList();
        new TA_OppLineItem_PutInsuranceRateValue_BU().beforeUpdate(TA_OpportunityLine_TestHelper.olis,oldLineItem);
    }
}