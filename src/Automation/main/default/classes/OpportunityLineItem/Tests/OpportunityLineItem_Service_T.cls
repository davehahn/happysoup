@isTest
public class OpportunityLineItem_Service_T {
    @testSetup 
    static void dataSetup()
    {
        TA_OpportunityLine_TestHelper.dataSetup();
    }
    @isTest
     static void oppLineItem_SetFlag_Test(){
    	TA_OpportunityLine_TestHelper.init();
        new TA_OppLineItem_SetFlag_BI().beforeInsert(TA_OpportunityLine_TestHelper.olis);
        System.assert(TA_OpportunityLine_TestHelper.olis[0].Taxable_Federal__c, false); 
        System.assert(TA_OpportunityLine_TestHelper.olis[0].Taxable_Provincial__c, false); 
       
    }
    @isTest
     static void updateOpp_Test(){
    	TA_OpportunityLine_TestHelper.init();
        new TA_OppLineItem_UpdateOpp_AD().afterDelete(TA_OpportunityLine_TestHelper.olis);
    }
    @isTest
     static void putInsuranceRate_Test(){
    	TA_OpportunityLine_TestHelper.init();
        List<OpportunityLineItem> oldLineItem = TA_OpportunityLine_TestHelper.getOldList();
        new TA_OppLineItem_PutInsuranceRateValue_BU().beforeUpdate(TA_OpportunityLine_TestHelper.olis,oldLineItem);
    }
     @isTest
     static void putInsuranceRate1_Test(){
    	TA_OpportunityLine_TestHelper.init();
        new TA_OppLineItem_PutInsuranceRateValue_BI().beforeInsert(TA_OpportunityLine_TestHelper.olis);
    }
    @isTest
    static void oppLineItem_SetBoatId_Test(){
    	TA_OpportunityLine_TestHelper.init('boat');
        new TA_OppLineItem_SetBoatId_AI().afterInsert(TA_OpportunityLine_TestHelper.olis);
    }
}