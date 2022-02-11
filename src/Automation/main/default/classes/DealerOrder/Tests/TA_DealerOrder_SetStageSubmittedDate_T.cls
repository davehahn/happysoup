@IsTest(SeeAllData=false)
public class TA_DealerOrder_SetStageSubmittedDate_T {
    static Dealer_Order__c order;
    static String partnerAccountName = 'TestPartner';
    static Account partner;
    
    @testSetup static void dataSetup(){
        TA_DealerOrder_TestHelper.dataSetup();
    }
    @IsTest
    static void beforeUpdate_Test() {
        TA_DealerOrder_TestHelper.init();
        Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
        insert order;
        
        System.assert(TA_DealerOrder_TestHelper.getDealerOrder()[0].Date_Submitted__c == null);
        Test.startTest();
        List<Dealer_Order__c> oldList = TA_DealerOrder_TestHelper.getOldList();
        oldList[0].Stage__c = 'Pending Review'; 
        new TA_DealerOrder_SetStageWiseSubmittedDate().beforeUpdate(TA_DealerOrder_TestHelper.getNewList(),oldList);
        System.debug('@@= '+TA_DealerOrder_TestHelper.getDealerOrder()[0].Date_Submitted__c);
        System.assert(TA_DealerOrder_TestHelper.getDealerOrder()[0].Date_Submitted__c == null);
        Test.stopTest();
        
        
    }
}