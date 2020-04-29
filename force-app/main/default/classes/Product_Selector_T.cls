/**
 * Created by dave on 2020-04-29.
 */

@IsTest
private class Product_Selector_T
{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Factory_Product.createSerializedProducts_AvailableOnline( 'Boat', 'Pontoon', 5 );
  }

  @IsTest
  static void allBoatsAvailableForOnlineSale()
  {
    Test.startTest();
    List<Product2> result = Product_Selector.allBoatsAvailableForOnlineSale();
    Test.stopTest();

    System.assertEquals( 5, result.size(), 'There should be 5 boats available for online sale');
  }
}