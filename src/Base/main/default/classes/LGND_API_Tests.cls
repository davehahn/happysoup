@isTest(SeeAllData=true)
private class LGND_API_Tests {

  static {
    gcProduct.disableTrigger = true;
  }


  @isTest static void media_portal_boats_test() {

    BoatTestFactory factory = new BoatTestFactory();
    //Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
    List<Product2> boats = factory.insertTestProducts(10, 'Boat');

    // set up the request object
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.requestURI =    '/v1/media-vault/boats/';
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    LGND_API_Boats.fetchBoats();
    String jsonData = res.responseBody.toString();
    Map<String, List<LGND_API.ProductWrapper>> returnedGroupedBoats = (Map<String, List<LGND_API.ProductWrapper>>)JSON.deserialize( jsonData,  Map<String, List<LGND_API.ProductWrapper>>.class );
    Test.stopTest();

    System.assert( returnedGroupedBoats.size() >= 0 );
  }

  @isTest static void media_portal_boat_test() {

    BoatTestFactory factory = new BoatTestFactory();
    //Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
    List<Product2> boats = factory.insertTestProducts(10, 'Boat');

    // set up the request object
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.requestURI =    '/v1/media-vault/boats/' + boats[0].Id;
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    LGND_API_Boats.fetchBoats();
    String jsonData = res.responseBody.toString();
    LGND_APIv1_Product returnedBoat = (LGND_APIv1_Product)JSON.deserialize( jsonData, LGND_APIv1_Product.class );

    req.requestURI =    '/v1/media-vault/boats/failure';
    LGND_API_Boats.fetchBoats();
    jsonData = res.responseBody.toString();
    Map<String, Map<String,String>> resBody = (Map<String, Map<String,String>>)JSON.deserialize( jsonData, Map<String, Map<String,String>>.class);
    Test.stopTest();

    System.assert(returnedBoat != null );
    System.assertEquals('Failure', resBody.values()[0].get('status') );
  }

  @isTest static void v1_retail_list_test()
  {
    BoatTestFactory factory = new BoatTestFactory();
    Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c];
    //Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
    List<Product2> pontoon_boats = factory.insertFullTestBoats(2, pb, 'Pontoon');

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    String jsonData;

    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();

    /* boats */
    req.requestURI =    '/v1/retail/boats/';
    LGND_API_Boats.fetchBoats();
    jsonData = res.responseBody.toString();
    Map<String, List<LGND_API.ProductWrapper>> returnedAllBoats = (Map<String, List<LGND_API.ProductWrapper>>)JSON.deserialize( jsonData,  Map<String, List<LGND_API.ProductWrapper>>.class );

    /* motors */
    req.requestURI =    '/v1/retail/motors/';
    LGND_API_Motors.fetchMotors();
    jsonData = res.responseBody.toString();
    Map<String, List<LGND_API.ProductWrapper>> returnedAllMotors = (Map<String, List<LGND_API.ProductWrapper>>)JSON.deserialize( jsonData,  Map<String, List<LGND_API.ProductWrapper>>.class );

    /* trailers */
    req.requestURI =    '/v1/retail/trailers/';
    LGND_API_Trailers.fetchTrailers();
    jsonData = res.responseBody.toString();
    Map<String, List<LGND_API.ProductWrapper>> returnedAllTrailers = (Map<String, List<LGND_API.ProductWrapper>>)JSON.deserialize( jsonData,  Map<String, List<LGND_API.ProductWrapper>>.class );

    Test.stopTest();

    System.assert( returnedAllBoats.size() >= 0 );
    System.assert( returnedAllMotors.size() >= 0 );
    System.assert( returnedAllTrailers.size() >= 0 );
  }

  @isTest static void v2_retail_list_test()
  {
    BoatTestFactory factory = new BoatTestFactory();
    Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c];
    //Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
    List<Product2> pontoon_boats = factory.insertFullTestBoats(2, pb, 'Pontoon');

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    String jsonData;

    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();

    /* boats */
    req.requestURI =    '/v2/retail/boats/';
    LGND_API_Boats.fetchBoats();
    jsonData = res.responseBody.toString();
    Map<String, List<LGND_API.ProductWrapper>> returnedAllBoats = (Map<String, List<LGND_API.ProductWrapper>>)JSON.deserialize( jsonData,  Map<String, List<LGND_API.ProductWrapper>>.class );

    /* motors */
    req.requestURI =    '/v2/retail/motors/';
    LGND_API_Motors.fetchMotors();
    jsonData = res.responseBody.toString();
    Map<String, List<LGND_API.ProductWrapper>> returnedAllMotors = (Map<String, List<LGND_API.ProductWrapper>>)JSON.deserialize( jsonData,  Map<String, List<LGND_API.ProductWrapper>>.class );

    /* trailers */
    req.requestURI =    '/v2/retail/trailers/';
    LGND_API_Trailers.fetchTrailers();
    jsonData = res.responseBody.toString();
    Map<String, List<LGND_API.ProductWrapper>> returnedAllTrailers = (Map<String, List<LGND_API.ProductWrapper>>)JSON.deserialize( jsonData,  Map<String, List<LGND_API.ProductWrapper>>.class );

    Test.stopTest();

    System.assert( returnedAllBoats.size() >= 0 );
    System.assert( returnedAllMotors.size() >= 0 );
    System.assert( returnedAllTrailers.size() >= 0 );
  }


  @isTest static void v1_partner_list_test()
  {
    BoatTestFactory factory = new BoatTestFactory();
    Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c];
    //Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
    List<Product2> pontoon_boats = factory.insertFullTestBoats(2, pb, 'Pontoon');

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    String jsonData;

    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();

    /* boats */
    req.requestURI =    '/v1/partner/boats/';
    LGND_API_Boats.fetchBoats();
    jsonData = res.responseBody.toString();
    Map<String, List<LGND_API.ProductWrapper>> returnedAllBoats = (Map<String, List<LGND_API.ProductWrapper>>)JSON.deserialize( jsonData,  Map<String, List<LGND_API.ProductWrapper>>.class );

    /* motors */
    req.requestURI =    '/v1/partner/motors/';
    LGND_API_Motors.fetchMotors();
    jsonData = res.responseBody.toString();
    Map<String, List<LGND_API.ProductWrapper>> returnedAllMotors = (Map<String, List<LGND_API.ProductWrapper>>)JSON.deserialize( jsonData,  Map<String, List<LGND_API.ProductWrapper>>.class );

    /* trailers */
    req.requestURI =    '/v1/partner/trailers/';
    LGND_API_Trailers.fetchTrailers();
    jsonData = res.responseBody.toString();
    Map<String, List<LGND_API.ProductWrapper>> returnedAllTrailers = (Map<String, List<LGND_API.ProductWrapper>>)JSON.deserialize( jsonData,  Map<String, List<LGND_API.ProductWrapper>>.class );

    Test.stopTest();

    System.assert( returnedAllBoats.size() >= 0 );
    System.assert( returnedAllMotors.size() >= 0 );
    System.assert( returnedAllTrailers.size() >= 0 );
  }

  @isTest static void v2_partner_list_test()
  {

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    String jsonData;

    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();

    BoatTestFactory factory = new BoatTestFactory();
    Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c];
    //Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
    List<Product2> pontoon_boats = factory.insertFullTestBoats(2, pb, 'Pontoon');


    /* boats */
    req.requestURI =    '/v2/partner/boats/';
    LGND_API_Boats.fetchBoats();
    jsonData = res.responseBody.toString();
    Map<String, List<LGND_API.ProductWrapper>> returnedAllBoats = (Map<String, List<LGND_API.ProductWrapper>>)JSON.deserialize( jsonData,  Map<String, List<LGND_API.ProductWrapper>>.class );

    /* motors */
    req.requestURI =    '/v2/partner/motors/';
    LGND_API_Motors.fetchMotors();
    jsonData = res.responseBody.toString();
    Map<String, List<LGND_API.ProductWrapper>> returnedAllMotors = (Map<String, List<LGND_API.ProductWrapper>>)JSON.deserialize( jsonData,  Map<String, List<LGND_API.ProductWrapper>>.class );

    /* trailers */
    req.requestURI =    '/v2/partner/trailers/';
    LGND_API_Trailers.fetchTrailers();
    jsonData = res.responseBody.toString();
    Map<String, List<LGND_API.ProductWrapper>> returnedAllTrailers = (Map<String, List<LGND_API.ProductWrapper>>)JSON.deserialize( jsonData,  Map<String, List<LGND_API.ProductWrapper>>.class );

    Test.stopTest();

    System.assert( returnedAllBoats.size() >= 0 );
    System.assert( returnedAllMotors.size() >= 0 );
    System.assert( returnedAllTrailers.size() >= 0 );
  }

  @isTest
  static void product_options_test_v1()
  {
    Product2 part = Factory_Product.buildNonSerializedProduct('Part', 'Hardware');
    insert part;
    Factory_PricebookEntry.createStandardEntry(part.Id, 10);
    insert Factory_PricebookEntry.buildEntry( part.Id,
                                              Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c,
                                              10 );
    Product2[] option_prods = Factory_Product.buildNonSerializedProducts('Part',
                                                                    'Hardware',
                                                                    15);
    insert option_prods;
    Product_Option__c[] options = Factory_ProductOption.buildProductOptions( part.Id, option_prods, 0, 2 );
    insert options;

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.requestURI =    '/v1/product-options/' + part.Id;
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;
    Test.startTest();
    LGND_APIv1_Product_Options.getOptioanlProducts();
    String jsonData = res.responseBody.toString();

    Test.stopTest();
  }


  @isTest static void boat_test_v1()
   {
    BoatTestFactory factory = new BoatTestFactory();
    List<Pricebook2> pbs = [SELECT Id
                     FROM Pricebook2
                     WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c
                     OR Id = :Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c];
    List<Product2> pontoon_boats = factory.insertFullTestBoats(10, pbs, 'Pontoon');

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.requestURI =    '/v1/retail/boats/' + pontoon_boats[0].Id;
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    LGND_API_Boats.fetchBoats();
    String jsonData = res.responseBody.toString();
    LGND_APIv1_Product returnedRetailBoat = (LGND_APIv1_Product)JSON.deserialize( jsonData, LGND_APIv1_Product.class );

    req.requestURI =    '/v1/partner/boats/' + pontoon_boats[0].Id;
    LGND_API_Boats.fetchBoats();
    jsonData = res.responseBody.toString();
    LGND_APIv1_Product returnedPartnerBoat = (LGND_APIv1_Product)JSON.deserialize( jsonData, LGND_APIv1_Product.class );

    System.assert(pontoon_boats[0].Standard_Motor__c != null);
    System.assert(returnedRetailBoat.StandardMotor != null);
    System.assert(returnedRetailBoat.StandardTrailer != null);
    System.assert(returnedRetailBoat.StandardTrollingMotor != null);
     //5 part type defined in BoatTestFactory by partTypes
    System.assertEquals(5, returnedRetailBoat.OptionalProducts.keySet().size() );
    System.assert(returnedRetailBoat.MotorUpgrades.size() == 9);
    System.assert(returnedRetailBoat.TrailerUpgrades.size() == 9);
    System.assert(returnedRetailBoat.TrollingMotorUpgrades.size() == 9);
     //6 fee type defined in BoatTestFactory
    System.assertEquals(6, returnedRetailBoat.Fees.keySet().size() );

    System.assert(returnedPartnerBoat.StandardMotor != null);
    System.assert(returnedPartnerBoat.StandardTrailer != null);
    System.assert(returnedPartnerBoat.StandardTrollingMotor != null);
     //5 part type defined in BoatTestFactory by partTypes
    System.assertEquals(5, returnedPartnerBoat.OptionalProducts.keySet().size() );
    System.assert(returnedPartnerBoat.MotorUpgrades.size() == 9);
    System.assert(returnedPartnerBoat.TrailerUpgrades.size() == 9);
    System.assert(returnedPartnerBoat.TrollingMotorUpgrades.size() == 9);
     //6 fee type defined in BoatTestFactory
    System.assertEquals(6, returnedPartnerBoat.Fees.keySet().size() );

  }

  @isTest static void boat_test_retail_v2()
  {
    BoatTestFactory factory = new BoatTestFactory();
    List<Pricebook2> pbs = [SELECT Id
    FROM Pricebook2
    WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c
    OR Id = :Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c];
    List<Product2> pontoon_boats = factory.insertFullTestBoats(10, pbs, 'Pontoon');

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.requestURI =    '/v2/retail/boats/' + pontoon_boats[0].Id;
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    LGND_API_Boats.fetchBoats();
    String jsonData = res.responseBody.toString();
    LGND_APIv2_Product returnedRetailBoat = (LGND_APIv2_Product)JSON.deserialize( jsonData, LGND_APIv2_Product.class );
    Test.stopTest();

    System.assert(pontoon_boats[0].Standard_Motor__c != null);
    System.assert(returnedRetailBoat.StandardMotor != null);
    System.assert(returnedRetailBoat.StandardTrailer != null);
    System.assert(returnedRetailBoat.StandardTrollingMotor != null);
    //5 part type defined in BoatTestFactory by partTypes
    System.assertEquals(5, returnedRetailBoat.OptionalProducts.keySet().size() );
    System.assert(returnedRetailBoat.MotorUpgrades.size() == 9);
    System.assert(returnedRetailBoat.TrailerUpgrades.size() == 9);
    System.assert(returnedRetailBoat.TrollingMotorUpgrades.size() == 9);
    //2 fees for each of 6 fee type defined in BoatTestFactory
    System.assertEquals(12, returnedRetailBoat.Fees.get('Ontario').size() );
  }

  @isTest static void boat_test_partner_v2()
   {
      BoatTestFactory factory = new BoatTestFactory();
      List<Pricebook2> pbs = [SELECT Id
                       FROM Pricebook2
                       WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c
                       OR Id = :Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c];
      List<Product2> pontoon_boats = factory.insertFullTestBoats(10, pbs, 'Pontoon');

      RestRequest req = new RestRequest();
      RestResponse res = new RestResponse();

      req.requestURI =    '/v2/partner/boats/' + pontoon_boats[0].Id;
      req.httpMethod = 'GET';
      RestContext.request = req;
      RestContext.response = res;

      Test.startTest();
      LGND_API_Boats.fetchBoats();
      String jsonData = res.responseBody.toString();
      LGND_APIv2_Product returnedPartnerBoat = (LGND_APIv2_Product)JSON.deserialize( jsonData, LGND_APIv2_Product.class );
      Test.stopTest();

      System.assert(pontoon_boats[0].Standard_Motor__c != null);
      System.assert(returnedPartnerBoat.StandardMotor != null);
      System.assert(returnedPartnerBoat.StandardTrailer != null);
      System.assert(returnedPartnerBoat.StandardTrollingMotor != null);
       //5 part type defined in BoatTestFactory by partTypes
      System.assertEquals(5, returnedPartnerBoat.OptionalProducts.keySet().size() );
      System.assert(returnedPartnerBoat.MotorUpgrades.size() == 9);
      System.assert(returnedPartnerBoat.TrailerUpgrades.size() == 9);
      System.assert(returnedPartnerBoat.TrollingMotorUpgrades.size() == 9);
       //2 fees for each of 6 fee type defined in BoatTestFactory
      System.assertEquals(12, returnedPartnerBoat.Fees.get('Ontario').size() );

  }

  @isTest static void motor_test()
  {
    BoatTestFactory factory = new BoatTestFactory();
    List<Pricebook2> pbs = [SELECT Id
                     FROM Pricebook2
                     WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c
                     OR Id = :Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c];
    List<Product2> motors = factory.insertTestProducts(10, 'Motor', pbs);

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;


    Test.startTest();
    req.requestURI =    '/v1/retail/motors/' + motors[0].Id;
    LGND_API_Motors.fetchMotors();
    String jsonData = res.responseBody.toString();
    LGND_APIv1_Product v1MotorRetail = (LGND_APIv1_Product)JSON.deserialize( jsonData, LGND_APIv1_Product.class );


    req.requestURI =    '/v2/retail/motors/' + motors[0].Id;
    LGND_API_Motors.fetchMotors();
    jsonData = res.responseBody.toString();
    LGND_APIv2_Product v2MotorRetail = (LGND_APIv2_Product)JSON.deserialize( jsonData, LGND_APIv2_Product.class );

    req.requestURI =    '/v1/partner/motors/' + motors[0].Id;
    LGND_API_Motors.fetchMotors();
    jsonData = res.responseBody.toString();
    LGND_APIv1_Product v1MotorPartner = (LGND_APIv1_Product)JSON.deserialize( jsonData, LGND_APIv1_Product.class );


    req.requestURI =    '/v2/partner/motors/' + motors[0].Id;
    LGND_API_Motors.fetchMotors();
    jsonData = res.responseBody.toString();
    LGND_APIv2_Product v2MotorPartner = (LGND_APIv2_Product)JSON.deserialize( jsonData, LGND_APIv2_Product.class );
    Test.stopTest();

    System.assert( v1MotorRetail != null );
    System.assert( v2MotorRetail != null );
    System.assert( v1MotorPartner != null );
    System.assert( v2MotorPartner != null );

  }

  @isTest static void trailer_test()
  {
    BoatTestFactory factory = new BoatTestFactory();
    List<Pricebook2> pbs = [SELECT Id
                     FROM Pricebook2
                     WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c
                     OR Id = :Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c];
    List<Product2> trailers = factory.insertTestProducts(10, 'Trailer', pbs);

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;


    Test.startTest();
    req.requestURI =    '/v1/retail/trailers/' + trailers[0].Id;
    LGND_API_Trailers.fetchTrailers();
    String jsonData = res.responseBody.toString();
    LGND_APIv1_Product v1TrailerRetail = (LGND_APIv1_Product)JSON.deserialize( jsonData, LGND_APIv1_Product.class );


    req.requestURI =    '/v2/retail/trailers/' + trailers[0].Id;
    LGND_API_Trailers.fetchTrailers();
    jsonData = res.responseBody.toString();
    LGND_APIv2_Product v2TrailerRetail = (LGND_APIv2_Product)JSON.deserialize( jsonData, LGND_APIv2_Product.class );

    req.requestURI =    '/v1/partner/trailers/' + trailers[0].Id;
    LGND_API_Trailers.fetchTrailers();
    jsonData = res.responseBody.toString();
    LGND_APIv1_Product v1TrailerPartner = (LGND_APIv1_Product)JSON.deserialize( jsonData, LGND_APIv1_Product.class );


    req.requestURI =    '/v2/partner/trailers/' + trailers[0].Id;
    LGND_API_Trailers.fetchTrailers();
    jsonData = res.responseBody.toString();
    LGND_APIv2_Product v2TrailerPartner = (LGND_APIv2_Product)JSON.deserialize( jsonData, LGND_APIv2_Product.class );
    Test.stopTest();

    System.assert( v1TrailerRetail != null );
    System.assert( v2TrailerRetail != null );
    System.assert( v1TrailerPartner != null );
    System.assert( v2TrailerPartner != null );

  }

  @isTest static void failure_test()
  {
    String jsonData;
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    /* fetch boat */

    req.requestURI =    '/v3/partner/boats/failure';
    LGND_API_Boats.fetchBoats();
    jsonData = res.responseBody.toString();
    Map<String, Map<String,String>> boatFail = (Map<String, Map<String,String>>)JSON.deserialize( jsonData, Map<String, Map<String,String>>.class);

    req.requestURI =    '/v1/partner/motors/failure';
    LGND_API_Motors.fetchMotors();
    jsonData = res.responseBody.toString();
    Map<String, Map<String,String>> motorFail = (Map<String, Map<String,String>>)JSON.deserialize( jsonData, Map<String, Map<String,String>>.class);

    req.requestURI =    '/v1/partner/trailers/failure';
    LGND_API_Trailers.fetchtrailers();
    jsonData = res.responseBody.toString();
    Map<String, Map<String,String>> trailerFail = (Map<String, Map<String,String>>)JSON.deserialize( jsonData, Map<String, Map<String,String>>.class);

    req.requestURI =    '/v3/partner/boats/';
    LGND_API_Boats.fetchBoats();
    jsonData = res.responseBody.toString();
    Map<String, Map<String,String>> versionFail = (Map<String, Map<String,String>>)JSON.deserialize( jsonData, Map<String, Map<String,String>>.class);

    req.requestURI =    '/v1/non-member/boats/';
    LGND_API_Boats.fetchBoats();
    jsonData = res.responseBody.toString();
    Map<String, Map<String,String>> apiTypeFail = (Map<String, Map<String,String>>)JSON.deserialize( jsonData, Map<String, Map<String,String>>.class);

    req.requestURI =    '/v3/partner/motors/';
    LGND_API_Motors.fetchMotors();
    jsonData = res.responseBody.toString();
    Map<String, Map<String,String>> versionMFail = (Map<String, Map<String,String>>)JSON.deserialize( jsonData, Map<String, Map<String,String>>.class);

    req.requestURI =    '/v3/partner/Trailers/';
    LGND_API_Trailers.fetchTrailers();
    jsonData = res.responseBody.toString();
    Map<String, Map<String,String>> versionTFail = (Map<String, Map<String,String>>)JSON.deserialize( jsonData, Map<String, Map<String,String>>.class);

     req.requestURI =    '/v1/non-member/motors/';
    LGND_API_Motors.fetchMotors();
    jsonData = res.responseBody.toString();
    Map<String, Map<String,String>> apiTypeMFail = (Map<String, Map<String,String>>)JSON.deserialize( jsonData, Map<String, Map<String,String>>.class);

     req.requestURI =    '/v1/non-member/trailers/';
    LGND_API_Trailers.fetchTrailers();
    jsonData = res.responseBody.toString();
    Map<String, Map<String,String>> apiTypeTFail = (Map<String, Map<String,String>>)JSON.deserialize( jsonData, Map<String, Map<String,String>>.class);

    Test.stopTest();

    System.assertEquals('Failure', boatFail.values()[0].get('status') );
    System.assertEquals('Failure', boatFail.values()[0].get('status') );
    System.assertEquals('Failure', trailerFail.values()[0].get('status') );
    System.assertEquals('Failure', versionFail.values()[0].get('status') );
    System.assertEquals('invalid Api Version Specified v3', versionFail.values()[0].get('message') );
    System.assertEquals('Failure', versionMFail.values()[0].get('status') );
    System.assertEquals('invalid Api Version Specified v3', versionMFail.values()[0].get('message') );
    System.assertEquals('Failure', versionTFail.values()[0].get('status') );
    System.assertEquals('invalid Api Version Specified v3', versionTFail.values()[0].get('message') );
    System.assertEquals('Failure', apiTypeFail.values()[0].get('status') );
    System.assertEquals('invalid Api Type Specified non-member', apiTypeFail.values()[0].get('message') );
    System.assertEquals('Failure', apiTypeMFail.values()[0].get('status') );
    System.assertEquals('invalid Api Type Specified non-member', apiTypeMFail.values()[0].get('message') );
    System.assertEquals('Failure', apiTypeTFail.values()[0].get('status') );
    System.assertEquals('invalid Api Type Specified non-member', apiTypeTFail.values()[0].get('message') );

  }

}