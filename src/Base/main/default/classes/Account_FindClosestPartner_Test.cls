@isTest
private class Account_FindClosestPartner_Test {
  private static Account orillia;
  private static Account barrie;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

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

  @isTest
  static void findClosestPartner_Test() {
    Test.setMock(HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock());
    Test.startTest();
    String jsonResult = Account_FindClosestPartner.findClosestPartner('orillia', 3, '');
    System.debug(jsonResult);
    Test.stopTest();
    PartnerLocator.SearchResult result = (PartnerLocator.SearchResult) JSON.deserialize(
      jsonResult,
      PartnerLocator.SearchResult.class
    );

    System.assertEquals(orillia.Name, result.mapMarkers[0].name);
    System.assertEquals('3.0 km', result.mapMarkers[0].distance);
    System.assertEquals('6 mins', result.mapMarkers[0].duration);
  }

  @isTest
  static void findClosestPartner_fail_Test() {
    String errMsg;
    Test.setMock(HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock_NoOrigin());
    Test.startTest();
    try {
      Account_FindClosestPartner.findClosestPartner('Fail origin', 3, '');
    } catch (Exception e) {
      errMsg = e.getMessage();
    }
    Test.stopTest();
    System.assertEquals('Fail origin does not appear to be valid', errMsg);
  }
}
