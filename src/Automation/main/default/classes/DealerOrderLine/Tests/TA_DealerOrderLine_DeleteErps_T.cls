@isTest
public with sharing class TA_DealerOrderLine_DeleteErps_T {
    @testSetup static void dataSetup(){
        TA_DealerOrderLine_TestHelper.dataSetup();

    }
    @isTest
    static void deleteERPs_Test(){

        TA_DealerOrderLine_TestHelper.init();
        TA_DealerOrderLine_TestHelper.buildBoat('Pontoon', 50000, null);
        TA_DealerOrderLine_TestHelper.buildDealerOrder(true, 'Draft');
        TA_DealerOrderLine_TestHelper.order = [Select id,Account__c,Payment_Method__c,Program_Year__c,Is_Booking_Order__c,Stage__c from Dealer_Order__c where id= :TA_DealerOrderLine_TestHelper.order.id ];
        TA_DealerOrderLine_TestHelper.createDealerOrderLines(TA_DealerOrderLine_TestHelper.order,2);
        new TA_DealerOrderLine_DeleteErps().afterDelete(TA_DealerOrderLine_TestHelper.dealerOrderLines);
        List<AcctSeed__Project__c> erpIds = [SELECT Id FROM AcctSeed__Project__c WHERE Id IN :TA_DealerOrderLine_TestHelper.erpIds];
        System.assertEquals(0, erpIds.size());

    }

}