@isTest
private class ProductDelete_Trigger_Test {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @isTest
  static void boat_delete_test() {
    InventoryTestFactory factory = new InventoryTestFactory();
    Product2 boat = factory.insertTestBoatWithFeatures(10);
    Id boatId = boat.Id;
    List<Product_Option__c> motorOptions = factory.buildMotorOptions(boat, 5);
    insert motorOptions;

    List<Product_Option__c> pos = [
      SELECT Id
      FROM Product_Option__c
      WHERE From_Product__c = :boatId OR To_Product__c = :boatId
    ];
    List<Product_Feature_Map__c> pfMaps = [SELECT Id FROM Product_Feature_Map__c WHERE Product_Id__c = :boatId];

    Schema.DescribeFieldResult featureCategory = Feature__c.Category__c.getDescribe();

    System.assertEquals(5, pos.size());
    System.assertEquals((featureCategory.getPicklistValues().size() * 10), pfMaps.size());

    test.startTest();
    delete boat;
    pos = [SELECT Id FROM Product_Option__c WHERE From_Product__c = :boatId OR To_Product__c = :boatId];
    pfMaps = [SELECT Id FROM Product_Feature_Map__c WHERE Product_Id__c = :boatId];
    //We test this because the default behavior is to simply blank out the lookup fields and we want to make sure we delete them;
    test.stopTest();

    System.assertEquals(0, pos.size());
    System.assertEquals(0, pfMaps.size());
  }

  @isTest
  static void motor_delete_test() {
    InventoryTestFactory factory = new InventoryTestFactory();

    Product2 motor = factory.buildTestProducts(1, 'Motor')[0];
    List<Product2> toMotors = factory.buildTestProducts(5, 'Motor');
    insert motor;
    insert toMotors;

    List<Product_Upgrade__c> pus = new List<Product_Upgrade__c>();

    for (Product2 toMotor : toMotors) {
      pus.add(factory.buildProductUpgrade(motor.Id, toMotor.Id, 1000.00));
    }

    insert pus;

    pus = [SELECT Id FROM Product_Upgrade__c WHERE To_Product__c = :motor.Id OR From_Product__c = :motor.Id];

    System.assertEquals(5, pus.size());

    test.startTest();
    delete motor;
    pus = [SELECT Id FROM Product_Upgrade__c WHERE To_Product__c = :motor.Id OR From_Product__c = :motor.Id];
    List<Product_Upgrade__c> pus_blank = [
      SELECT Id
      FROM Product_Upgrade__c
      WHERE To_Product__c = NULL OR From_Product__c = NULL
    ];
    test.stopTest();

    System.assertEquals(0, pus.size());
    System.assertEquals(0, pus_blank.size());
  }
}
