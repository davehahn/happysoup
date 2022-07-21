@isTest
private class ProductMotorExt_Test {
  testMethod static void getMotorUpgradesTest() {
    /* disable the Gimbal Trigger handler gtProduct.trigger
     until Gimbals code gets deployed, this needs to be commented out for production */
    gcProduct.disableTrigger = true;
    InventoryTestFactory factory = new InventoryTestFactory();
    List<Product2> motors = factory.buildTestProducts(5, 'Motor');
    insert motors;
    List<Product_Upgrade__c> upgrades = new List<Product_Upgrade__c>();
    upgrades.add(factory.buildProductUpgrade(motors[0].Id, motors[1].Id, 100));
    upgrades.add(factory.buildProductUpgrade(motors[0].Id, motors[2].Id, 200));
    upgrades.add(factory.buildProductUpgrade(motors[0].Id, motors[3].Id, 300));
    upgrades.add(factory.buildProductUpgrade(motors[0].Id, motors[4].Id, 400));
    insert upgrades;

    /* instantiate a standard controller and the extension */
    ApexPages.StandardController sc = new ApexPages.StandardController(motors[0]);
    ProductMotorExt pmx = new ProductMotorExt(sc);

    Test.startTest();
    List<Product_Upgrade__c> fetched = pmx.getMotorUpgrades();
    Test.stopTest();

    System.assertEquals(4, fetched.size());
  } //getMotorUpgradesTest()
}
