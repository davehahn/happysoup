/**
 * Created by dave on 2023-02-01.
 */

@IsTest
private class Test_ProductTransfer
{
  static Schema.Location sourceLocation;
  static Schema.Location sourceLocation2;
  static Schema.Location sourceLocation3;
  static Schema.Location destinationLocation;
  static Schema.Location destinationLocation2;
  static Schema.Location destinationLocation3;
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
    sourceLocation2 = new Schema.Location(
      LocationType = 'Warehouse',
      IsInventoryLocation = true,
      Name = 'Source Location',
      Description = 'Unit Test Source Location'
    );
    insert sourceLocation2;
    sourceLocation3 = new Schema.Location(
      LocationType = 'Warehouse',
      IsInventoryLocation = true,
      Name = 'Source Location',
      Description = 'Unit Test Source Location'
    );
    insert sourceLocation3;
    destinationLocation = new Schema.Location(
      LocationType = 'Warehouse',
      IsInventoryLocation = true,
      Name = 'Destination Location',
      Description = 'Unit Test Destination Location'
    );
    insert destinationLocation;
    destinationLocation2 = new Schema.Location(
      LocationType = 'Warehouse',
      IsInventoryLocation = true,
      Name = 'Destination Location',
      Description = 'Unit Test Destination Location'
    );
    insert destinationLocation2;
    destinationLocation3 = new Schema.Location(
      LocationType = 'Warehouse',
      IsInventoryLocation = true,
      Name = 'Destination Location',
      Description = 'Unit Test Destination Location'
    );
    insert destinationLocation3;
  }

  private static void createProductItems( Id sourceLocationId, Id destinationLocationId){
    List<ProductItem> productItems = new List<ProductItem>();
    for (Product2 p : parts)
    {
      productItems.add(
        new ProductItem(
          LocationId = sourceLocationId,
          Product2Id = p.Id,
          QuantityOnHand = INVENTORY_START,
          QuantityUnitOfMeasure = 'Each'
        )
      );
      if (destinationLocationId != null )
      {
        productItems.add(
          new ProductItem(
            LocationId = destinationLocationId,
            Product2Id = p.Id,
            QuantityOnHand = 0,
            QuantityUnitOfMeasure = 'Each'
          )
        );
      }
    }
    insert productItems;
  }


  private static void init(Id sourceLocationId, Id destinationLocationId )
  {
    parts = Factory_Product.createNonSerializedProducts('Part', 'Electronics', 10);
    createProductItems(sourceLocationId, destinationLocationId);
  }

  @IsTest
  static void withoutDestinationProductItem_WillPass()
  {
    createLocations();
    init(sourceLocation.Id, null);
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
    createLocations();
    init(sourceLocation2.Id, destinationLocation2.Id);
    Product2 part = parts[0];

    ProductTransfer pt = new ProductTransfer(
      DestinationLocationId = destinationLocation2.Id,
      SourceLocationId = sourceLocation2.Id,
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
        sourceLocation2.Id, destinationLocation2.Id
      }
    ];

    System.assertEquals(1, pis.size());

    for (ProductItem pi : pis)
    {
      if (pi.LocationId == destinationLocation2.Id)
      {
        System.assertEquals(QUANTITY_REQUIRED, pi.QuantityOnHand);
      }
      if (pi.LocationId == sourceLocation2.Id)
      {
        System.assertEquals(INVENTORY_START - QUANTITY_REQUIRED, pi.QuantityOnHand);
      }
    }
  }

  @IsTest
  static void withoutDestinationProductItemTwoTransfers_WillFail()
  {
    createLocations();
    init(sourceLocation3.Id, null);
    Product2 part = parts[0];

    ProductTransfer pt = new ProductTransfer(
      DestinationLocationId = destinationLocation3.Id,
      SourceLocationId = sourceLocation3.Id,
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
        sourceLocation3.Id, destinationLocation3.Id
      }
    ];

    System.assertEquals(1, pis.size());

    for (ProductItem pi : pis)
    {
      if (pi.LocationId == destinationLocation3.Id)
      {
        System.assertEquals(QUANTITY_REQUIRED, pi.QuantityOnHand);
      }
      if (pi.LocationId == sourceLocation3.Id)
      {
        System.assertEquals(INVENTORY_START - QUANTITY_REQUIRED, pi.QuantityOnHand);
      }
    }

    ProductTransfer pt2 = new ProductTransfer(
      DestinationLocationId = destinationLocation3.Id,
      SourceLocationId = sourceLocation3.Id,
      Product2Id = part.Id,
      QuantitySent = QUANTITY_REQUIRED,
      QuantityReceived = QUANTITY_REQUIRED,
      QuantityUnitOfMeasure = 'Each',
      IsReceived = true
    );

    insert pt2;

    System.assertEquals(1, pis.size());

    for (ProductItem pi : pis)
    {
      if (pi.LocationId == destinationLocation3.Id)
      {
        System.assertEquals(QUANTITY_REQUIRED, pi.QuantityOnHand);
      }
      if (pi.LocationId == sourceLocation3.Id)
      {
        System.assertEquals(INVENTORY_START - QUANTITY_REQUIRED, pi.QuantityOnHand);
      }
    }
  }
}