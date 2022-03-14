/**
 * Created by dave on 2021-05-07.
 */

@IsTest
private class PartnerBookingOrder_Selector_T
{
  static final String programYear = '2021';
  static final String partnerAccountName = 'TestPartner';

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account partner = Factory_Account.buildDealerAccounts(1)[0];
    partner.Name = partnerAccountName;
    insert partner;
    Dealer_Order__c order = new Dealer_Order__c(
      Is_Booking_Order__c = true,
      Program_Year__c = programYear,
      Payment_Method__c = 'Cash',
      Account__c = partner.Id,
      Pricebook__c = gcConstants.idPricebookPartner
    );
    TriggerBase.bypass('Dealer_Order__c');
    insert order;
    TriggerBase.clearBypass( 'Dealer_Order__c');
    Partner_Booking_Order__c pbo = new Partner_Booking_Order__c(
      Account__c = partner.Id,
      Dealer_Order__c = order.Id,
      Name = programYear
    );
    insert pbo;
  }

  private static Account findPartner()
  {
    Id rtId = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer');
    return [SELECT Id, BillingState FROM Account WHERE Name = :partnerAccountName AND RecordTypeId = :rtId];
  }

  @IsTest
  static void getUnique_Test()
  {
    Account partner = findPartner();
    String uniquifier = programYear + '-' + partner.Id;
    Partner_Booking_Order__c result;

    Test.startTest();
    result = PartnerBookingOrder_Selector.getUnique( uniquifier );
    Test.stopTest();

    System.assertNotEquals( null, result );
  }

  @IsTest
  static void getUnique_Null_Test()
  {
    Account partner = findPartner();
    String uniquifier = '1902-' + partner.Id;
    Partner_Booking_Order__c result;
    Exception ex;

    Test.startTest();
    try
    {
      result = PartnerBookingOrder_Selector.getUnique(uniquifier);
    }
    catch( Exception e )
    {
      ex = e;
    }
    Test.stopTest();

    System.assertEquals( null, result );
    System.assertNotEquals( null, ex );
  }
}