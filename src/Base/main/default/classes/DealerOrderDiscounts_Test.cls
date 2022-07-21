@isTest
private class DealerOrderDiscounts_Test {
  //  @testSetup static void dataSetup()
  //  {
  //    //new Factory_TestData();
  //    Factory_CustomSettings.setupInventorySettings();
  //  }
  //
  //  static Account acct;
  //  static {
  //    acct = AccountFactory.buildDealerAccount('Test Dealer');
  //    acct.BillingStreet = '666 Test Drive';
  //    acct.BillingState = 'Ontario';
  //    acct.BillingCity = 'Lovely Place';
  //    acct.BillingCountry = 'Canada';
  //    acct.BillingPostalCode = 'A1B2C3';
  //    insert acct;
  //  }
  //
  //  @isTest
  //  static void constructor_reOrder_test() {
  //    Test.startTest();
  //    Dealer_Order__c dOrder = new Dealer_Order__c(
  //      Account__c = acct.Id,
  //      Is_Booking_Order__c = false,
  //      Model_Year__c = String.valueOf( Date.today().year() )
  //    );
  //    insert dOrder;
  //    DealerOrderDiscounts dod = new DealerOrderDiscounts( dOrder.Id );
  //    Test.stopTest();
  //    System.assertEquals( 1, dod.availableDiscounts.size() );
  //  }
  //
  //  @isTest
  //  static void constructor_bookingOrder_test() {
  //    Test.startTest();
  //    insert new Dealer_Program_Settings__c(Name = '2018', Early_Order_Discount_Date__c = Date.today().addDays(3), Early_Order_Discount_Rate__c = 2.0 );
  //    Dealer_Order__c dOrder = new Dealer_Order__c(
  //      Account__c = acct.Id,
  //      Is_Booking_Order__c = true,
  //      Model_Year__c = String.valueOf( Date.today().year() )
  //    );
  //    insert dOrder;
  //    DealerOrderDiscounts dod = new DealerOrderDiscounts( dOrder.Id );
  //    Test.stopTest();
  //    System.assertEquals( 2, dod.availableDiscounts.size() );
  //  }
}
