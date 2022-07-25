@isTest(seeAllData=true)
private class ProductUpgrades_Test {
  static BoatTestFactory factory;
  static Pricebook2[] pricebooks;
  static Product2[] motors;
  static Product2[] trailers;
  static Product2[] trolling_motors;
  static ProductUpgrades puExt;
  //static PageReference pageRef;

  @isTest
  static void select_change_test() {
    Test.startTest();
    init();
    doSelect();
    Test.stopTest();
    System.assert(puExt.getPricebookSelectOptions().size() > 0);
    System.assertEquals(10, puExt.getMotorSelectOptions().size());
    System.assertEquals(2, puExt.getNewMotorSelectOptions().size()); // Default + one available
    System.assertEquals(10, puExt.getTrailerSelectOptions().size());
    System.assertEquals(2, puExt.getNewTrailerSelectOptions().size()); // Default + one available
    System.assertEquals(10, puExt.getTrollingMotorSelectOptions().size());
    System.assertEquals(2, puExt.getNewTrollingMotorSelectOptions().size()); // Default + one available
    System.assertEquals(8, puExt.getMotorUpgrades().size());
    System.assertEquals(8, puExt.getTrailerUpgrades().size());
    System.assertEquals(8, puExt.getTrollingMotorUpgrades().size());

    puExt.selectedPbIdMap.put('Motor', pricebooks[1].Id);
    puExt.motorPBChanged();

    System.assertEquals(0, puExt.getMotorSelectOptions().size());
  }

  @isTest
  static void edit_upgrade_cost_test() {
    Test.startTest();
    init();
    doSelect();
    Product_Upgrade_Cost__c motorUpgradeCost = puExt.getMotorUpgrades()[0].Product_Upgrade_Costs__r[0];
    Map<String, String> motorJsonData = new Map<String, String>{ 'Cost__c' => '300', 'Id' => motorUpgradeCost.Id };
    Product_Upgrade_Cost__c motorUpgradeCost_after = ProductUpgrades.updateCost(JSON.serialize(motorJsonData));
    Test.stopTest();
    System.assertEquals(100, motorUpgradeCost.Cost__c);
    System.assertEquals(300, motorUpgradeCost_after.Cost__c);
  }

  @isTest
  static void create_new_upgrade_cost_test() {
    Test.startTest();
    init();
    doSelect();
    Map<String, String> jsonData = new Map<String, String>{
      'From_Product_Id' => motors[0].Id,
      'To_Product_Id' => motors[1].Id,
      'Pricebook_Id' => pricebooks[0].Id,
      'Cost' => '200'
    };
    Product_Upgrade_Cost__c puc = ProductUpgrades.createCost(JSON.serialize(jsonData));
    //Lets just refresh the upgrade List
    puExt.selectedIdMap.put('Motor', motors[0].Id);
    puExt.motorSelectChanged();
    Test.stopTest();
    System.assertEquals(200, puc.Cost__c);
    System.assertEquals(9, puExt.getMotorUpgrades().size());
  }

  private static void init() {
    puExt = new ProductUpgrades(new ApexPages.StandardController(new Product_Upgrade__c()));
    factory = new BoatTestFactory();
    pricebooks = new List<Pricebook2>();
    Id salesRtId = new Application_RecordType().getPricebookRecordTypes().getSalesId();
    pricebooks.add(
      new Pricebook2(
        Name = 'Test PB 1',
        isActive = true,
        RecordTypeId = salesRTId,
        Sales_Year__c = String.valueOf(Date.today().year()),
        Version__c = 98
      )
    );
    pricebooks.add(
      new Pricebook2(
        Name = 'Test PB 2',
        isActive = true,
        RecordTypeId = salesRTId,
        Sales_Year__c = String.valueOf(Date.today().year()),
        Version__c = 99
      )
    );
    insert pricebooks;
    motors = factory.insertTestProducts(10, 'Motor', pricebooks[0]);
    trailers = factory.insertTestProducts(10, 'Trailer', pricebooks[0]);
    trolling_motors = factory.insertTestProducts(10, 'Trolling Motor', pricebooks[0]);
    buildUpgrades(motors, pricebooks[0]);
    buildUpgrades(trailers, pricebooks[0]);
    buildUpgrades(trolling_motors, pricebooks[0]);
    //pageRef = Page.ProductUpgradeChart;
  }

  private static void doSelect() {
    puExt.selectedPbIdMap.put('Motor', pricebooks[0].Id);
    puExt.motorPBChanged();
    puExt.selectedPbIdMap.put('Trailer', pricebooks[0].Id);
    puExt.trailerPBChanged();
    puExt.selectedPbIdMap.put('Trolling Motor', pricebooks[0].Id);
    puExt.trollingMotorPBChanged();
    puExt.selectedIdMap.put('Motor', motors[0].Id);
    puExt.motorSelectChanged();
    puExt.selectedIdMap.put('Trailer', trailers[0].Id);
    puExt.trailerSelectChanged();
    puExt.selectedIdMap.put('Trolling Motor', trolling_motors[0].Id);
    puExt.trollingMotorSelectChanged();
  }

  private static void buildUpgrades(Product2[] prods, Pricebook2 pb) {
    // use prods[0] as the from_product
    // use prods[1] as not selected as an upgrade so we have something to add later
    // prods[2] > [9] we make upgrades for
    Product_Upgrade__c[] upgrades = new List<Product_Upgrade__c>();
    Product_Upgrade_Cost__c[] upgradeCosts = new List<Product_Upgrade_Cost__c>();

    for (Integer i = 2; i < prods.size(); i++) {
      upgrades.add(new Product_Upgrade__c(From_Product__c = prods[0].Id, To_Product__c = prods[i].Id));
    }
    insert upgrades;
    for (Product_Upgrade__c pu : upgrades) {
      upgradeCosts.add(new Product_Upgrade_Cost__c(Product_Upgrade__c = pu.Id, Price_Book__c = pb.Id, Cost__c = 100));
    }
    insert upgradeCosts;
  }
}
