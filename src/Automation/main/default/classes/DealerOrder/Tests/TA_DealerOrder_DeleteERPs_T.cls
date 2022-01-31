
@IsTest(SeeAllData=false)
public with sharing class TA_DealerOrder_DeleteERPs_T {

    @testSetup
    static void dataSetup(){
        TA_DealerOrder_TestHelper.dataSetup();
    }
    @IsTest
    static void BeforeDelete_Test() {
        TA_DealerOrder_TestHelper.init();
        Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Pending Review');
        insert order;
        Test.startTest();
        try
        {
            //delete order;
            new TA_DealerOrder_DeleteERPs().beforeDelete(new List<Dealer_Order__c>{order});
        }
        catch (Exception e)
        {
            System.assert(
                    e.getMessage()
                            .contains('You can not delete a Dealer Order with stage "Pending Review"')
            );
        }
        Test.stopTest();


    }

    @IsTest
    static void BeforeDeleteDraftStage_Test() {
        TA_DealerOrder_TestHelper.init();
        TA_DealerOrder_TestHelper.buildBoat('Pontoon', 50000, null);


        Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
        insert order;
        TA_DealerOrder_TestHelper.createDealerOrderLines(order, 3);
        Test.startTest();
        new TA_DealerOrder_DeleteERPs().beforeDelete(new List<Dealer_Order__c>{order});
        delete order;
        Test.stopTest();
        List<AcctSeed__Project__c> erps = [SELECT Id, OwnerId FROM AcctSeed__Project__c WHERE Id = :TA_DealerOrder_TestHelper.erps[0].Id];
        System.assert(erps.isEmpty());

    }

}