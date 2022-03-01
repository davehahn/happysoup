@isTest
public class TA_DealerOrderLine_HandlePartnerPro_T {
    @testSetup static void dataSetup(){
        TA_DealerOrderLine_TestHelper.dataSetup();
    }
    @isTest
    static void handlePartnerProgram_afterInsert_Test(){

        TA_DealerOrderLine_TestHelper.init();
        TA_DealerOrderLine_TestHelper.buildBoat('Pontoon', 50000, null);
        TA_DealerOrderLine_TestHelper.buildDealerOrder(true, 'Draft');
        TA_DealerOrderLine_TestHelper.order = [Select id,Account__c,Payment_Method__c,Program_Year__c,Is_Booking_Order__c,Stage__c from Dealer_Order__c where id= :TA_DealerOrderLine_TestHelper.order.id ];
        TA_DealerOrderLine_TestHelper.createDealerOrderLines(TA_DealerOrderLine_TestHelper.order,2);
        new TA_DealerOrderLine_HandlePartnerPro().afterInsert(TA_DealerOrderLine_TestHelper.dealerOrderLines);
    }

    @isTest
    static void handlePartnerProgram_afterDelete_Test(){

        TA_DealerOrderLine_TestHelper.init();
        TA_DealerOrderLine_TestHelper.buildBoat('Pontoon', 50000, null);
        TA_DealerOrderLine_TestHelper.buildDealerOrder(true, 'Draft');
        TA_DealerOrderLine_TestHelper.order = [Select id,Account__c,Payment_Method__c,Program_Year__c,Is_Booking_Order__c,Stage__c from Dealer_Order__c where id= :TA_DealerOrderLine_TestHelper.order.id ];
        TA_DealerOrderLine_TestHelper.createDealerOrderLines(TA_DealerOrderLine_TestHelper.order,2);
        new TA_DealerOrderLine_HandlePartnerPro().afterDelete(TA_DealerOrderLine_TestHelper.dealerOrderLines);
    }
    @isTest
    static void handlePartnerProgram_afterUpdate_Test(){

        TA_DealerOrderLine_TestHelper.init();
        TA_DealerOrderLine_TestHelper.buildBoat('Pontoon', 50000, null);
        TA_DealerOrderLine_TestHelper.buildDealerOrder(true, 'Draft');
        TA_DealerOrderLine_TestHelper.order = [Select id,Account__c,Payment_Method__c,Program_Year__c,Is_Booking_Order__c,Stage__c from Dealer_Order__c where id= :TA_DealerOrderLine_TestHelper.order.id ];
        TA_DealerOrderLine_TestHelper.createDealerOrderLines(TA_DealerOrderLine_TestHelper.order,2);
        new TA_DealerOrderLine_HandlePartnerPro().afterUpdate(TA_DealerOrderLine_TestHelper.dealerOrderLines,TA_DealerOrderLine_TestHelper.dealerOrderLines);
    }
}