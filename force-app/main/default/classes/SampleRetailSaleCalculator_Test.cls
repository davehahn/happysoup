@isTest
private class SampleRetailSaleCalculator_Test {

  static User partnerUser;
  static Product2 boat;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void initPartnerUser()
  {
    Account a = Factory_Account.insertDealerAccounts(1)[0];
    a.Legend_Volume_Discount__c = 4.0;
    a.Legend_Coop_Discount__c = 5.0;
    a.Mercury_Volume_Discount__c = 9.0;
    a.BillingStreet = '139 Fittons Rd West';
    a.BillingCity = 'Orillia';
    a.BillingState = 'Ontario';
    a.BillingCountry = 'Canada';
    a.BillingPostalCode = 'L3V3V3';
    update a;
    Contact c = Factory_Contact.buildContact( a.Id, 'Pfname', 'Plname', 'test@partner.com');
    partnerUser = [SELECT Id FROM User WHERE ContactId = :c.Id];
  }

  private static void setupBoatData()
  {
    Pricebook2[] pbs = [SELECT Id FROM Pricebook2 WHERE Id IN :CPQ_Lib_dh.defaultPricebooks.values() ];
    BoatTestFactory factory = new BoatTestFactory();
    boat = factory.insertFullTestBoats(1, pbs, 'Pontoon')[0];
  }

  @isTest
  static void fetchInitialData_NonPartner_Test()
  {
    String jsonResult = SampleRetailSaleCalculator.fetchInitialData();
    Map<String, String> result = (Map<String, String>)JSON.deserialize( jsonResult, Map<String,String>.class );
    System.assertEquals( null, result.get('legendVolumeDiscount') );
    System.assertEquals( null, result.get('legendCoopDiscount') );
    System.assertEquals( null, result.get('MercuryVolumeDiscount') );
    System.assertEquals( 'false', result.get('isInternalAccount') );
  }

	@isTest
  static void fetchInitialData_Partner_Test()
  {
    initPartnerUser();
    System.runAs( partnerUser )
    {
      String jsonResult = SampleRetailSaleCalculator.fetchInitialData();
      Map<String, String> result = (Map<String, String>)JSON.deserialize( jsonResult, Map<String,String>.class );
      CPQ theCPQ = (CPQ)JSON.deserialize( result.get('cpq'), CPQ.class );
      System.assertEquals( '4.00', result.get('legendVolumeDiscount') );
      System.assertEquals( '5.00', result.get('legendCoopDiscount') );
      System.assertEquals( '9.00', result.get('MercuryVolumeDiscount') );
      System.assertEquals( 'false', result.get('isInternalAccount') );
      System.assertEquals( 'partner', theCPQ.saleType );
      System.assertEquals( Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c,
                           theCPQ.activePricebookId );
    }
  }

  @isTest
  static void fetchMajorProductDetail_Test()
  {
    initPartnerUser();
    setupBoatData();
    System.runAs( partnerUser )
    {
      CPQ theCPQ = new CPQ('partner');
      theCPQ.boatId = boat.Id;
      String jsonResult = SampleRetailSaleCalculator.fetchMajorProductDetails( JSON.serialize( theCPQ ) );
      theCPQ = (CPQ)JSON.deserialize( jsonResult, CPQ.class );
      System.assertEquals( theCPQ.theBoat.name, boat.Name );
      System.assert( theCPQ.baseProductOptions.size() > 0 );
    }
  }
}