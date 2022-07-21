@isTest
private class ProductBoatExt_Test {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @isTest
  static void newObjectConstructorTest() {
    InventoryTestFactory factory = new InventoryTestFactory();
    Product2 boat = new Product2();
    List<Feature__c> features = factory.buildAllFeatures(8);
    insert features;

    Test.startTest();
    ApexPages.StandardController sc = new ApexPages.StandardController(boat);
    ProductBoatExt pbx = new ProductBoatExt(sc);
    Test.stopTest();
    System.assertEquals(false, pbx.getRenderMotorUpgrades());
    System.assertEquals(false, pbx.getRenderTrailerUpgrades());
    System.assertEquals(false, pbx.getRenderTrollingMotorUpgrades());
    System.assertEquals(null, pbx.recordId);
    System.assertEquals(0, pbx.productFeatures.size());
    System.assertEquals(false, pbx.getHasFeatures());
    System.assertEquals(null, pbx.currentProduct);
    System.assertEquals(null, pbx.productOptions);
    pbx.editFeatures();
  } //newObjectConstructorTest

  @isTest
  static void existingObjectConstructorTest() {
    InventoryTestFactory factory = new InventoryTestFactory();
    Product2 boat = factory.insertTestBoatWithFeatures(7);
    List<Feature__c> features = factory.buildAllFeatures(10);
    insert features;
    List<Product_Option__c> opts = factory.buildPartOptions(boat, 5, 'Hardware');
    insert opts;

    Test.startTest();
    ApexPages.StandardController sc = new ApexPages.StandardController(boat);
    ProductBoatExt pbx = new ProductBoatExt(sc);
    Map<String, Set<String>> categories = new Map<String, Set<String>>();
    //get list of feature categories
    categories.put('feature', new Set<String>());
    Schema.DescribeFieldResult featureCategory = Feature__c.Category__c.getDescribe();
    for (Schema.PickListEntry ple : featureCategory.getPicklistValues()) {
      String cat = ple.getLabel();
      categories.get('feature').add(cat);
    }
    Test.stopTest();

    System.assertEquals(boat.Id, pbx.recordId);
    System.assertEquals(categories.get('feature').size(), pbx.productFeatures.size());

    System.assertEquals(boat.Id, pbx.currentProduct.Id);
    System.assertEquals(5, pbx.productOptions.size());
    for (String cat : categories.get('feature')) {
      System.assertEquals(7, pbx.productFeatures.get(cat).size());
    }
  } //existingObjectConstructorTest

  //*************** Product2 Option Test *************//

  @isTest
  static void getOptionsTests() {
    InventoryTestFactory factory = new InventoryTestFactory();
    Product2 boat = factory.buildTestBoat();
    insert boat;
    Map<String, Integer> optionSetupMap = new Map<String, Integer>();
    optionSetupMap.put('Hardware', 4);
    optionSetupMap.put('Fun and Entertainment', 6);
    optionSetupMap.put('Graphics and Decals', 8);
    optionSetupMap.put('Pontoon Covers', 3);
    optionSetupMap.put('Seating', 10);
    optionSetupMap.put('Safety', 5);
    optionSetupMap.put('Trailering and Covers', 2);

    List<Product_Option__c> options = new List<Product_Option__c>();
    for (String family : optionSetupMap.keyset()) {
      options.addAll(factory.buildPartOptions(boat, optionSetupMap.get(family), family));
    }
    options.addAll(factory.buildMotorOptions(boat, 9));
    options.addAll(factory.buildTrailerOptions(boat, 3));
    options.addAll(factory.buildTrollingMotorOptions(boat, 5));
    insert options;

    ApexPages.StandardController sc = new ApexPages.StandardController(boat);
    ProductBoatExt pbx = new ProductBoatExt(sc);

    System.assertEquals(pbx.productOptions.size(), 55);
    for (String family : optionSetupMap.keyset()) {
      System.assertEquals(pbx.productOptionsMap.get(family).size(), optionSetupMap.get(family));
    }
    System.assertEquals(9, pbx.productUpgradeMap.get('Motor').size());
    System.assertEquals(3, pbx.productUpgradeMap.get('Trailer').size());
    System.assertEquals(5, pbx.productUpgradeMap.get('Trolling Motor').size());
    System.assertEquals(true, pbx.getRenderMotorUpgrades());
    System.assertEquals(true, pbx.getRenderTrailerUpgrades());
    System.assertEquals(true, pbx.getRenderTrollingMotorUpgrades());
  } //getOptionsTests
} // ProductBoatExt_Test
