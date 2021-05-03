@isTest( seeAllData=true)
private class BoatRemoter_Test {

  static {
     /* disable the Gimbal Trigger handler gtProduct.trigger
       until Gimbals code gets deployed, this needs to be commented out for production */
    //gcProduct.disableTrigger = true;
  }

  // ************** Tests for Product Upgrades ****************//

  testMethod static void fetchUpgradeTest() {
    InventoryTestFactory factory = new InventoryTestFactory();
    Product_Upgrade_Cost__c puc = factory.buildUpgradeAndCostForStdPB();
    insert puc;

    Test.startTest();
    Product_Upgrade_Cost__c valid_remote_pu = BoatRemoter.fetchEditUpgradeDetails(puc.Id);
    Product_Upgrade_Cost__c invalid_remote_pu = BoatRemoter.fetchEditUpgradeDetails('not Id');
    Test.stopTest();

    System.assertEquals(puc.Id, valid_remote_pu.Id);
    System.assertEquals(null, invalid_remote_pu);
  }

  testMethod static void newProductUpgradeTest() {

    InventoryTestFactory factory = new InventoryTestFactory();
    List<Product2> motors = factory.buildTestProducts(2, 'Motor');
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert motors;
    gcProduct.disableTrigger = orig;
    Product2 fromMotor = motors[0];
    Product2 toMotor = motors[1];

    Test.startTest();
    Product_Upgrade__c upgradeObject = BoatRemoter.newProductUpgrade(fromMotor.Id, toMotor.Id);
    Test.stopTest();

    System.assertEquals(fromMotor.Id, upgradeObject.From_Product__c);
    System.assertEquals(toMotor.Id, upgradeObject.To_Product__c);
    System.assertEquals(null, upgradeObject.Id);

  }

  testMethod static void createProductUpgradeTest() {
    InventoryTestFactory factory = new InventoryTestFactory();
    List<Product2> motors = factory.buildTestProducts(2, 'Motor');
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert motors;
    gcProduct.disableTrigger = orig;
    Product2 fromMotor = motors[0];
    Product2 toMotor = motors[1];

    Test.startTest();
    Product_Upgrade__c upgrade = BoatRemoter.createProductUpgrade(fromMotor.Id, toMotor.Id, '1200');
    Product_Upgrade__c no_price = BoatRemoter.createProductUpgrade(fromMotor.Id, toMotor.Id, null);
    Product_Upgrade__c word_price = BoatRemoter.createProductUpgrade(fromMotor.Id, toMotor.Id, 'word');
    Product_Upgrade__c no_from = BoatRemoter.createProductUpgrade(null, toMotor.Id, '1500');
    Product_Upgrade__c no_to = BoatRemoter.createProductUpgrade(fromMotor.Id, null, '1500');
    Test.stopTest();

    System.assertEquals(fromMotor.Id, upgrade.From_Product__c);
    System.assertEquals(toMotor.Id, upgrade.To_Product__c);
    System.assertNotEquals(null, upgrade.Id);
    System.assertEquals(1200, upgrade.Price__c);
    System.assertEquals(null, no_price);
    System.assertEquals(null, word_price);
    System.assertEquals(null, no_from);
    System.assertEquals(null, no_to);
  }

  testMethod static void updatePriceTest() {
    InventoryTestFactory factory = new InventoryTestFactory();
    Product_Upgrade__c pu = factory.buildProductUpgrade();
    insert pu;

    Test.startTest();
    Product_Upgrade__c success_edited = BoatRemoter.updatePrice(pu.Id, '1500');
    Product_Upgrade__c failed_edited = BoatRemoter.updatePrice(pu.Id, 'not a number');
    Test.stopTest();

    System.assertEquals(1500, success_edited.Price__c);
    System.assertEquals(null, failed_edited);
  }

  testMethod static void newProductUpgradeCostTest()
  {
    Test.startTest();
    InventoryTestFactory factory = new InventoryTestFactory();
    Product_Upgrade__c pu = factory.buildProductUpgrade();
    insert pu;
    Pricebook2 stdPB = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
    Product_Upgrade_Cost__c holder = new Product_Upgrade_Cost__c(
      Product_Upgrade__c = pu.Id,
      Price_Book__c = stdPB.Id,
      Cost__c = 300
    );
    Product_Upgrade_Cost__c returned = BoatRemoter.newProductUpgradeCost(JSON.serialize(holder) );
    Test.stopTest();

    System.assert(holder.Product_Upgrade__c == returned.Product_Upgrade__c);
  }

  testMethod static void updateCostTest()
  {
    InventoryTestFactory factory = new InventoryTestFactory();
    Product_Upgrade_Cost__c puc = factory.buildUpgradeAndCostForStdPB();
    insert puc;
    System.assertEquals(100, puc.Cost__c);
    puc.Cost__c = 200;
    Product_Upgrade_Cost__c returned = BoatRemoter.updateCost( JSON.serialize(puc) );
    Product_Upgrade_Cost__c updated = [SELECT Id, Cost__c
                                       FROM Product_Upgrade_Cost__c
                                       WHERE Id = : puc.Id];
    System.assertEquals(200, returned.Cost__c);
    System.assertEquals(200, updated.Cost__c);
  }

  //************** Test for Product Options *************//

  testMethod static void editOptionDetailsTest() {
    InventoryTestFactory factory = new InventoryTestFactory();
    Product2 boat = factory.buildTestBoat();
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert boat;
    gcProduct.disableTrigger = orig;
    Product_Option__c po = factory.buildPartOptions(boat, 1, 'Accessory')[0];
    insert po;

    Test.startTest();
    Product_Option__c remote_po = BoatRemoter.editOptionDetails(po.Id);
    Product_Option__c failed_remote_po = BoatRemoter.editOptionDetails(null);
    Test.stopTest();

    System.assertEquals(remote_po.Id, po.Id);
    System.assertEquals(null, failed_remote_po);

  }

  testmethod static void updateOptionDetailsTest() {
    InventoryTestFactory factory = new InventoryTestFactory();
    Product2 boat = factory.buildTestBoat();
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert boat;
    gcProduct.disableTrigger = orig;
    Product_Option__c po = factory.buildPartOptions(boat, 1, 'Accessory')[0];
    insert po;

    Test.startTest();
    Product_Option__c po2 = BoatRemoter.updateOptionDetails('Id=' + po.Id + '&Standard__c=2&Maximum__c=7');
    Test.stopTest();

    System.assertNotEquals(null, po2);
    System.assertEquals(2, po2.Standard__c);
    System.assertEquals(7, po2.Maximum__c);

  }

  @isTest
  private static void setMaximumMotor_Test() {
    BoatTestFactory factory = new BoatTestFactory();
    Test.startTest();
    Product2 boat = factory.insertFullTestBoats(1, 'Pontoon')[0];
    Product_Option__c origMaxMotor = [SELECT Id
                                      FROM Product_Option__c
                                      WHERE isBiggestMotor__c = true
                                      AND To_Product__c = :boat.Id];
    List<Product_Option__c> motorOptions = [ SELECT Id
                                             FROM Product_Option__c
                                             WHERE To_Product__c = :boat.Id
                                             AND From_Product_Record_Type__c = 'Motor'
                                             AND isBiggestMotor__c = false];

    System.debug('&&&&&&&&&&&&&&&&&&&&&&&& ' + origMaxMotor);
    System.debug('&&&&&&&&&&&&&&&&&&&&&&&& ' + motorOptions);

    Product_Option__c newMaxMotor = BoatRemoter.setMaximumMotor( motorOptions[0].Id );
    Product_Option__c afterMotor = [SELECT Id FROM Product_Option__c WHERE isBiggestMotor__c = true AND To_Product__c = :boat.Id];
    Test.stopTest();
    System.assertEquals(newMaxMotor.id, afterMotor.Id);

  }

  //*************** Test for Features *****************//

	testMethod static void featureCreateTest() {
    Test.startTest();
      Feature__c feature = BoatRemoter.createNewFeature('Test Feature');
    Test.stopTest();

    System.assertEquals([SELECT Id, description__c FROM Feature__c WHERE Id = :feature.Id], feature);
	}

}