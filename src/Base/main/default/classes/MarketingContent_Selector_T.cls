/**
 * Created by dave on 2020-05-12.
 */

@IsTest
private class MarketingContent_Selector_T
{

  static Product2[] products;
  static Product2[] optionalProducts;
  static Id productOptionId;
  static Id productId;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void initData()
  {
    products = Factory_Product.createSerializedProducts(
      'Boat',
      'Full Windshield',
      5
    );
    optionalProducts = Factory_Product.createNonSerializedProducts(
      'Part',
      'Electronics',
      10
    );
    productId = products[0].Id;
    Product_Option__c po = new Product_Option__c(
      To_Product__c = productId,
      From_Product__c = optionalProducts[0].Id,
      Standard__c = 0,
      Maximum__c = 1,
      Available_Online__c = true
    );
    insert po;
    productOptionId = po.Id;
    Marketing_Content__c[] mContents = new List<Marketing_Content__c>();
    mContents.add( new Marketing_Content__c(
      Product_Option__c = productOptionId,
      Label__c = 'Product Option',
      Content__c = 'This is a Product Options Marketing Content'
    ));
    mContents.add( new Marketing_Content__c(
      Product__c = productId,
      Label__c = 'Product',
      Content__c = 'This is a Product Marketing Content'
    ));
    insert mContents;
  }

  @IsTest
  static void allByProductAndProductOption_Test()
  {
    initData();
    Set<Id> ids = new Set<Id>{
      productId,
      productOptionId
    };

    Test.startTest();
    List<Marketing_Content__c> result =
      MarketingContent_Selector.allByProductAndProductOption( ids );
    Test.stopTest();

    System.assertEquals( 2, result.size() );
  }
}