/**
 * Created by dave on 2020-08-12.
 */

@IsTest
private class PartnerBookingOrder_TriggerHandler_T
{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void beforeInsert_Test()
  {
    Account partner = Factory_Account.buildDealerAccounts(1)[0];
    insert partner;
    String programYear = String.valueOf( Date.today().year() );
    Dealer_Order__c bookingOrder = Factory_DealerOrder.createDealerOrder(partner);
    bookingOrder.Is_Booking_Order__c = true;
    bookingOrder.Program_Year__c = programYear;
    update bookingOrder;
    Partner_Booking_Order__c booking = new Partner_Booking_Order__c(
      Account__c = partner.Id,
      Dealer_Order__c = bookingOrder.Id,
      V_Hull_Discount_Percent__c = 8,
      Name = bookingOrder.Program_Year__c
    );

    Test.startTest();
    insert booking;
    Test.stopTest();

    booking = [SELECT Id, Uniquifier__c FROM Partner_Booking_Order__c WHERE Id =:booking.Id ];
    System.assertEquals( programYear + '-' + partner.Id, booking.Uniquifier__c );
  }
}