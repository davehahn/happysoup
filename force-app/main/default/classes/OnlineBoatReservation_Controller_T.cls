/**
 * Created by dave on 2020-04-29.
 */

@IsTest
private without sharing class OnlineBoatReservation_Controller_T
{

  static Factory_Boat boatFactory;
  static Id personRT = LGND_Utilities.recordTypeIdFromName('Account', 'Person Account');
  static Id retailPbId = LGND_Constants.retailPricebookId;
  static String email = 'someone@someplace.somedomain';
  static Map<String, String> custJSON = new Map<String, String>
  {
    'firstName' => 'TestFirst',
    'lastName' => 'TestLast',
    'phone' => '111-111-1111',
    'email' => email,
    'state' => 'Ontario'
  };
  static Account acct = new Account(
    FirstName = 'TestFirst',
    LastName = 'TestLast',
    Phone = '111-111-1111',
    PersonEmail = email,
    RecordTypeId = personRT,
    BillingState = 'Ontario'
  );
  static Account acct1 = new Account(
    FirstName = 'TestFirst1',
    LastName = 'TestLast1',
    Phone = '111-111-1111',
    PersonEmail = email,
    RecordTypeId = personRT,
    BillingState = 'Ontario'
  );
  static Account acct2 = new Account(
    FirstName = 'TestFirst1',
    LastName = 'TestLast1',
    Phone = '111-111-1111',
    PersonEmail = email,
    RecordTypeId = personRT,
    BillingState = 'Ontario'
  );

  static Product2 boat;
  static Product2 motor;
  static Product2 trailer;
  static Product2[] parts;
  static Map<Id, PricebookEntry> pbEntryMap = new Map<Id, PricebookEntry>();
  static Opportunity opp;
  static User guest = Factory_User.createUser('Guest', 'BoatRes', 'Boat Reservation Profile');


  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Factory_Product.createSerializedProducts_AvailableOnline('Boat', 'Pontoon', 5);
  }

  private static void dataSetupForFullBoat()
  {
    List<Map<String, String>> rtFamily = new List<Map<String, String>>();
    rtFamily.add(new Map<String, String>
    {
      'recordTypeName' => 'Motor', 'family' => 'Remote'
    });
    rtFamily.add(new Map<String, String>
    {
      'recordTypeName' => 'Trailer', 'family' => 'Boat Trailer'
    });

    boatFactory = new Factory_Boat('Full Windshield', LGND_Constants.retailPricebookId)
      .addStandardProducts(rtFamily)
      .addMotorUpgrades(5)
      .addTrailerUpgrades(5)
      .addPremiumPackage()
      .addOptions();
    boatFactory.addAdditionalFees(boatFactory.boat.Id);
    boatFactory.addMarketingContent(boatFactory.boat.Id, 3);
    boatFactory.finish();
  }

  private static void setupOpp( Id oppId)
  {
    opp = new Opportunity(
      Id = oppId,
      Deposit__c = 500,
      Name = 'Test Opportunity',
      Pricebook2Id = retailPbId,
      StageName = 'Quoting',
      CloseDate = Date.today().addMonths( 1 ),
      AccountId = acct.Id
    );
  }

  private static void dataSetupForProducts()
  {
    boat = Factory_Product.createSerializedProduct( 'Boat', 'Full Windshield' );
    motor = Factory_Product.createSerializedProduct( 'Motor', ' Remote' );
    trailer = Factory_Product.createSerializedProduct( 'Trailer', 'Boat Trailer' );
    parts = Factory_Product.createNonSerializedProducts( 'Part', 'Electronics', 5 );
    List<Product2> allProds = new List<Product2>();
    allProds.add( boat );
    allProds.add( motor );
    allProds.add( trailer );
    allProds.addAll( parts );
    Factory_PricebookEntry.insertStandardEntries( allProds, 0 );
    List<PricebookEntry> pbes = new List<PricebookEntry>();
    pbes.add( Factory_PricebookEntry.buildEntry( boat.Id, retailPbId, 30000 ) );
    pbes.add( Factory_PricebookEntry.buildEntry( motor.Id, retailPbId, 10000 ) );
    pbes.add( Factory_PricebookEntry.buildEntry( trailer.Id, retailPbId, 10000 ) );
    pbes.addAll( Factory_PricebookEntry.buildEntries( parts, retailPbId, 100 ) );
    insert pbes;
    for( PricebookEntry pbe : pbes )
    {
      pbEntryMap.put( pbe.Product2Id, pbe );
    }
  }

  private  static List<OpportunityLineItem> buildOpportunityLineItems()
  {
    List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
    olis.add( Factory_OpportunityLineItem.buildLineItem(
      pbEntryMap.get( boat.Id ).Id,
      null,
      pbEntryMap.get( boat.Id ).UnitPrice,
      1,
      null
    ));
    olis.add( Factory_OpportunityLineItem.buildLineItem(
      pbEntryMap.get( motor.Id ).Id,
      null,
      pbEntryMap.get( motor.Id ).UnitPrice,
      1,
      null
    ));
    olis.add( Factory_OpportunityLineItem.buildLineItem(
      pbEntryMap.get( trailer.Id ).Id,
      null,
      pbEntryMap.get( trailer.Id ).UnitPrice,
      1,
      null
    ));
    olis.add( Factory_OpportunityLineItem.buildLineItem(
      pbEntryMap.get( parts[0].Id ).Id,
      null,
      pbEntryMap.get( parts[0].Id ).UnitPrice,
      1,
      null
    ));
    olis.add( Factory_OpportunityLineItem.buildLineItem(
      pbEntryMap.get( parts[1].Id ).Id,
      null,
      pbEntryMap.get( parts[1].Id ).UnitPrice,
      1,
      null
    ));
    olis.add( Factory_OpportunityLineItem.buildLineItem(
      pbEntryMap.get( parts[2].Id ).Id,
      null,
      pbEntryMap.get( parts[2].Id ).UnitPrice,
      1,
      parts[1].Id
    ));

    return olis;
  }

  @IsTest
  static void fetchSettings_Test()
  {
    Boat_Reservation_Settings__mdt brSettings =
      [ SELECT Id, Default_Deposit_Amount__c, Default_Interest_Rate__c, Default_Term__c
        FROM Boat_Reservation_Settings__mdt
        LIMIT 1 ];
    Test.startTest();
    Map<String, Object> result =
      OnlineBoatReservation_Controller.fetchSettings();
    Test.stopTest();

    System.assertEquals( brSettings.Default_Term__c, (Decimal)result.get('term') );
    System.assertEquals( brSettings.Default_Deposit_Amount__c, (Decimal)result.get('deposit') );
    System.assertEquals( brSettings.Default_Interest_Rate__c, (Decimal)result.get('interestRate') );
  }

  @IsTest
  static void fetchBoats_Test()
  {
    Test.startTest();
    List<Map<String, String>> result = OnlineBoatReservation_Controller.fetchBoats();
    Test.stopTest();

    System.assertEquals(5, result.size(), 'There should be 5 boats available for online sale');
  }

  @IsTest
  static void fetchBoat_Test()
  {
    dataSetupForFullBoat();

    //System.runAs( guest )
    //{
      Test.startTest();
      OnlineBoat result = OnlineBoatReservation_Controller.fetchBoat(boatFactory.boat.Id);
      Test.stopTest();

      Product2 boat = [
        SELECT
          Id,
          Name
        FROM Product2
        WHERE Id = :boatFactory.boat.Id
      ];

      String testFamily = LGND_Utilities.toCamelCase(Factory_Boat.PART_FAMILIES[0]);
      Schema.PickListEntry[] provEntries = Product_Fee_Amount__c.Province__c.getDescribe().getPicklistValues();

      System.debug(result.standardTrailer);
      System.assertEquals(boat.Id, result.id);
      System.assertEquals(boat.Name, result.name);
      System.assertEquals(Factory_Boat.BOAT_PRICE, result.retailPrice);
      System.assertEquals(boatFactory.standardMotor.Id, result.standardMotor.id);
      System.assertEquals(2, result.motorUpgrades.size());
      System.assertEquals(3, result.motorUpgrades[0].optionalProducts.size());
      System.assertEquals(1, result.motorUpgrades[0].optionalProducts.get(testFamily).size());
      System.assertEquals(boatFactory.standardTrailer.Id, result.standardTrailer.id);
      System.assertEquals(2, result.trailerUpgrades.size());
      System.assertEquals(boatFactory.premiumPackage.Id, result.premiumPackage.id);
      System.assertEquals(Factory_Boat.PREMIUM_PACKAGE_PRICE, result.premiumPackage.value);
      System.assertEquals(Factory_Boat.FEATURE_CATEGORIES.size(), result.premiumPackage.contents.size());
      System.assertEquals(Factory_Boat.FEATURE_COUNT, result.premiumPackage.contents.get(Factory_Boat.FEATURE_CATEGORIES[0].getLabel()).size());
      System.assertEquals(Factory_Boat.PART_FAMILIES.size(), result.optionalProducts.size());
      System.assertEquals(1, result.optionalProducts.get(testFamily).size());
      System.assertEquals(3, result.optionalProducts.get(testFamily)[0].kitComponents.size());
      System.assertEquals(1, result.standardMotor.optionalProducts.get(testFamily).size());
      System.assertEquals(1, result.standardTrailer.optionalProducts.get(testFamily).size());
      System.assertEquals(provEntries.size(), result.additionalFees.size());
      System.assertEquals(3, result.additionalFees.get(provEntries[0].getLabel()).size());
      System.assertEquals(3, result.marketingContent.size());
    //}
  }

  @IsTest
  static void createAccount_Pass_Test()
  {
    Test.startTest();
    OnlineBoatReservation_Controller.AccountSaveResult result =
      OnlineBoatReservation_Controller.createAccount(JSON.serialize(custJSON));
    Test.stopTest();

    Opportunity opp = [SELECT Id, OwnerId, StageName,Pricebook2Id, CloseDate FROM Opportunity Where Id = :result.opportunityId];

    System.assertEquals('success', result.status, 'Result status should be success');
    System.assert(result.record != null, 'An account should be returned');
    System.assert(result.opportunityId != null, 'There should be an Opportunity Id');
    System.assertEquals('Quoting', opp.StageName, 'Opportunity Stage should be Quoting');
    System.assertEquals( LGND_Constants.retailPricebookId, opp.Pricebook2Id );
  }

  @IsTest
  static void createAccount_Guest_Pass_Test()
  {
    System.runAs( guest )
    {
      Test.startTest();
      OnlineBoatReservation_Controller.AccountSaveResult result =
        OnlineBoatReservation_Controller.createAccount(JSON.serialize(custJSON));
      Test.stopTest();

      Opportunity opp = [SELECT Id, OwnerId, StageName,Pricebook2Id, CloseDate FROM Opportunity Where Id = :result.opportunityId];

      System.assertEquals('success', result.status, 'Result status should be success');
      System.assert(result.record != null, 'An account should be returned');
      System.assert(result.opportunityId != null, 'There should be an Opportunity Id');
      System.assertEquals('Quoting', opp.StageName, 'Opportunity Stage should be Quoting');
      System.assertEquals( guest.Id, opp.OwnerId );
      System.assertEquals(LGND_Constants.retailPricebookId, opp.Pricebook2Id);
      System.assertNotEquals( Test.getStandardPricebookId(), opp.Pricebook2Id );
    }
  }

  @IsTest
  static void createAccount_ValidationFail_Test()
  {
    custJSON.put('firstName', null);
    custJSON.put('email', null);
    Test.startTest();
    OnlineBoatReservation_Controller.AccountSaveResult result =
      OnlineBoatReservation_Controller.createAccount(JSON.serialize(custJSON));
    Test.stopTest();

    System.assertEquals('error', result.status, ' Status should be error');
    System.assertEquals(2, result.messages.size());

  }

  @IsTest
  static void createAccount_SingleAccountDuplicate_Test()
  {
    insert acct1;
    Test.startTest();
    OnlineBoatReservation_Controller.AccountSaveResult result =
      OnlineBoatReservation_Controller.createAccount(JSON.serialize(custJSON));
    Test.stopTest();

    Opportunity opp = [SELECT Id, StageName, CloseDate FROM Opportunity Where Id = :result.opportunityId];
    Account[] accts = [SELECT Id FROM Account WHERE IsPersonAccount = true AND PersonEmail = :email ];

    System.assertEquals('success', result.status, 'Result status should be success');
    System.assertEquals(acct1.Id, result.record.Id);
    System.assertEquals('Quoting', opp.StageName, 'Opportunity Stage should be Quoting');
    System.assert(result.opportunityId != null, 'There should be an Opportunity Id');
    System.assertEquals(custJSON.get('firstName'), result.record.FirstName);
    System.assertNotEquals(acct1.FirstName, result.record.FirstName);
    System.assertEquals( 1, accts.size() );
  }

  @IsTest
  static void createAccount_MultipleAccountDuplicate_NoMatch_Test()
  {
    insert acct1;
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;
    dml.DuplicateRuleHeader.runAsCurrentUser = true;
    Database.SaveResult sr = Database.insert(acct2, dml);
    custJSON.put('email', 'someoneelse@somewhereelse.somedomain');
    custJSON.put('firstName', 'Test-First-Diff');
    custJSON.put('lastName', 'Test-Last-Diff');

    Account[] accts = [SELECT Id FROM Account WHERE IsPersonAccount = true];
    System.assertEquals( 2, accts.size() );

    Test.startTest();
    OnlineBoatReservation_Controller.AccountSaveResult result =
      OnlineBoatReservation_Controller.createAccount(JSON.serialize(custJSON));
    Test.stopTest();

    Opportunity opp = [SELECT Id, StageName, CloseDate FROM Opportunity Where Id = :result.opportunityId];
    Account[] newAccts = [SELECT Id, RecordType.Name FROM Account WHERE Id = :result.record.Id ];
    System.assertEquals('success', result.status, 'Result status should be success');
    System.assert( result.record.Id != null );
    System.assertNotEquals(acct.Id, result.record.Id);
    System.assertNotEquals(acct2.Id, result.record.Id);
    System.assertEquals( 1, newAccts.size() );
    System.assertEquals( 'Person Account', newAccts[0].RecordType.Name );
    System.assertEquals( custJSON.get('email'), result.record.PersonEmail );
    System.assert(result.opportunityId != null, 'There should be an Opportunity Id');
    System.assertEquals('Quoting', opp.StageName, 'Opportunity Stage should be Quoting');
    System.assertEquals(custJSON.get('firstName'), result.record.FirstName);
  }

  @IsTest
  static void createAccount_WithSingleFoundLead_Test()
  {
    Lead l = new Lead(
      FirstName = 'TestFirst',
      LastName = 'TestLast',
      Email = email
    );
    insert l;

    Test.startTest();
    OnlineBoatReservation_Controller.AccountSaveResult result =
      OnlineBoatReservation_Controller.createAccount(JSON.serialize(custJSON));
    Test.stopTest();

    l = [SELECT Id, IsConverted FROM Lead WHERE Id = :l.Id];
    Account[] accts = [SELECT Id FROM Account WHERE IsPersonAccount = true AND PersonEmail = :email ];

    System.assertEquals('success', result.status, 'Result status should be success');
    System.assert(result.record != null, 'An account should be returned');
    System.assert(result.opportunityId != null, 'There should be an Opportunity Id');
    System.assert(l.IsConverted, 'Lead should be converted');
    System.assertEquals( 1, accts.size() );
  }

  @IsTest
  static void createAccount_WithSingleFoundLeadAndAccount_Test()
  {
    Lead l = new Lead(
      FirstName = 'TestFirst-lead',
      LastName = 'TestLast-lead',
      Email = email
    );
    insert l;
    insert acct;

    Test.startTest();
    OnlineBoatReservation_Controller.AccountSaveResult result =
      OnlineBoatReservation_Controller.createAccount(JSON.serialize(custJSON));
    Test.stopTest();

    Opportunity opp = [SELECT Id, StageName, CloseDate FROM Opportunity Where Id = :result.opportunityId];
    Account[] accts = [SELECT Id FROM Account WHERE IsPersonAccount = true AND PersonEmail = :email ];
    l = [SELECT Id, IsConverted FROM Lead WHERE Id = :l.Id];

    System.assertEquals('success', result.status, 'Result status should be success');
    System.assertEquals(acct.Id, result.record.Id);
    System.assertEquals('Quoting', opp.StageName, 'Opportunity Stage should be Quoting');
    System.assert(result.opportunityId != null, 'There should be an Opportunity Id');
    System.assertEquals(custJSON.get('firstName'), result.record.FirstName);
    System.assert(l.IsConverted, 'Lead should be converted');
    System.assertEquals( 1, accts.size() );
  }

  @IsTest
  static void createAccount_WithSingleFoundLeadAndMultipleAccounts_NoMatch_Test()
  {
    String diffEmail = 'someoneelse@somewherelese.somedomain';
    Lead l = new Lead(
      FirstName = 'TestFirst',
      LastName = 'TestLast',
      Email = diffEmail
    );
    insert l;
    insert acct1;

    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;
    dml.DuplicateRuleHeader.runAsCurrentUser = true;
    Database.SaveResult sr = Database.insert(acct2, dml);
    custJSON.put('email', diffEmail );

    Test.startTest();
    OnlineBoatReservation_Controller.AccountSaveResult result =
      OnlineBoatReservation_Controller.createAccount(JSON.serialize(custJSON));
    Test.stopTest();

    Opportunity opp = [SELECT Id, StageName, CloseDate FROM Opportunity Where Id = :result.opportunityId];
    l = [SELECT Id, IsConverted FROM Lead WHERE Id = :l.Id];

    System.assertEquals('success', result.status, 'Result status should be success');
    System.assertNotEquals(acct.Id, result.record.Id);
    System.assertNotEquals(acct2.Id, result.record.Id);
    System.assert(result.opportunityId != null, 'There should be an Opportunity Id');
    System.assertEquals('Quoting', opp.StageName, 'Opportunity Stage should be Quoting');
    System.assertEquals(custJSON.get('firstName'), result.record.FirstName);
    System.assert(l.IsConverted, 'Lead should be converted');
  }

  @IsTest
  static void createAccount_WithSingleFoundLeadAndMultipleAccounts_WithMatch_Test()
  {
    Lead l = new Lead(
      FirstName = 'TestFirst',
      LastName = 'TestLast',
      Email = email
    );
    insert l;
    insert acct;
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;
    dml.DuplicateRuleHeader.runAsCurrentUser = true;
    Database.SaveResult sr = Database.insert(acct2, dml);

    Test.startTest();
    OnlineBoatReservation_Controller.AccountSaveResult result =
      OnlineBoatReservation_Controller.createAccount(JSON.serialize(custJSON));
    Test.stopTest();

    Opportunity opp = [SELECT Id, StageName, CloseDate FROM Opportunity Where Id = :result.opportunityId];
    l = [SELECT Id, IsConverted FROM Lead WHERE Id = :l.Id ];

    System.assertEquals('success', result.status, 'Result status should be success');
    System.assertEquals(acct.Id, result.record.Id);
    System.assert(result.opportunityId != null, 'There should be an Opportunity Id');
    System.assertEquals('Quoting', opp.StageName, 'Opportunity Stage should be Quoting');
    System.assertEquals(custJSON.get('firstName'), result.record.FirstName);
    System.assert( l.IsConverted, 'Lead should be converted' );
  }

  @IsTest
  static void saveLineItems_Test()
  {
    dataSetupForProducts();
    insert acct;

    OnlineBoatReservation_Controller.AccountSaveResult result =
      OnlineBoatReservation_Controller.createAccount(JSON.serialize(custJSON));

    setupOpp(result.opportunityId);

    List<OpportunityLineItem> olis = buildOpportunityLineItems();

    Test.startTest();
    OnlineBoatReservation_Controller.saveLineItems(
      JSON.serialize(opp),
      JSON.serialize(olis)
    );
    Test.stopTest();

    Opportunity opp_r = [SELECT Id, Deposit__c FROM Opportunity WHERE Id = :opp.Id];
    List<OpportunityLineItem> olis_r = [SELECT Id, ParentProductId__c FROM OpportunityLineItem WHERE OpportunityId = :opp_r.Id];
    List<OpportunityLineItem> child_olis = new List<OpportunityLineItem>();
    for (OpportunityLineItem oli : olis_r)
    {
      if (oli.ParentProductId__c != null)
        child_olis.add(oli);
    }

    System.assertEquals(500, opp_r.Deposit__c, 'Opportunity Deposit should be 500');
    System.assertEquals(6, olis_r.size());
    System.assertEquals(1, child_olis.size());

  }

}
