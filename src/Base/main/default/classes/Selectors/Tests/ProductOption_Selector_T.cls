/**
 * Created by dave on 2020-05-12.
 */

@IsTest
private class ProductOption_Selector_T {
  static Product2[] parentProducts;
  static Product2[] optionalProducts;
  static Product_Option__c[] options;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void initData() {
    parentProducts = Factory_Product.createSerializedProducts('Boat', 'Full Windshield', 4);
    optionalProducts = Factory_Product.createNonSerializedProducts('Part', 'Hardware', 10);
    options = new List<Product_Option__c>();
    for (Product2 pp : parentProducts) {
      options.addAll(Factory_ProductOption.buildProductOptions(pp.Id, optionalProducts, 0, 1));
    }
    insert options;
  }

  @IsTest
  static void allChildOptions_AvailableOnline_Fail_Test() {
    initData();
    Set<Id> parentIds = new Set<Id>{ parentProducts[0].Id, parentProducts[1].Id };

    Test.startTest();
    List<Product_Option__c> result = ProductOption_Selector.allChildOptions_AvailableOnline(parentIds);
    Test.stopTest();

    System.assertEquals(0, result.size());
  }

  @IsTest
  static void allChildOptions_AvailableOnline_Pass_Test() {
    initData();
    Set<Id> parentIds = new Set<Id>{ parentProducts[0].Id, parentProducts[1].Id };
    Integer count1 = 0;
    Integer count2 = 0;

    for (Product_Option__c po : options) {
      if (po.To_Product__c == parentProducts[0].Id && count1 < 5) {
        po.Available_Online__c = true;
        count1++;
      }
      if (po.To_Product__c == parentProducts[1].Id && count2 < 5) {
        po.Available_Online__c = true;
        count2++;
      }
    }
    update options;

    Test.startTest();
    List<Product_Option__c> result = ProductOption_Selector.allChildOptions_AvailableOnline(parentIds);
    Test.stopTest();

    System.assertEquals(10, result.size());
  }
}
