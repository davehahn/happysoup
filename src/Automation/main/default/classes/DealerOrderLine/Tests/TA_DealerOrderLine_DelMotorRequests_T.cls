@isTest
public with sharing class TA_DealerOrderLine_DelMotorRequests_T {
  @testSetup
  static void dataSetup() {
    TA_DealerOrderLine_TestHelper.dataSetup();
  }
  @isTest
  static void deleteDealerMotorRequests_Test() {
    Set<Id> motorRequestIds = new Set<Id>();
    TA_DealerOrderLine_TestHelper.init();
    TA_DealerOrderLine_TestHelper.buildBoat('Pontoon', 50000, null);
    TA_DealerOrderLine_TestHelper.buildDealerOrder(true, 'Draft');
    TA_DealerOrderLine_TestHelper.order = [
      SELECT id, Account__c, Payment_Method__c, Program_Year__c, Is_Booking_Order__c, Stage__c
      FROM Dealer_Order__c
      WHERE id = :TA_DealerOrderLine_TestHelper.order.id
    ];
    TA_DealerOrderLine_TestHelper.createDealerOrderLines(TA_DealerOrderLine_TestHelper.order, 2);
    SYstem.debug('TA_DealerOrderLine_TestHelper.dealerOrderLines= ' + TA_DealerOrderLine_TestHelper.dealerOrderLines);
    TA_DealerOrderLine_TestHelper.dealerOrderLines = [
      SELECT id, ERP_Order__c, Product__c, Dealer_Order__c, Model_Year__c, Order_Group_Id__c, Dealer_Motor_Request__c
      FROM Dealer_Order_Line__c
    ];
    new TA_DealerOrderLine_DelMotorRequests().afterDelete(TA_DealerOrderLine_TestHelper.dealerOrderLines);
    List<Dealer_Order_Line__c> dealerOrderLineList = [
      SELECT id
      FROM Dealer_Order_Line__c
      WHERE Dealer_Motor_Request__c != NULL
    ];
    System.assert(dealerOrderLineList.isEmpty());
  }
}
