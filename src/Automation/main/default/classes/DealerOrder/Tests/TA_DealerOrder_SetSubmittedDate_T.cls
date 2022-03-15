
@IsTest(SeeAllData=false)
public with sharing class TA_DealerOrder_SetSubmittedDate_T {
    @testSetup
    static void dataSetup(){
        TA_DealerOrder_TestHelper.dataSetup();
    }
    @IsTest
    static void beforeInsert_Test()
    {
        TA_DealerOrder_TestHelper.init();
        Dealer_Order__c order = TA_DealerOrder_TestHelper.buildDealerOrder(true, 'Pending Review');
        DateTime tNow = DateTime.now();
        Test.startTest();
        new TA_DealerOrder_SetSubmittedDate().beforeInsert(new List<Dealer_Order__c>{order});
        insert order;
        Test.stopTest();

        order = [SELECT Id, Date_Submitted__c FROM Dealer_Order__c WHERE Id = :order.Id];
        System.assertEquals(tNow.year(), order.Date_Submitted__c.year());
        System.assertEquals(tNow.month(), order.Date_Submitted__c.month());
        System.assertEquals(tNow.day(), order.Date_Submitted__c.day());

    }

}