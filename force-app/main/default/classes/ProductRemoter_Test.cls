@isTest
private class ProductRemoter_Test {

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

	@isTest static void test_method_one() {
    InventoryTestFactory factory = new InventoryTestFactory();
    List<Product2> randomProducts = factory.insertTestProducts(6, 'Part');
    List<Product2> boatProducts = factory.insertTestProducts(2, 'Boat', 'Pontoon');
    Id pb2Id = Test.getStandardPricebookId();

    test.startTest();
    List<String> excludes = new List<String>{'Boat'};
    List<Productremoter.ProductWrapper> searchProducts = ProductRemoter.productSearch(pb2Id, 'InventoryTestxxx');
    List<Productremoter.ProductWrapper> searchProductsExcludesBoats = ProductRemoter.excludedProductSearch(pb2Id, 'InventoryTestxxx', excludes);
    Product2 selected = ProductRemoter.selectProduct(pb2Id, searchProducts[2].Id);
    test.stopTest();

    System.assertEquals(8, searchProducts.size() );
    System.assertEquals(6, searchProductsExcludesBoats.size() );
    System.assert( selected != null );

  }

}