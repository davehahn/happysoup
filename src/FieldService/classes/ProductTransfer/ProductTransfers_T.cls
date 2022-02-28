/**
 * Created by dave on 2020-11-16.
 */

@IsTest
private class ProductTransfers_T
{
  private static final String warehouseName = 'Wholesale';
  private static final Integer inventoryQuantityStart = 10;

  private static AcctSeedERP__Warehouse__c warehouse;
  private static List<Product2> products;
  private static List<Schema.Location> locations;
  private static ProductItem sourceProductItem;

  @testSetup static void dataSetup()
  {
    Factory_TestData factory = new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    AcctSeedERP__Warehouse__c wh = factory.warehouses.get( warehouseName );
    Schema.Location wholeSale_site = factory.warehouse2fslSiteMap.get( wh.Id );
    Schema.Location staging = Factory_Location.buildPickAndPack(
      'Pick and Pack',
      wholeSale_site
    );
    insert staging;
  }

  private static void createData( Boolean createSourceProductItem )
  {
    products = Factory_Product.createNonSerializedProducts('Part', 'Electronics', 2);
    String nameString = '%' + warehouseName + '%';
    warehouse = [
      SELECT
        Id,
        Name
      FROM AcctSeedERP__Warehouse__c
      WHERE Name LIKE :nameString
    ];
    Schema.Location site = [
      SELECT
        Id
      FROM Location
      WHERE Name LIKE :nameString
      AND LocationType = 'Site'
    ];
    locations = [
      SELECT
        Id
      FROM Location
      WHERE ParentLocationId = :site.Id
    ];
    if( createSourceProductItem )
    {
      sourceProductItem = new ProductItem(
        Product2Id = products[0].Id,
        LocationId = locations[0].Id,
        QuantityUnitOfMeasure = 'Each',
        QuantityOnHand = 10
      );
      insert sourceProductItem;
    }
  }

  @IsTest
  static void onInsert_T()
  {
    createData(true);
    ProductTransfer pt = new ProductTransfer(
      Product2Id = products[0].Id,
      SourceLocationId = locations[0].Id,
      DestinationLocationId = locations[1].Id,
      QuantitySent = 1,
      QuantityReceived = 1,
      QuantityUnitOfMeasure = 'Each',
      IsReceived = true
    );

    List<ProductItem> productItems_before = [
      SELECT
        Id,
        QuantityOnHand
      FROM ProductItem
      WHERE Product2Id = :products[0].Id
    ];

    Test.startTest();
    insert pt;
    Test.stopTest();

    List<ProductItem> productItems_after = [
      SELECT
        Id,
        QuantityOnHand
      FROM ProductItem
      WHERE Product2Id = :products[0].Id
    ];

    List<ProductItemTransaction> piTransactions = [
      SELECT
        Id,
        ProductItemId,
        Quantity,
        TransactionType
      FROM ProductItemTransaction
      WHERE RelatedRecordId = :pt.Id
    ];

    System.assertEquals( 1, productItems_before.size() );
    System.assertEquals( 2, productItems_after.size() );
    System.assertEquals( inventoryQuantityStart, productItems_before[0].QuantityOnHand );
    System.assertEquals( 1, productItems_after[1].QuantityOnHand );
    System.assertEquals( inventoryQuantityStart - 1 , productItems_after[0].QuantityOnHand );
    System.assertEquals( 2, piTransactions.size() );
  }

  @IsTest
  static void onInsert_noSourceProductItem_T()
  {
    createData(false);
    ProductTransfer pt = new ProductTransfer(
      Product2Id = products[0].Id,
      SourceLocationId = locations[0].Id,
      DestinationLocationId = locations[1].Id,
      QuantitySent = 1,
      QuantityReceived = 1,
      QuantityUnitOfMeasure = 'Each',
      IsReceived = true
    );

    String exMsg;
    Test.startTest();
    try
    {
      insert pt;
    }
    catch( Exception e )
    {
      exMsg = e.getMessage();
    }

    System.assert( exMsg != null );

  }
}