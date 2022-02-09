
@IsTest(SeeAllData=false)
public with sharing class TA_DealerOrder_SetERPStage_T {

    @testSetup
    static void dataSetup(){
        TA_DealerOrder_TestHelper.dataSetup();
    }

    @IsTest
    static void afterUpdate_PendingFinancing_Test() {
        TA_DealerOrder_TestHelper.init();
        TA_DealerOrder_TestHelper.buildBoat('Pontoon', 50000, null);


        Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
        insert order;
        TA_DealerOrder_TestHelper.createDealerOrderLines(order, 1);
        Dealer_Order__c orderOld = new   Dealer_Order__c();
        orderOld = TA_DealerOrder_TestHelper.getOldList()[0];
        List<Dealer_Order__c> oldlist = new List<Dealer_Order__c>{orderOld};
        Test.startTest();
        order.Stage__c = 'Pending Financing';
        update order;
        new TA_DealerOrder_SetERPStage().afterUpdate(new List<Dealer_Order__c> {order},oldlist);
        Test.stopTest();
        AcctSeed__Project__c erp = [SELECT Id, Stage__c FROM AcctSeed__Project__c WHERE Id = :TA_DealerOrder_TestHelper.erps[0].Id];
        System.assertEquals('Pending Financing', erp.Stage__c);

    }

    @IsTest
    static void afterUpdate_Approved_Test() {
        TA_DealerOrder_TestHelper.init();
        TA_DealerOrder_TestHelper.buildBoat('Pontoon', 50000, null);


        Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
        insert order;
        TA_DealerOrder_TestHelper.createDealerOrderLines(order, 1);
        Dealer_Order__c orderOld = new   Dealer_Order__c();
        orderOld = TA_DealerOrder_TestHelper.getOldList()[0];
        List<Dealer_Order__c> oldlist = new List<Dealer_Order__c>{orderOld};
        Test.startTest();
        order.Stage__c = 'Approved';
        update order;
        new TA_DealerOrder_SetERPStage().afterUpdate(new List<Dealer_Order__c> {order},oldlist);
        Test.stopTest();
        AcctSeed__Project__c erp = [SELECT Id, Stage__c FROM AcctSeed__Project__c WHERE Id = :TA_DealerOrder_TestHelper.erps[0].Id];
        System.assertEquals('Tagging Pending', erp.Stage__c);

    }

    @IsTest
    static void afterUpdate_PendingReview_Test() {
        TA_DealerOrder_TestHelper.init();
        TA_DealerOrder_TestHelper.buildBoat('Pontoon', 50000, null);


        Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
        insert order;
        TA_DealerOrder_TestHelper.createDealerOrderLines(order, 1);
        Dealer_Order__c orderOld = new   Dealer_Order__c();
        orderOld = TA_DealerOrder_TestHelper.getOldList()[0];
        List<Dealer_Order__c> oldlist = new List<Dealer_Order__c>{orderOld};
        Test.startTest();
        order.Stage__c = 'Pending Review';
        update order;
        new TA_DealerOrder_SetERPStage().afterUpdate(new List<Dealer_Order__c> {order},oldlist);
        Test.stopTest();
        AcctSeed__Project__c erp = [SELECT Id, Stage__c FROM AcctSeed__Project__c WHERE Id = :TA_DealerOrder_TestHelper.erps[0].Id];
        System.assertEquals('Pending Review', erp.Stage__c);

    }

    @IsTest
    static void afterUpdate_MotorRequest_SendEmail_Test()
    {
        TA_DealerOrder_TestHelper.init();
        TA_DealerOrder_TestHelper.buildMotor( 2000 );
        Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
        insert order;
        Dealer_Order__c orderOld = new   Dealer_Order__c();
        orderOld = TA_DealerOrder_TestHelper.getOldList()[0];
        List<Dealer_Order__c> oldlist = new List<Dealer_Order__c>{orderOld};
        Dealer_Motor_Request__c dmr = new Dealer_Motor_Request__c(
                Motor__c = TA_DealerOrder_TestHelper.motor.Id,
                Notes__c = 'Test DMR',
                Quantity__c = 1
        );
        insert dmr;
        Factory_DealerOrder.createDealerOrderLines(new List<Dealer_Motor_Request__c>{ dmr }, order, TA_DealerOrder_TestHelper.motor );
        Test.startTest();
        order.Stage__c = 'Pending Financing';
        update order;
        new TA_DealerOrder_SetERPStage().afterUpdate(new List<Dealer_Order__c> {order},oldlist);

        Test.stopTest();

        order = [ SELECT Id, Merc_Order_Sent__c FROM Dealer_Order__c WHERE Id = :order.Id ];
        System.assert( order.Merc_Order_Sent__c );

    }
}