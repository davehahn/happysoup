/**
 * Created by dave on 2019-10-31.
 */

@IsTest
private class PartnerLocator_T
{

  private static Account orillia;
  private static Account barrie;

  static {
    orillia = Factory_Account.buildDealerAccounts(1)[0];
    orillia.Name = 'Orillia Dealer';
    orillia.BillingStreet = '139 Fittons Rd East';
    orillia.BillingCity = 'Orillia';
    orillia.BillingState = 'Ontario';
    orillia.BillingCountry = 'Canada';
    orillia.BillingPostalCode = 'L3V 2G9';
    orillia.BillingLatitude = 44.62840928065218;
    orillia.BillingLongitude = -79.41666966709374;

    barrie = Factory_Account.buildDealerAccounts(1)[0];
    barrie.Name = 'Barrie Dealer';
    barrie.BillingStreet = '2375 Industrial Park Rd.';
    barrie.BillingCity = 'Innisfil';
    barrie.BillingState = 'Ontario';
    barrie.BillingCountry = 'Canada';
    barrie.BillingPostalCode = 'L9S 3W1';
    barrie.BillingLatitude = 44.29638562156834;
    barrie.BillingLongitude = -79.68193162911972;

    insert new List<Account>{ barrie, orillia };
  }

  @IsTest
  static void execute_Test()
  {
    Test.setMock( HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock() );
    Test.startTest();
    PartnerLocator locator = new PartnerLocator();
    PartnerLocator.SearchResult result = locator.execute( 'orillia', 2 );
    Test.stopTest();
    System.assert( result.origin_address != null );
    System.assertEquals( 2, result.mapMarkers.size() );
  }

  @IsTest
  static void execute_withExclude_Test()
  {
    Test.setMock( HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock() );
    Test.startTest();
    PartnerLocator locator = new PartnerLocator();
    locator.exclude( barrie.Id );
    PartnerLocator.SearchResult result = locator.execute( 'orillia', 2 );
    Test.stopTest();
    System.assert( result.origin_address != null );
    System.assertEquals( 1, result.mapMarkers.size() );
  }

  @IsTest
  static void execute_withDefaultExclude_Test()
  {
    Partner_Locator_Excludes__c exclude = new Partner_Locator_Excludes__c(
      Name = 'Barrie',
      AccountId__c = barrie.Id
    );
    insert exclude;
    Test.setMock( HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock() );
    Test.startTest();
    PartnerLocator locator = new PartnerLocator();
    PartnerLocator.SearchResult result = locator.execute( 'orillia', 2 );
    Test.stopTest();
    System.assert( result.origin_address != null );
    System.assertEquals( 1, result.mapMarkers.size() );
  }
}