/**
 * Created by Tim on 2021-07-28.
 */

@IsTest
private class FSBoatDetails_Service_T {
  static Factory_Boat boatFactory;

  @TestSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    List<Map<String, String>> rtFamily = new List<Map<String, String>>();
    rtFamily.add(new Map<String, String>{ 'recordTypeName' => 'Motor', 'family' => 'Remote' });
    rtFamily.add(new Map<String, String>{ 'recordTypeName' => 'Trailer', 'family' => 'Boat Trailer' });

    boatFactory = new Factory_Boat('Full Windshield', LGND_Constants.retailPricebookId)
      .addStandardProducts(rtFamily)
      .addMotorUpgrades(2)
      .addTrailerUpgrades(2)
      .addPremiumPackage()
      .addOptions();
    boatFactory.addAdditionalFees(boatFactory.boat.Id);
    boatFactory.addMarketingContent(boatFactory.boat.Id, 3);
    boatFactory.finish();
  }

  @IsTest
  static void fetchFullBoatDetails_Test() {
    init();

    Test.startTest();
    FSBoatDetails_Service result = new FSBoatDetails_Service(boatFactory.boat.Id);
    Test.stopTest();

    Product2 boat = [SELECT Id, Name, Series__c FROM Product2 WHERE Id = :boatFactory.boat.Id];

    System.debug(result);
    System.assertEquals(boat.Id, result.id);
    System.assertEquals(boat.Name, result.name);
    System.assertEquals(boat.Series__c, result.Series);
    System.assertEquals(Factory_Boat.BOAT_PRICE, result.retailPrice);
    System.assertEquals(2, result.motorUpgrades.size());
    System.assertEquals(2, result.trailerUpgrades.size());
    System.assertEquals(Factory_Boat.PART_FAMILIES.size(), result.optionalProducts.size());
  }
}
