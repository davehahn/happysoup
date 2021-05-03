@isTest
private class UpgradeChart_Test {

	@isTest static void cellTest() {
         /* disable the Gimbal Trigger handler gtProduct.trigger
       until Gimbals code gets deployed, this needs to be commented out for production */
    gcProduct.disableTrigger = true;
    InventoryTestFactory factory = new InventoryTestFactory();

    List<Product2> motors = factory.buildTestProducts(6, 'Motor');
    insert motors;

    List<Product_Upgrade__c> pus = new List<Product_Upgrade__c>();
    Decimal price = 100;
    for(Integer i=1; i<4; i++){
      Product_Upgrade__c pu = factory.buildProductUpgrade(motors[0].Id, motors[i].Id, price);
      pus.add(pu);
      price += 100;
    }
    insert pus;
    Product2 origMotor = [SELECT Id, (SELECT Id, Price__c, From_Product__c, To_Product__c FROM From_Product_Upgrades__r) FROM Product2 WHERE Id = : motors[0].Id];

    test.startTest();
    UpgradeChart uc = new UpgradeChart();
    uc.FromObj = origMotor;
    uc.to_Id = motors[0].id;
    //Should return an empty Product_Upgrade__c object
    Product_Upgrade__c resp1 = uc.getProductUpgradeCost();
    uc.to_Id = motors[1].id;
    //Should return a Product_Upgrade__c object with price = 100
    Product_Upgrade__c resp2 = uc.getProductUpgradeCost();
    uc.FromObj = [SELECT Id, (SELECT Id, Price__c, From_Product__c, To_Product__c FROM From_Product_Upgrades__r) FROM Product2 WHERE Id = : motors[5].Id];
    uc.to_Id = motors[3].Id;
    //Should return an empty Product_Upgrade__c object
    Product_Upgrade__c resp3 = uc.getProductUpgradeCost();
    test.stopTest();

    System.assertEquals(null, resp1.Id);
    System.assertEquals(100, resp2.Price__c);
    System.assertEquals(null, resp3.Id);
	}



}