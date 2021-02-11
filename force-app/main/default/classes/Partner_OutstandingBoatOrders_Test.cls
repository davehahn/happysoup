@isTest
private class Partner_OutstandingBoatOrders_Test {

  private static Account dealer;
  private static Contact partnerContact;
  private static User partnerUser;
  private static Product2[] boats;
  private static Product2[] trailers;
  private static Dealer_Order__c order;
  private static AcctSeed__Project__c[] boatERPs;
  private static AcctSeed__Project__c[] trailerERPs;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void setup()
  {
    dealer = Factory_Account.insertDealerAccounts(1)[0];
    partnerContact = Factory_Contact.buildContact(
      dealer.Id,
      'PartnerFN',
      'PartnerLN',
      'partner@dealer.com '
    );
    partnerUser = [SELECT Id, Name FROM User WHERE ContactId = :partnerContact.Id ];
    boats = Factory_Product.createSerializedProducts('Boat', 'Pontoon', 3 );
    trailers = Factory_Product.createSerializedProducts('Trailer', 'Pontoon Trailer', 3 );
  }

  private static void buildOrders()
  {
    boatERPs = Factory_ERPOrder.createPartnerBoatSales(
      dealer,
      new List<Product2>{boats[0], trailers[0]},
      new List<String>{'Plan Load', 'Delivered'}
    );
    trailerERPs = Factory_ERPOrder.createPartnerBoatSales(
      dealer,
      new List<Product2>{trailers[0]},
      new List<String>{'Plan Load'}
    );
    order = Factory_DealerOrder.createDealerOrder( dealer, 'Pending Review' );
    boatERPs[1].Stage__c = 'Delivered';
    Boolean origTrig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    update boatERPs[1];
    gcProject.disableTrigger =  origTrig;
    Dealer_Order_Line__c[] dols = new List<Dealer_Order_Line__c>();
    System.debug('in test - ' + boatERPs[0].Stage__c );
    System.debug('in test - ' + boatERPs[1].Stage__c );
    dols.add( Factory_DealerOrder.buildDealerOrderLine( boatERPs[0], order, boats[0] ) );
    dols.add( Factory_DealerOrder.buildDealerOrderLine( boatERPs[1], order, boats[0] ) );
    dols.add( Factory_DealerOrder.buildDealerOrderLine( trailerERPs[0], order, trailers[0] ) );
    insert dols;
  }

	@isTest
  static void fetchOutstandingNumbers_Test()
  {
    setup();
    System.runAs( partnerUser )
    {
      buildOrders();
      Test.startTest();
      String resultJSON = Partner_OutstandingBoatOrders.fetchOutstandingNumbers();
      Test.stopTest();
      Map<String, Integer> result = (Map<String, Integer>)JSON.deserialize( resultJSON, Map<String, Integer>.class );
      System.assertEquals( 1, result.get('boats') );
      System.assertEquals( 1, result.get('trailers') );
    }
  }

  @isTest
  static void fetchOutstandingNumbers_nonPartner_Test()
  {
    Profile su = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
    User u = Factory_User.buildUser('fname', 'lname', su.Id);
    insert u;
    String err;
    System.runAs( u )
    {
      try {
        Partner_OutstandingBoatOrders.fetchOutstandingNumbers();
      }
      catch( Exception e )
      {
        err = e.getMessage();
      }
      System.assertEquals( err, 'Current user does not have an Account Id and is likely not a Partner');
    }
  }

  @isTest
  static void fetchOrderTypeDetails_Boat_Test()
  {
    setup();
    System.runAs( partnerUser )
    {
      buildOrders();
      Test.startTest();
      String resultJSON = Partner_OutstandingBoatOrders.fetchOrderTypeDetails('boat');
      List<Partner_OutstandingBoatOrders.OrderLine> result = (List<Partner_OutstandingBoatOrders.OrderLine>)JSON.deserialize(
        resultJSON, List<Partner_OutstandingBoatOrders.OrderLine>.class );
      System.assertEquals( 1, result.size() );
      System.assertEquals( result[0].majorItemName, boats[0].Name );
      System.assertEquals( result[0].dealerOrderId, order.Id );
      System.assertEquals( 1, result[0].lineItems.size() );
      System.assertEquals( result[0].estArrivalDate, null );
    }
  }

  @isTest
  static void fetchOrderTypeDetails_Boat_withArrivalDateButNoCustomSetting_Test()
  {
    setup();
    System.runAs( partnerUser )
    {
      buildOrders();
      boatERPs[0].Arrival_Date__c = Date.today();
      gcProject.disableTrigger = true;
      update boatERPs[0];
      Test.startTest();
      String resultJSON = Partner_OutstandingBoatOrders.fetchOrderTypeDetails('boat');
      Test.stopTest();
      List<Partner_OutstandingBoatOrders.OrderLine> result =
        (List<Partner_OutstandingBoatOrders.OrderLine>)JSON.deserialize(
          resultJSON, List<Partner_OutstandingBoatOrders.OrderLine>.class
        );
      System.assertEquals( 1, result.size() );
      System.assertEquals( result[0].majorItemName, boats[0].Name );
      System.assertEquals( result[0].dealerOrderId, order.Id );
      System.assertEquals( 1, result[0].lineItems.size() );
      System.assertEquals( result[0].estArrivalDate, null );
    }
  }

  @isTest
  static void fetchOrderTypeDetails_Boat_withArrivalDateAndCustomSetting_Test()
  {
    setup();
    Integer offset = 14;
    insert new Partner_Community_Settings__c(
      Order_Arrival_Date_Offset__c = offset
    );
    System.runAs( partnerUser )
    {
      buildOrders();
      boatERPs[0].Arrival_Date__c = Date.today();
      gcProject.disableTrigger = true;
      update boatERPs[0];
      Test.startTest();
      String resultJSON = Partner_OutstandingBoatOrders.fetchOrderTypeDetails('boat');
      Test.stopTest();
      List<Partner_OutstandingBoatOrders.OrderLine> result =
        (List<Partner_OutstandingBoatOrders.OrderLine>)JSON.deserialize(
          resultJSON, List<Partner_OutstandingBoatOrders.OrderLine>.class
        );
      System.assertEquals( 1, result.size() );
      System.assertEquals( result[0].majorItemName, boats[0].Name );
      System.assertEquals( result[0].dealerOrderId, order.Id );
      System.assertEquals( 1, result[0].lineItems.size() );
      System.assertEquals( result[0].estArrivalDate, Date.today().addDays(offset) );
    }
  }

  @isTest
  static void fetchOrderTypeDetails_Trailer_Test()
  {
    setup();
    System.runAs( partnerUser )
    {
      buildOrders();
      Test.startTest();
      String resultJSON = Partner_OutstandingBoatOrders.fetchOrderTypeDetails('trailer');
      List<Partner_OutstandingBoatOrders.OrderLine> result = (List<Partner_OutstandingBoatOrders.OrderLine>)JSON.deserialize(
        resultJSON, List<Partner_OutstandingBoatOrders.OrderLine>.class );
      System.assertEquals( 1, result.size() );
      System.assertEquals( result[0].majorItemName, trailers[0].Name );
      System.assertEquals( result[0].dealerOrderId, order.Id );
      System.assert( result[0].lineItems == null );
    }
  }

}