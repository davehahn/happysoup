/**
 * Created by dave on 2022-05-26.
 */

@IsTest
private class Product_ActivePrices_Controller_T
{

  private static Product2 p;
  private static final Decimal PRICE = 100;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void initData() {
    p = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    Factory_PricebookEntry.createAllDefaultEntriesEntries( p.Id, PRICE);
  }


  @IsTest
  static void getCurrentPricing()
  {
    initData();

    Test.startTest();
    Product_ActivePrices_Controller.ActivePricesWrapper result = Product_ActivePrices_Controller.getCurrentPricing(p.Id);
    Test.stopTest();

    System.assertEquals(PRICE, result.retail.price );
    System.assertEquals(PRICE, result.partner.price );
    System.assertEquals(PRICE, result.factory.price );
  }
}