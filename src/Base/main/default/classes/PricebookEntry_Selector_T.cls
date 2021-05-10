/**
 * Created by dave on 2020-05-12.
 */

@IsTest
private class PricebookEntry_Selector_T
{

  static Product2[] products;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void initData()
  {
    products = Factory_Product.createNonSerializedProducts(
      'Part',
      'Electronics',
      10
    );
    List<PricebookEntry> stdPBEntries =
      Factory_PricebookEntry.buildEntries(
        products,
        Test.getStandardPricebookId(),
        0
      );
    List<PricebookEntry> retailPBEntries =
      Factory_PricebookEntry.buildEntries(
        products,
        LGND_Constants.retailPricebookId,
        100
      );

    insert stdPBEntries;
    insert retailPBEntries;
  }

  @IsTest
  static void allRetailEntriesByProductId_Test()
  {
    initData();
    Set<Id> prodIds = new Set<Id>{
      products[0].Id,
      products[1].Id
    };

    Test.startTest();
    PricebookEntry[] result =
      PricebookEntry_Selector.allRetailEntriesByProductId( prodIds );
    Test.stopTest();

    System.assertEquals( 2, result.size() );
    System.assertEquals( 100, result[0].UnitPrice );
  }
}