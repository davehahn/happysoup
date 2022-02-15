
@IsTest(SeeAllData=false)
public with sharing class TA_DealerOrder_CreatePartnerOrder_T {
    static Dealer_Order__c order;
    static String partnerAccountName = 'TestPartner';
    static Account partner;
    
    @testSetup static void dataSetup(){
         TA_DealerOrder_TestHelper.dataSetup();
    }
    @IsTest
    static void afterInsert_Test() {
		    TA_DealerOrder_TestHelper.init();
        Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
        insert order;
        Test.startTest();
        new TA_DealerOrder_CreatePartnerOrder().afterInsert(new List<Dealer_Order__c>{order});
        System.assert(TA_DealerOrder_TestHelper.getPartnerBookingOrder().size()>0);
        Test.stopTest();
        
        
    }



}