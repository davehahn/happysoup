/**
 * Created by dave on 2023-02-01.
 */

@IsTest
private class Test_ProductTransfer
{
  static Schema.Location sourceLocation;
  static Schema.Location destinationLocation;
  static List<Product2> parts;
  static final Integer INVENTORY_START = 10;
  static final Integer QUANTITY_REQUIRED = 1;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void createLocations(){
    sourceLocation = new Schema.Location(
      LocationType = 'Warehouse',
      IsInventoryLocation = true,
      Name = 'Source Location',
      Description = 'Unit Test Source Location'
    );
    insert sourceLocation;
    destinationLocation = new Schema.Location(
      LocationType = 'Warehouse',
      IsInventoryLocation = true,
      Name = 'Destination Location',
      Description = 'Unit Test Destination Location'
    );
    insert destinationLocation;
  }

  private static void createProductItems( Boolean includeDestinationLocation){
    List<ProductItem> productItems = new List<ProductItem>();
    for (Product2 p : parts)
    {
      productItems.add(
        new ProductItem(
          LocationId = sourceLocation.Id,
          Product2Id = p.Id,
          QuantityOnHand = INVENTORY_START,
          QuantityUnitOfMeasure = 'Each'
        )
      );
      if (includeDestinationLocation)
      {
        productItems.add(
          new ProductItem(
            LocationId = destinationLocation.Id,
            Product2Id = p.Id,
            QuantityOnHand = 0,
            QuantityUnitOfMeasure = 'Each'
          )
        );
      }
    }
    insert productItems;
  }


  private static void init(Boolean includeDestinationLocation)
  {
    createLocations();
    parts = Factory_Product.createNonSerializedProducts('Part', 'Electronics', 10);
    createProductItems(includeDestinationLocation);
  }

  @IsTest
  static void withoutDestinationProductItem_WillPass()
  {
    init(false);
    Product2 part = parts[0];

    ProductTransfer pt = new ProductTransfer(
      DestinationLocationId = destinationLocation.Id,
      SourceLocationId = sourceLocation.Id,
      Product2Id = part.Id,
      QuantitySent = QUANTITY_REQUIRED,
      QuantityReceived = QUANTITY_REQUIRED,
      QuantityUnitOfMeasure = 'Each',
      IsReceived = true
    );

    Test.startTest();
    insert pt;
    Test.stopTest();

    ProductItem[] pis = [
      SELECT Id, QuantityOnHand, LocationId
      FROM ProductItem
      WHERE Product2Id = :part.Id AND LocationId IN :new Set<Id>
      {
        sourceLocation.Id, destinationLocation.Id
      }
    ];

    System.assertEquals(2, pis.size());

    for (ProductItem pi : pis)
    {
      if (pi.LocationId == destinationLocation.Id)
      {
        System.assertEquals(QUANTITY_REQUIRED, pi.QuantityOnHand);
      }
      if (pi.LocationId == sourceLocation.Id)
      {
        System.assertEquals(INVENTORY_START - QUANTITY_REQUIRED, pi.QuantityOnHand);
      }
    }
  }

  @IsTest
  static void withDestinationProductItem_WillFail()
  {
    init(true);
    Product2 part = parts[0];

    ProductTransfer pt = new ProductTransfer(
      DestinationLocationId = destinationLocation.Id,
      SourceLocationId = sourceLocation.Id,
      Product2Id = part.Id,
      QuantitySent = QUANTITY_REQUIRED,
      QuantityReceived = QUANTITY_REQUIRED,
      QuantityUnitOfMeasure = 'Each',
      IsReceived = true
    );

    Test.startTest();
    insert pt;
    Test.stopTest();

    ProductItem[] pis = [
      SELECT Id, QuantityOnHand, LocationId
      FROM ProductItem
      WHERE Product2Id = :part.Id AND LocationId IN :new Set<Id>
      {
        sourceLocation.Id, destinationLocation.Id
      }
    ];

    System.assertEquals(2, pis.size());

    for (ProductItem pi : pis)
    {
      if (pi.LocationId == destinationLocation.Id)
      {
        System.assertEquals(QUANTITY_REQUIRED, pi.QuantityOnHand);
      }
      if (pi.LocationId == sourceLocation.Id)
      {
        System.assertEquals(INVENTORY_START - QUANTITY_REQUIRED, pi.QuantityOnHand);
      }
    }
  }

  @IsTest
  static void withoutDestinationProductItemTwoTransfers_WillFail()
  {
    init(false);
    Product2 part = parts[0];

    ProductTransfer pt = new ProductTransfer(
      DestinationLocationId = destinationLocation.Id,
      SourceLocationId = sourceLocation.Id,
      Product2Id = part.Id,
      QuantitySent = QUANTITY_REQUIRED,
      QuantityReceived = QUANTITY_REQUIRED,
      QuantityUnitOfMeasure = 'Each',
      IsReceived = true
    );

    Test.startTest();
    insert pt;
    Test.stopTest();

    ProductItem[] pis = [
      SELECT Id, QuantityOnHand, LocationId
      FROM ProductItem
      WHERE Product2Id = :part.Id AND LocationId IN :new Set<Id>
      {
        sourceLocation.Id, destinationLocation.Id
      }
    ];

    System.assertEquals(2, pis.size());

    for (ProductItem pi : pis)
    {
      if (pi.LocationId == destinationLocation.Id)
      {
        System.assertEquals(QUANTITY_REQUIRED, pi.QuantityOnHand);
      }
      if (pi.LocationId == sourceLocation.Id)
      {
        System.assertEquals(INVENTORY_START - QUANTITY_REQUIRED, pi.QuantityOnHand);
      }
    }

    ProductTransfer pt2 = new ProductTransfer(
      DestinationLocationId = destinationLocation.Id,
      SourceLocationId = sourceLocation.Id,
      Product2Id = part.Id,
      QuantitySent = QUANTITY_REQUIRED,
      QuantityReceived = QUANTITY_REQUIRED,
      QuantityUnitOfMeasure = 'Each',
      IsReceived = true
    );

    insert pt2;

    System.assertEquals(2, pis.size());

    for (ProductItem pi : pis)
    {
      if (pi.LocationId == destinationLocation.Id)
      {
        System.assertEquals(QUANTITY_REQUIRED, pi.QuantityOnHand);
      }
      if (pi.LocationId == sourceLocation.Id)
      {
        System.assertEquals(INVENTORY_START - QUANTITY_REQUIRED, pi.QuantityOnHand);
      }
    }
  }
}