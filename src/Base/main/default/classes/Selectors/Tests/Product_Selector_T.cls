/**
 * Created by dave on 2020-04-29.
 */

@IsTest
private class Product_Selector_T {
  static Product2[] onlineBoats;
  static Product2[] notOnlineBoats;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void initData() {
    onlineBoats = Factory_Product.createSerializedProducts_AvailableOnline('Boat', 'Pontoon', 5);
    notOnlineBoats = Factory_Product.createSerializedProducts('Boat', 'Pontoon', 5);
  }

  @IsTest
  static void allBoatsAvailableForOnlineSale() {
    initData();
    Test.startTest();
    List<Product2> result = Product_Selector.allBoatsAvailableForOnlineSale();
    Test.stopTest();

    System.assertEquals(5, result.size(), 'There should be 5 boats available for online sale');
  }

  @IsTest
  static void getOnlineBoat_Pass_Test() {
    initData();
    Test.startTest();
    Product2 result = Product_Selector.getOnlineBoat(onlineBoats[0].Id);
    Test.stopTest();

    System.assertEquals(onlineBoats[0].Id, result.Id, 'Should return a Product');
  }

  @IsTest
  static void allWithFullDetailsById_Test() {
    initData();
    Set<Id> prodIds = new Set<Id>();
    for (Product2 p : onlineBoats) {
      prodIds.add(p.Id);
    }
    for (Product2 p : notOnlineBoats) {
      prodIds.add(p.Id);
    }

    Test.startTest();
    List<Product2> result = Product_Selector.allWithFullDetailsById(prodIds);
    Test.stopTest();

    Integer count = onlineBoats.size() + notOnlineBoats.size();

    System.assertEquals(count, result.size(), 'should return ' + String.valueOf(count) + 'records');
  }

  @IsTest
  static void getOnlineBoat_Fail_Test() {
    initData();
    Test.startTest();
    Product2 result = Product_Selector.getOnlineBoat(notOnlineBoats[0].Id);
    Test.stopTest();

    System.assert(result == null, 'NULL should be returned');
  }
}
