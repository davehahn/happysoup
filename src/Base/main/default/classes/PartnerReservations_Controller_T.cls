/**
 * Created by dave on 2020-10-07.
 */

@IsTest
private class PartnerReservations_Controller_T
{
  static String partnerAccountName = 'TestPartner';
  static String factoryAccountName = 'TestFactory';
  static List<String> factoryUserNames = new List<String>{'Fuf','Ful'};
  static List<String> partnerUserNames = new List<String>{'Puf','Pul'};

  static User runningUser;
  static Account userAccount;
  static Account customer;
  static Product2[] boats;
  static Product2[] trailers;
  static Dealer_Order__c order;
  static AcctSeed__Project__c[] boatERPs;
  static List<Promotion__c> promotions;


  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    buildAccountsAndUsers();
  }

  private static void buildAccountsAndUsers()
  {
    Account[] partnerAccounts = Factory_Account.buildDealerAccounts(2);
    partnerAccounts[0].Name = partnerAccountName;
    partnerAccounts[1].Name = factoryAccountName;
    partnerAccounts[1].Is_Internal__c = true;
    insert partnerAccounts;
    Factory_User.createPartnerUser(
      partnerAccounts[0].Id,
      partnerUserNames[0],
      partnerUserNames[1]
    );
    Factory_User.createPartnerUser(
      partnerAccounts[1].Id,
      factoryUserNames[0],
      factoryUserNames[1]
    );
  }

  private static void setUser( String userType )
  {
    List<String> names;
    switch on userType
    {
      when 'partner'
      {
        names = partnerUserNames;
      }
      when 'factory'
      {
        names = factoryUserNames;
      }
    }
    runningUser = [
      SELECT
        Id,
        AccountId
      FROM User
      WHERE FirstName = :names[0]
      AND LastName = :names[1]
    ];
    userAccount = [SELECT Id, Name FROM Account WHERE Id = :runningUser.AccountId];
  }

  private static void testDataSetup()
  {
    boats = Factory_Product.createSerializedProducts('Boat', 'Pontoon', 3);
    trailers = Factory_Product.createSerializedProducts('Trailer', 'Pontoon Trailer', 3);
  }

  private static void buildOrders()
  {
    boatERPs = Factory_ERPOrder.createPartnerBoatSales(
      userAccount,
      new List<Product2>{boats[0], trailers[0]},
      new List<String>{'Plan Load', 'Delivered'}
    );
    order = Factory_DealerOrder.createDealerOrder( userAccount, 'Pending Review' );
    boatERPs[1].Stage__c = 'Delivered';
    Boolean origTrig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    update boatERPs[1];
    gcProject.disableTrigger =  origTrig;
    Dealer_Order_Line__c[] dols = new List<Dealer_Order_Line__c>();
    dols.add( Factory_DealerOrder.buildDealerOrderLine( boatERPs[0], order, boats[0] ) );
    dols.add( Factory_DealerOrder.buildDealerOrderLine( boatERPs[1], order, boats[0] ) );
    insert dols;
  }

  private static void buildPromotions()
  {
    promotions = Factory_Promotion.buildPromotions( 3 );
    promotions[0].Available_On__c = 'Reservation';
    insert promotions;
    List<Promotion_Item__c> pItems = new List<Promotion_Item__c>();
    for( Promotion__c p : promotions)
    {
      pItems.add(
        Factory_Promotion.buildPromoItem(
          p,
          boats[0],
          1000
        )
      );
    }
    insert pItems;
  }

  private static String customerJSON()
  {
    customer = Factory_Account.buildFullPersonAccount('TestFirst', 'TestLast');
    insert customer;
    return JSON.serialize(
      new Customer.Person( customer )
    );
  }

  @IsTest
  static void init_isFactoryStore_Fail()
  {
    try {
      String resultJSON = PartnerReservations_Controller.init();
    }
    catch( Exception e )
    {
      System.assertEquals( 'You appear to be logged in as a Non Partner User',
                           e.getMessage() );
    }
  }

  @IsTest
  static void isFactoryStore_False_NoSettings()
  {
    setUser('partner');
    System.runAs( runningUser )
    {
      Test.startTest();
      String resultJSON = PartnerReservations_Controller.init();
      Map<String, Boolean> result = (Map<String, Boolean>)JSON.deserialize(
        resultJSON,
        Map<String, Boolean>.class
      );
      Test.stopTest();

      System.assert( !result.get('isFactoryStore'), 'Should not be a factory store');
      System.assert( !result.get('allowDraftBookingOrders'), 'Draft Booking Orders should not be allowed');
    }
  }

  @IsTest
  static void isFactoryStore_False_WithSettingsTrue()
  {
    Date tDay = Date.today();
    String monthDayString = String.valueOf( tday.month() + 6 ) + '/01';
    Partner_Boat_Sale_Settings__c settings = new Partner_Boat_Sale_Settings__c(
      Booking_Order_Begin_Month_Day__c = monthDayString
    );
    insert settings;
    setUser('partner');
    System.runAs( runningUser )
    {
      Test.startTest();
      String resultJSON = PartnerReservations_Controller.init();
      Map<String, Boolean> result = (Map<String, Boolean>)JSON.deserialize(
        resultJSON,
        Map<String, Boolean>.class
      );
      Test.stopTest();

      System.assert( !result.get('isFactoryStore'), 'Should not be a factory store');
      System.assert( result.get('allowDraftBookingOrders'), 'Draft Booking Orders should be allowed');
    }
  }

  @IsTest
  static void isFactoryStore_False_WithSettingsFalse()
  {
    Date tDay = Date.today();
    String monthDayString = String.valueOf( tday.month() - 6 ) + '/01';
    Partner_Boat_Sale_Settings__c settings = new Partner_Boat_Sale_Settings__c(
      Booking_Order_Begin_Month_Day__c = monthDayString
    );
    insert settings;
    setUser('partner');
    System.runAs( runningUser )
    {
      Test.startTest();
      String resultJSON = PartnerReservations_Controller.init();
      Map<String, Boolean> result = (Map<String, Boolean>)JSON.deserialize(
        resultJSON,
        Map<String, Boolean>.class
      );
      Test.stopTest();

      System.assert( !result.get('isFactoryStore'), 'Should not be a factory store');
      System.assert( !result.get('allowDraftBookingOrders'), 'Draft Booking Orders should not be allowed');
    }
  }

  @IsTest
  static void isFactoryStore_true()
  {
    setUser('factory');
    System.runAs( runningUser )
    {
      Test.startTest();
      String resultJSON = PartnerReservations_Controller.init();
      Map<String, Boolean> result = (Map<String, Boolean>)JSON.deserialize(
        resultJSON,
        Map<String, Boolean>.class
      );
      Test.stopTest();

      System.assert( result.get('isFactoryStore'), 'Should be a factory store');
    }
  }



  @IsTest
  static void fetchOutstandingBoatOrders_Test()
  {
    setUser('partner');
    testDataSetup();
    System.runAs( runningUser )
    {
      buildOrders();
      Test.startTest();
      String resultJSON = PartnerReservations_Controller.fetchOutstandingBoatOrders();
      List<Partner_OutstandingBoatOrders.OrderLine> result = (List<Partner_OutstandingBoatOrders.OrderLine>)JSON.deserialize(
        resultJSON, List<Partner_OutstandingBoatOrders.OrderLine>.class );
      System.assertEquals( 1, result.size() );
      System.assertEquals( result[0].majorItemName, boats[0].Name );
      System.assertEquals( result[0].erpOrderId, boatERPs[0].Id );
      System.assertEquals( result[0].dealerOrderId, order.Id );
      System.assertEquals( result[0].estArrivalDate, null );
      System.assertEquals( 1, result[0].lineItems.size() );
    }
  }

  @IsTest
  static void createReservation_Test()
  {
    setUser('partner');
    testDataSetup();
    System.runAs( runningUser )
    {
      buildOrders();
      Test.startTest();
      String jsonResult = PartnerReservations_Controller.createReservation(
        String.valueOf(boatERPs[0].Id),
        customerJSON()
      );
      Account resultAccount = (Account)JSON.deserialize( jsonResult, Account.class );
      Test.stopTest();

      AcctSeed__Project__c resultERP = [
        SELECT
          Id,
          Reserved_For_Customer_Account__c
        FROM AcctSeed__Project__c
        WHERE Id = :boatERPs[0].Id
      ];

      System.assertEquals( resultAccount.Id, customer.Id );
      System.assertEquals( resultERP.Reserved_For_Customer_Account__c, customer.Id );
    }
  }

  @IsTest
  static void checkForPromotions_Test()
  {
    setUser('partner');
    testDataSetup();
    buildPromotions();
    System.runAs( runningUser )
    {
      Test.startTest();
      String jsonResult = PartnerReservations_Controller.checkForPromotions( boats[0].Id );
      List<Promotion_Item__c> result =
        (List<Promotion_Item__c>)JSON.deserialize(
          jsonResult, List<Promotion_Item__c>.class
        );
      System.assertEquals( 1, result.size() );
    }
  }

  @IsTest
  static void createPromotionCase_Test()
  {
    setUser('partner');
    testDataSetup();
    buildPromotions();
    System.runAs( runningUser )
    {
      customerJSON();
      Promotion_Item__c pItem = [
        SELECT Id
        FROM Promotion_Item__c
        WHERE Product__c = :boats[0].Id
        AND Promotion__c = :promotions[0].Id
      ];
      Map<String, String> data = new Map<String, String>{
        'promoItemId' => String.valueOf(pItem.Id),
        'customerId' => customer.Id
      };
      Test.startTest();
      String resultJSON = PartnerReservations_Controller.createPromotionCase(
        JSON.serialize( data )
      );
      Test.stopTest();

      Case result = (Case)JSON.deserialize( resultJSON, Case.class );
      runningUser = [
        SELECT
          Id,
          ContactId,
          AccountId
        FROM User
        WHERE Id = :runningUser.Id
      ];

      System.assertEquals( result.Promotion_Customer_Account__c, customer.Id );
      System.assertEquals( result.ContactId, runningUser.ContactId );
      System.assertEquals( result.Promotion_Item__c, pItem.Id );
      System.assertEquals( result.Status, 'Pending documentation' );
    }
  }

  @IsTest
  static void cancelReservation_Test()
  {
    setUser('partner');
    testDataSetup();
    buildPromotions();
    runningUser = [
      SELECT
        Id,
        ContactId,
        AccountId
      FROM User
      WHERE Id = :runningUser.Id
    ];
    customerJSON();
    Promotion_Item__c pItem = [
      SELECT Id
      FROM Promotion_Item__c
      WHERE Product__c = :boats[0].Id
      AND Promotion__c = :promotions[0].Id
    ];

    System.runAs(runningUser)
    {
      buildOrders();
      boatErps[0].Reserved_For_Customer_Account__c = customer.Id;
      Boolean o = gcProject.disableTrigger;
      gcProject.disableTrigger = true;
      update boatERPs[0];
      gcProject.disableTrigger = o;
      Case promoCase = new Case(
        ContactId = runningUser.ContactId,
        AccountId = runningUser.AccountId,
        RecordTypeId = LGND_Constants.caseRtId_Promotion,
        Promotion_Item__c = pItem.Id,
        Promotion_Customer_Account__c = customer.Id,
        Status = 'Pending documentation'
      );
      insert promoCase;
      Test.startTest();
      PartnerReservations_Controller.cancelReservation( boatERPs[0].Id, promoCase.Id );
      Test.stopTest();

      AcctSeed__Project__c pBoatSale = [
        SELECT
          Id,
          Reserved_For_Customer_Account__c
        FROM AcctSeed__Project__c
        WHERE Id = : boatERPs[0].Id
      ];
      List<Case> cases = [
        SELECT Id
        FROM Case
        WHERE Id = :promoCase.Id
      ];

      System.assertEquals( null, pBoatSale.Reserved_For_Customer_Account__c );
      System.assertEquals( 0, cases.size() );
    }
  }

  @IsTest
  static void submitCase_Test()
  {
    setUser('partner');
    testDataSetup();
    runningUser = [
      SELECT
        Id,
        ContactId,
        AccountId
      FROM User
      WHERE Id = :runningUser.Id
    ];
    customerJSON();
    System.runAs(runningUser)
    {
      Case promoCase = new Case(
        ContactId = runningUser.ContactId,
        AccountId = runningUser.AccountId,
        RecordTypeId = LGND_Constants.caseRtId_Promotion,
        Promotion_Customer_Account__c = customer.Id,
        Status = 'Pending documentation'
      );
      insert promoCase;
      Test.startTest();
      PartnerReservations_Controller.submitCase( promoCase.Id );
      Test.stopTest();

      promoCase = [
        SELECT Id,
               Status
        FROM Case
        WHERE Id = :promoCase.Id
      ];

      System.assertEquals( promoCase.Status, 'Pending review' );
    }
  }
}