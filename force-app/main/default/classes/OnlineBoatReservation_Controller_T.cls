/**
 * Created by dave on 2020-04-29.
 */

@IsTest
private class OnlineBoatReservation_Controller_T
{

  static Factory_Boat boatFactory;


  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Factory_Product.createSerializedProducts_AvailableOnline( 'Boat', 'Pontoon', 5 );
  }

  private static void dataSetupForFullBoat()
  {
    List<Map<String, String>> rtFamily = new List<Map<String, String>>();
    rtFamily.add( new Map<String, String>{ 'recordTypeName' => 'Motor', 'family' => 'Remote'} );
    rtFamily.add( new Map<String, String>{ 'recordTypeName' => 'Trailer', 'family' => 'Boat Trailer'} );

    boatFactory = new Factory_Boat( 'Full Windshield', LGND_Constants.retailPricebookId )
      .addStandardProducts( rtFamily )
      .addMotorUpgrades( 5 )
      .addTrailerUpgrades( 5 )
      .addPremiumPackage()
      .addOptions();
    boatFactory.addAdditionalFees( boatFactory.boat.Id );
    boatFactory.addMarketingContent( boatFactory.boat.Id, 3 );
    boatFactory.finish();
  }

  @IsTest
  static void fetchBoats_Test()
  {
    Test.startTest();
    List<Map<String, String>> result = OnlineBoatReservation_Controller.fetchBoats();
    Test.stopTest();

    System.assertEquals( 5, result.size(), 'There should be 5 boats available for online sale');
  }

  @IsTest
  static void fetchBoat_Test()
  {
    dataSetupForFullBoat();
    Test.startTest();
    OnlineBoat result = OnlineBoatReservation_Controller.fetchBoat( boatFactory.boat.Id );
    Test.stopTest();

    Product2 boat = [
      SELECT
        Id,
        Name
      FROM Product2
      WHERE Id = :boatFactory.boat.Id
    ];

    String testFamily = LGND_Utilities.toCamelCase( Factory_Boat.PART_FAMILIES[0] );
    Schema.PickListEntry[] provEntries = Product_Fee_Amount__c.Province__c.getDescribe().getPicklistValues();

    System.debug( result.standardTrailer );
    System.assertEquals( boat.Id, result.id );
    System.assertEquals( boat.Name, result.name );
    System.assertEquals( Factory_Boat.BOAT_PRICE, result.retailPrice );
    System.assertEquals( boatFactory.standardMotor.Id, result.standardMotor.id );
    System.assertEquals( 2, result.motorUpgrades.size() );
    System.assertEquals( 3, result.motorUpgrades[0].optionalProducts.size() );
    System.assertEquals( 1, result.motorUpgrades[0].optionalProducts.get( testFamily ).size() );
    System.assertEquals( boatFactory.standardTrailer.Id, result.standardTrailer.id );
    System.assertEquals( 2, result.trailerUpgrades.size() );
    System.assertEquals( boatFactory.premiumPackage.Id, result.premiumPackage.id );
    System.assertEquals( Factory_Boat.PREMIUM_PACKAGE_PRICE, result.premiumPackage.value );
    System.assertEquals( Factory_Boat.FEATURE_CATEGORIES.size(), result.premiumPackage.contents.size() );
    System.assertEquals( Factory_Boat.FEATURE_COUNT, result.premiumPackage.contents.get( Factory_Boat.FEATURE_CATEGORIES[0].getLabel() ).size() );
    System.assertEquals( Factory_Boat.PART_FAMILIES.size(), result.optionalProducts.size() );
    System.assertEquals( 1, result.optionalProducts.get( testFamily ).size() );
    System.assertEquals( 3 , result.optionalProducts.get( testFamily)[0].kitComponents.size() );
    System.assertEquals( 1, result.standardMotor.optionalProducts.get( testFamily ).size() );
    System.assertEquals( 1, result.standardTrailer.optionalProducts.get( testFamily ).size() );
    System.assertEquals( provEntries.size(), result.additionalFees.size() );
    System.assertEquals( 3, result.additionalFees.get( provEntries[0].getLabel() ).size() );
    System.assertEquals( 3, result.marketingContent.size() );
  }

  @IsTest
  static void createAccount_Pass_Test()
  {
    Map<String, String> custJSON = new Map<String, String>{
      'firstName' => 'TestFirst',
      'lastName' => 'TestLast',
      'phone' => '111-111-1111',
      'email' => 'test@davetest.boom'
    };

    Test.startTest();
    OnlineBoatReservation_Controller.AccountSaveResult result =
      OnlineBoatReservation_Controller.createAccount( JSON.serialize( custJSON ) );
    Test.stopTest();

    System.assertEquals( 'success', result.status, 'Result status should be success' );
    System.assert( result.record != null, 'An account should be returned' );
  }

  @IsTest
  static void createAccount_Duplicate_Email_Test()
  {
    Account acct = new Account(
      FirstName = 'TestFirst1',
      LastName = 'TestLast1',
      Phone = '111-111-1111',
      PersonEmail = 'test@davetest.boom',
      RecordTypeId = LGND_Utilities.recordTypeIdFromName( 'Account', 'Person Account' )
    );
    insert acct;

    Map<String, String> custJSON = new Map<String, String>{
      'firstName' => 'TestFirst',
      'lastName' => 'TestLast',
      'phone' => '111-111-1111',
      'email' => acct.PersonEmail
    };
    Test.startTest();
      OnlineBoatReservation_Controller.AccountSaveResult result =
        OnlineBoatReservation_Controller.createAccount( JSON.serialize( custJSON ) );
    Test.stopTest();

    System.assertEquals( 'error', result.status, 'Result status should be error' );
    System.assertEquals( 1, result.duplicateRecords.size(), 'Should have 1 duplicate record');
    System.assertEquals( acct.Id, result.duplicateRecords[0].get('Id') );
  }

  @IsTest
  static void createAccount_WithSingleFoundLead_Pass_Test()
  {
    String email = 'someone@someplace.somedomain';
    Lead l = new Lead(
      FirstName = 'TestFirst',
      LastName = 'TestLast',
      Email = email
    );
    insert l;

    Map<String, String> custJSON = new Map<String, String>{
      'firstName' => 'TestFirst',
      'lastName' => 'TestLast',
      'phone' => '111-111-1111',
      'email' => email
    };

    Test.startTest();
    OnlineBoatReservation_Controller.AccountSaveResult result =
      OnlineBoatReservation_Controller.createAccount( JSON.serialize( custJSON ) );
    Test.stopTest();

    l = [SELECT Id, IsConverted FROM Lead WHERE Id = :l.Id ];

    System.assertEquals( 'success', result.status, 'Result status should be success' );
    System.assert( result.record != null, 'An account should be returned' );
    System.assert( l.IsConverted, 'Lead should be converted' );
  }

  @IsTest
  static void createAccount_WithSingleFoundLead_Duplicate_Test()
  {
    String email = 'someone@someplace.somedomain';
    Lead l = new Lead(
      FirstName = 'TestFirst',
      LastName = 'TestLast',
      Email = email
    );
    insert l;
    Account acct = new Account(
      FirstName = 'TestFirst',
      LastName = 'TestLast',
      Phone = '111-111-1111',
      PersonEmail = email,
      RecordTypeId = LGND_Utilities.recordTypeIdFromName( 'Account', 'Person Account' )
    );
    insert acct;

    Map<String, String> custJSON = new Map<String, String>{
      'firstName' => 'TestFirst',
      'lastName' => 'TestLast',
      'phone' => '111-111-1111',
      'email' => email
    };

    Test.startTest();
    OnlineBoatReservation_Controller.AccountSaveResult result =
      OnlineBoatReservation_Controller.createAccount( JSON.serialize( custJSON ) );
    Test.stopTest();

    l = [SELECT Id, IsConverted FROM Lead WHERE Id = :l.Id ];

    System.debug( result.duplicateRecords[0] );
    System.assertEquals( 'error', result.status, 'Result status should be error' );
    System.assertEquals( 1, result.duplicateRecords.size(), 'Should have 1 duplicate record');
    System.assertEquals( acct.Id, result.duplicateRecords[0].get('Id') );
    System.assert( !l.IsConverted, 'Lead should Not be converted' );
  }


}