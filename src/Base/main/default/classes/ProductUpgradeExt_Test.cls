@isTest
private class ProductUpgradeExt_Test {
  testMethod static void createProductUpgradeTest() {
    /* disable the Gimbal Trigger handler gtProduct.trigger
     until Gimbals code gets deployed, this needs to be commented out for production */
    gcProduct.disableTrigger = true;
    InventoryTestFactory factory = new InventoryTestFactory();
    List<Product2> motors = factory.buildTestProducts(2, 'Motor');
    insert motors;

    PageReference pageRef = Page.ProductUpgradeForm;
    pageRef.getParameters().put('fromProductId', motors[0].Id);
    pageRef.getParameters().put('toProductId', motors[1].Id);
    Test.setCurrentPageReference(pageRef);

    /* instantiate a standard controller and the extension */
    ApexPages.StandardController sc = new ApexPages.StandardController(new Product_Upgrade__c());
    ProductUpgradeExt pux = new ProductUpgradeExt(sc);
    Product_Upgrade__c new_pu = (Product_Upgrade__c) sc.getRecord();
    new_pu.price__c = 259;

    pux.save();

    Product_Upgrade__c pu_saved = [
      SELECT Id, Price__c
      FROM Product_Upgrade__c
      WHERE From_Product__c = :motors[0].Id AND To_Product__c = :motors[1].Id
    ];

    System.assertEquals(259, pu_saved.Price__c);
  } //createProductUpgrateTest()

  testMethod static void deleteProductUpgradeTest() {
    /* disable the Gimbal Trigger handler gtProduct.trigger
     until Gimbals code gets deployed, this needs to be commented out for production */
    gcProduct.disableTrigger = true;
    InventoryTestFactory factory = new InventoryTestFactory();
    Product_Upgrade__c pu = factory.buildProductUpgrade();
    insert pu;

    ApexPages.StandardController sc = new ApexPages.StandardController(pu);
    ProductUpgradeExt pux = new ProductUpgradeExt(sc);

    List<Product_Upgrade__c> upgrades = [SELECT Id FROM Product_Upgrade__c WHERE Id = :pu.Id];
    System.assertEquals(1, upgrades.size());

    pux.deleteRecord();

    upgrades = [SELECT Id FROM Product_Upgrade__c WHERE Id = :pu.Id];
    System.assertEquals(0, upgrades.size());
  } //deleteProductUpgradeTest
}
