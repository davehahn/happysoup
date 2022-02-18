@isTest
public class TA_OppLineItem_SetBoatId_AI_T {
	@testSetup 
    static void dataSetup()
    {
        TA_OpportunityLine_TestHelper.dataSetup();
    }
    @isTest
     static void oppLineItem_SetFlag_Test(){
    	TA_OpportunityLine_TestHelper.init('boat');
        new TA_OppLineItem_SetBoatId_AI().afterInsert(TA_OpportunityLine_TestHelper.olis);
        TA_OpportunityLine_TestHelper.olis = [SELECT Id, Opportunity.BoatId__c, PricebookEntry.Product2Id FROM OpportunityLineItem];
        System.assert(TA_OpportunityLine_TestHelper.olis[0].Opportunity.BoatId__c !=null);
    }
}