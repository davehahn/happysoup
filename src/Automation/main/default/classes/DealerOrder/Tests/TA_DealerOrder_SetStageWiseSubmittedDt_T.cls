@IsTest(SeeAllData=false)
public class TA_DealerOrder_SetStageWiseSubmittedDt_T {

    @testSetup
    static void dataSetup(){
        TA_DealerOrder_TestHelper.dataSetup();
    }

    @IsTest
    static void beforeUpdate_Test()
    {
        TA_DealerOrder_TestHelper.init();

        Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
        insert order;
        Dealer_Order__c orderOld = new   Dealer_Order__c();
        orderOld = TA_DealerOrder_TestHelper.getOldList()[0];
        List<Dealer_Order__c> oldlist = new List<Dealer_Order__c>{orderOld};


        //order = [SELECT Id, Date_Submitted__c FROM Dealer_Order__c WHERE Id = :order.Id];
       // System.assert(order.Date_Submitted__c == null);
        Test.startTest();
        order.Stage__c = 'Pending Review';
        new TA_DealerOrder_SetStageWiseSubmittedDate().beforeUpdate(new List<Dealer_Order__c> {order},oldlist);
        update order;
        order = [SELECT Id, Date_Submitted__c FROM Dealer_Order__c WHERE Id = :order.Id];
        System.assert(order.Date_Submitted__c != null);
        order.Stage__c = 'Draft';
        new TA_DealerOrder_SetStageWiseSubmittedDate().beforeUpdate(new List<Dealer_Order__c> {order},oldlist);
        update order;
        order = [SELECT Id, Date_Submitted__c FROM Dealer_Order__c WHERE Id = :order.Id];
        System.assert(order.Date_Submitted__c == null);
        Test.stopTest();

    }

}