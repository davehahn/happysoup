/**
 * Created by dave on 2020-04-29.
 */

@IsTest
private class OnlineBoatReservation_Controller_T
{
//  static final Decimal BOAT_PRICE = 30000;
//  static final Decimal PREMIUM_PACKAGE_PRICE = 5000;
//  static final List<Schema.PickListEntry> FEATURE_CATEGORIES = Feature__c.Category__c.getDescribe().getPicklistValues();
//  static final Integer FEATURE_COUNT = 3;
//  static final List<String> PART_FAMILIES = new List<String>{'Electronics', 'Saftey', 'Canvas'};
//  static Product2 boat;
//  static Product2 standardTrailer;
//  static Product2 standardMotor;
//  static Product2 premiumPackage;

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

//    PricebookEntry[] stdPbEntries = new List<PricebookEntry>();
//    PricebookEntry[] pbEntries = new List<PricebookEntry>();
//    Product_Option__c[] options = new List<Product_Option__c>();
//
//    boat = Factory_Product.createSerializedProducts_AvailableOnline( 'Boat', 'Full Windshield', 1 )[0];
//    stdPbEntries.add( Factory_PricebookEntry.buildEntry( boat.Id, Test.getStandardPricebookId(), BOAT_PRICE ) );
//    pbEntries.add( Factory_PricebookEntry.buildEntry( boat.Id, LGND_Constants.retailPricebookId, BOAT_PRICE ) );
//
//    standardTrailer = Factory_Product.createSerializedProduct('Trailer', 'Boat Trailer' );
//    boat.Standard_Trailer__c = standardTrailer.Id;
//    stdPbEntries.add( Factory_PricebookEntry.buildEntry( standardTrailer.Id, Test.getStandardPricebookId(), 1000 ) );
//    pbEntries.add( Factory_PricebookEntry.buildEntry( standardTrailer.Id, LGND_Constants.retailPricebookId, 1000 ) );
//
//    standardMotor = Factory_Product.createSerializedProduct('Motor', ' Remote' );
//    boat.Standard_Motor__c = standardMotor.Id;
//    stdPbEntries.add( Factory_PricebookEntry.buildEntry( standardMotor.Id, Test.getStandardPricebookId(), 2000 ) );
//    pbEntries.add( Factory_PricebookEntry.buildEntry( standardMotor.Id, LGND_Constants.retailPricebookId, 2000 ) );
//
//    update boat;

    /* Motor & Trailer Upgrades */
//    List<Product2> motors = Factory_Product.createSerializedProducts( 'Motor', 'Remote', 5 );
//    stdPbEntries.addAll( Factory_PricebookEntry.buildEntries( motors, Test.getStandardPricebookId(), 1000 ) );
//    pbEntries.addAll( Factory_PricebookEntry.buildEntries( motors, LGND_Constants.retailPricebookId, 1000 ) );
//    for( Integer i=0; i<motors.size(); i++ )
//    {
//      options.add( Factory_ProductOption.buildProductOption(
//        boat.Id,
//        motors[i].Id,
//        0,
//        1,
//        i < 2
//      ));
//    }
//
//    List<Product2> trailers = Factory_Product.createSerializedProducts( 'Trailer', 'Boat Trailer', 5 );
//    stdPbEntries.addAll( Factory_PricebookEntry.buildEntries( trailers, Test.getStandardPricebookId(), 1000 ) );
//    pbEntries.addAll( Factory_PricebookEntry.buildEntries( trailers, LGND_Constants.retailPricebookId, 1000 ) );
//    for( Integer i=0; i<trailers.size(); i++ )
//    {
//      options.add( Factory_ProductOption.buildProductOption(
//        boat.Id,
//        trailers[i].Id,
//        0,
//        1,
//        i < 2
//      ));
//    }
//
//    Factory_ProductUpgrade.createUpgradesWithCostInPricebook(
//      standardTrailer.Id,
//      trailers,
//      LGND_Constants.retailPricebookId,
//      100
//    );
//
//    Factory_ProductUpgrade.createUpgradesWithCostInPricebook(
//      standardMotor.Id,
//      motors,
//      LGND_Constants.retailPricebookId,
//      100
//    );

    /* Premium Package */
//    premiumPackage = Factory_Product.createNonSerializedProduct( 'Part', 'Premium Package' );
//    stdPbEntries.add( Factory_PricebookEntry.buildEntry( premiumPackage.Id, Test.getStandardPricebookId(), PREMIUM_PACKAGE_PRICE ) );
//    pbEntries.add( Factory_PricebookEntry.buildEntry( premiumPackage.Id, LGND_Constants.retailPricebookId, PREMIUM_PACKAGE_PRICE ) );
//    Factory_ProductFeature.createAllFeatures( premiumPackage.Id, FEATURE_COUNT );
//    options.add( Factory_ProductOption.buildProductOption( boat.Id, premiumPackage.Id, 1, 1, true ) );

//    List<Product2> parts = new List<Product2>();
//    for( String family : PART_FAMILIES )
//    {
//      for( Integer i=0; i<15; i++ )
//      {
//        parts.add( Factory_Product.buildNonSerializedProduct( 'Part', family ) );
//      }
//    }
//    insert parts;
//    stdPbEntries.addAll( Factory_PricebookEntry.buildEntries( parts, Test.getStandardPricebookId(), 100 ) );
//    pbEntries.addAll( Factory_PricebookEntry.buildEntries( parts, LGND_Constants.retailPricebookId, 100 ) );
//
//    Map<String,Set<Id>> boatFilter = new Map<String,Set<Id>>();
//    Map<String,Set<Id>> motorFilter = new Map<String,Set<Id>>();
//    Map<String,Set<Id>> trailerFilter =new Map<String,Set<Id>>();
//    List<AcctSeed__Product_Part__c> productParts = new List<AcctSeed__Product_Part__c>();
//    for( Product2 part : parts )
//    {
//      Id parentId = boat.Id;
//      Boolean availableOnline = false;
//      if( !boatFilter.containsKey( part.Family ) )
//        boatFilter.put( part.Family, new Set<Id>() );
//      if( !motorFilter.containsKey( part.Family ) )
//        motorFilter.put( part.Family, new Set<Id>() );
//      if( !trailerFilter.containsKey( part.Family ) )
//        trailerFilter.put( part.Family, new Set<Id>() );
//
//      if( boatFilter.get( part.Family ).size() == 0 )
//      {
//        boatFilter.get( part.Family ).add( part.Id );
//        parentId = boat.Id;
//        availableOnline = true;
//        for( Product2 pp : Factory_Product.createNonSerializedProducts('Part', 'Electronics', 3) )
//        {
//          stdPbEntries.add( Factory_PricebookEntry.buildEntry( pp.Id, Test.getStandardPricebookId(), 10 ) );
//          pbEntries.add( Factory_PricebookEntry.buildEntry( pp.Id, LGND_Constants.retailPricebookId, 10 ) );
//          productParts.add( new AcctSeed__Product_Part__c(
//            AcctSeed__Product__c = part.Id,
//            AcctSeed__Product_Part__c = pp.Id,
//            AcctSeed__Quantity__c = 1
//          ));
//        }
//      }
//      else if( motorFilter.get( part.Family ).size() == 0 )
//      {
//        motorFilter.get( part.Family ).add( part.Id );
//        parentId = standardMotor.Id;
//        availableOnline = true;
//      }
//      else if( motorFilter.get( part.Family ).size() == 1 )
//      {
//        motorFilter.get( part.Family ).add( part.Id );
//        parentId = motors[0].Id;
//        availableOnline = true;
//      }
//      else if( trailerFilter.get( part.Family ).size() == 0 )
//      {
//        trailerFilter.get( part.Family ).add( part.Id );
//        parentId = standardTrailer.Id;
//        availableOnline = true;
//      }
//      options.add( Factory_ProductOption.buildProductOption( parentId, part.Id, 0, 2, availableOnline) );
//    }
//    insert stdPbEntries;
//    insert pbEntries;
//    insert options;
//    insert productParts;

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
}