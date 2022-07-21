@isTest
public with sharing class TA_DealerOrderLine_SetLineTotal_T {
  @testSetup
  static void dataSetup() {
    TA_DealerOrderLine_TestHelper.dataSetup();
  }

  @isTest
  static void setLineTotal_beforeInsert_Test() {
    TA_DealerOrderLine_TestHelper.init();
    TA_DealerOrderLine_TestHelper.buildBoat('Pontoon', 50000, null);
    TA_DealerOrderLine_TestHelper.buildDealerOrder(true, 'Draft');
    TA_DealerOrderLine_TestHelper.order = [
      SELECT id, Account__c, Payment_Method__c, Program_Year__c, Is_Booking_Order__c, Stage__c
      FROM Dealer_Order__c
      WHERE id = :TA_DealerOrderLine_TestHelper.order.id
    ];
    TA_DealerOrderLine_TestHelper.createDealerOrderLines(TA_DealerOrderLine_TestHelper.order, 2);
    new TA_DealerOrderLine_SetLineTotal().beforeInsert(TA_DealerOrderLine_TestHelper.dealerOrderLines);
    // DealerOrderLine_Service.setLineTotal(TA_DealerOrderLine_TestHelper.dealerOrderLines);
    System.assertEquals(
      TA_DealerOrderLine_TestHelper.dealerOrderLines[0].Line_Total_No_Fees_or_Discounts__c,
      TA_DealerOrderLine_TestHelper.dealerOrderLines[0].Line_Total_NoFeesOrDiscountsCalc__c
    );
  }
  @isTest
  static void setLineTotal_beforeInsertUpdate_Test() {
    TA_DealerOrderLine_TestHelper.init();
    TA_DealerOrderLine_TestHelper.buildBoat('Pontoon', 50000, null);
    TA_DealerOrderLine_TestHelper.buildDealerOrder(true, 'Draft');
    TA_DealerOrderLine_TestHelper.order = [
      SELECT id, Account__c, Payment_Method__c, Program_Year__c, Is_Booking_Order__c, Stage__c
      FROM Dealer_Order__c
      WHERE id = :TA_DealerOrderLine_TestHelper.order.id
    ];
    TA_DealerOrderLine_TestHelper.createDealerOrderLines(TA_DealerOrderLine_TestHelper.order, 2);
    new TA_DealerOrderLine_SetLineTotal()
      .beforeUpdate(TA_DealerOrderLine_TestHelper.dealerOrderLines, TA_DealerOrderLine_TestHelper.dealerOrderLines);
    // DealerOrderLine_Service.setLineTotal(TA_DealerOrderLine_TestHelper.dealerOrderLines);
    System.assertEquals(
      TA_DealerOrderLine_TestHelper.dealerOrderLines[0].Line_Total_No_Fees_or_Discounts__c,
      TA_DealerOrderLine_TestHelper.dealerOrderLines[0].Line_Total_NoFeesOrDiscountsCalc__c
    );
  }
}
