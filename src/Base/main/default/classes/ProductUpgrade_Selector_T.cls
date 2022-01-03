/**
 * Created by dave on 2020-05-12.
 */

@IsTest
private class ProductUpgrade_Selector_T
{
  static Product2[] standardProducts;
  static Product2[] upgradeProducts;
  static Product_Upgrade__c[] upgrades;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void initData()
  {
    standardProducts = Factory_Product.createSerializedProducts(
      'Motor',
      'Remote',
      4
    );
    upgradeProducts = Factory_Product.createNonSerializedProducts(
      'Part',
      'Hardware',
      10
    );
    upgrades = new List<Product_Upgrade__c>();
    for( Product2 pp : standardProducts )
    {
      for( Product2 part : upgradeProducts )
      {
        upgrades.add( new Product_Upgrade__c(
          From_Product__c = pp.Id,
          To_Product__c = part.Id
        ));
      }
    }
    insert upgrades;
    List<Product_Upgrade_Cost__c> upgradeCosts = new List<Product_Upgrade_Cost__c>();
    for( Product_Upgrade__c pu : upgrades )
    {
      upgradeCosts.add( new Product_Upgrade_Cost__c(
        Product_Upgrade__c = pu.Id,
        Price_Book__c = LGND_Constants.retailPricebookId,
        Cost__c = 1000
      ));
    }
    insert upgradeCosts;
  }

  @IsTest
  static void allUpgradesByStandardIdsWithRetailCost_Test()
  {
    initData();
    Set<Id> standardIds = new Set<Id>{
      standardProducts[0].Id,
      standardProducts[1].Id
    };
    Set<Id> upgradeIds = new Set<Id>{
      upgradeProducts[0].Id,
      upgradeProducts[1].Id,
      upgradeProducts[3].Id
    };

    Test.startTest();
    List<Product_Upgrade__c> result =
      ProductUpgrade_selector.allUpgradesByStandardIdsWithRetailCost(
        standardIds, upgradeIds
      );
    Test.stopTest();

    System.assertEquals( 6, result.size() );
    System.assertEquals( 1, result[0].Product_Upgrade_Costs__r.size() );
    System.assertEquals( 1000, result[0].Product_Upgrade_Costs__r[0].Cost__c );
  }

}