@IsTest
public with sharing class TA_DealerOrderLine_DelTransferRequests_T {
  @testSetup
  static void dataSetup() {
    TA_DealerOrderLine_TestHelper.dataSetup();
  }
  @isTest
  static void deleteLegendTransferRequests_Test() {
    Set<Id> transferIds = new Set<Id>();
    TA_DealerOrderLine_TestHelper.init();
    TA_DealerOrderLine_TestHelper.buildBoat('Pontoon', 50000, null);
    TA_DealerOrderLine_TestHelper.buildDealerOrder(true, 'Draft');
    TA_DealerOrderLine_TestHelper.order = [
      SELECT id, Account__c, Payment_Method__c, Program_Year__c, Is_Booking_Order__c, Stage__c
      FROM Dealer_Order__c
      WHERE id = :TA_DealerOrderLine_TestHelper.order.id
    ];
    TA_DealerOrderLine_TestHelper.createDealerOrderLines(TA_DealerOrderLine_TestHelper.order, 2);

    new TA_DealerOrderLine_DelTransferRequests().afterDelete(TA_DealerOrderLine_TestHelper.dealerOrderLines);
    TA_DealerOrderLine_TestHelper.dealerOrderLines = [
      SELECT id
      FROM Dealer_Order_Line__c
      WHERE Legend_Transfer_Request__c != NULL
    ];
    System.assert(TA_DealerOrderLine_TestHelper.dealerOrderLines.isEmpty());
  }
}
