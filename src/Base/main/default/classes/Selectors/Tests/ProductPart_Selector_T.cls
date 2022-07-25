/**
 * Created by dave on 2020-05-12.
 */

@IsTest
private class ProductPart_Selector_T {
  static Product2[] parentProducts;
  static Product2[] parts;
  static AcctSeed__Product_Part__c[] productParts;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void initData() {
    parentProducts = Factory_Product.createNonSerializedProducts('Part', 'Hardware', 4);
    parts = Factory_Product.createNonSerializedProducts('Part', 'Hardware', 10);
    productParts = new List<AcctSeed__Product_Part__c>();
    for (Product2 pp : parentProducts) {
      for (Product2 part : parts) {
        productParts.add(
          new AcctSeed__Product_Part__c(
            AcctSeed__Product__c = pp.Id,
            AcctSeed__Product_Part__c = part.Id,
            AcctSeed__Quantity__c = 1
          )
        );
      }
    }
    insert productParts;
  }

  @IsTest
  static void allForPartKitsByParentIds_Test() {
    initData();
    Set<Id> parentIds = new Set<Id>{ parentProducts[0].Id, parentProducts[1].Id };

    Test.startTest();
    AcctSeed__Product_Part__c[] result = ProductPart_Selector.allForPartKitsByParentIds(parentIds);
    Test.stopTest();

    System.assertEquals(20, result.size());
  }
}
