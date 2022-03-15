/**
 * Created by dave on 2020-11-11.
 */

@IsTest
private class ProductTransferTool_Controller_T
{
  private static final String warehouseName = 'Wholesale';
  private static final Integer inventoryQuantityStart = 10;

  private static AcctSeedERP__Warehouse__c warehouse;
  private static Schema.Location warehouseLocation;
  private static Schema.Location woPickAndPackLocation;
  private static WorkOrder workOrder;
  private static WorkOrderLineItem woli;
  private static List<ProductRequired> requiredProducts;

  @testSetup static void dataSetup()
  {
    Factory_TestData factory = new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    AcctSeedERP__Warehouse__c wholesale_wh = factory.warehouses.get( warehouseName );
    System.debug( wholesale_wh );
    System.debug( factory.warehouse2fslSiteMap );
    Schema.Location wholeSale_site = factory.warehouse2fslSiteMap.get( wholesale_wh.Id );
    List<Schema.Location> locations = new List<schema.Location>();
    locations.add( Factory_Location.buildPickAndPack(
       'Pick and Pack',
      wholeSale_site
    ));
    locations.addAll( Factory_Location.buildEmployees(
      wholesale_wh.Name,
      wholeSale_site,
      8
    ));
    insert locations;
    User u = Factory_User.newUser(
      'FFF',
      'LLL',
      'System Administrator',
      wholesale_wh
    );
    u.GL_Account_Variable_1__c = null;
    insert u;
  }

  private static User findUser()
  {
    return  [SELECT Id FROM User WHERE FirstName = 'FFF' AND LastName = 'LLL'];
  }

  private static void findWarehouse()
  {
    String nameString = '%' + warehouseName + '%';
    warehouse = [ SELECT Id, Name FROM AcctSeedERP__Warehouse__c WHERE Name LIKE :nameString ];
  }

  private static void findLocations()
  {
    warehouseLocation = [
      SELECT
        Id,
        ParentLocationId
      FROM Location
      WHERE Warehouse__c = :warehouse.Id
    ];
    woPickAndPackLocation = [
      SELECT
        Id
      FROM Location
      WHERE ParentLocationId = :warehouseLocation.ParentLocationId
      AND Id <> :warehouseLocation.Id
      AND LocationType = 'Pick and Pack'
    ];
  }

  private static void buildWorkOrderData( Integer partsCount)
  {
    Id pbId = LGND_Constants.retailPricebookId;
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial(
      'Boat',
      'Pontoon',
      'TEST1234SERIAL'
    );
    workOrder = Factory_WorkOrder.buildNew( null, pbId );
    workOrder.LocationId = warehouseLocation.Id;
    workOrder.RecordTypeId = new Application_RecordType().getWorkOrderRecordTypes().getManufacturingId();
    workOrder.Serial_Number__c = serial.Id;
    insert workOrder;
    System.debug('workOrder 1');
    System.debug(workOrder);
    woli = Factory_WorkOrder.createLineItems(
      workOrder.id,
      1
    )[0];
    System.debug('woli 1');
    System.debug(woli);

    Product2[] parts = Factory_Product.createNonSerializedProducts(
      'Part',
      'Electronics',
      partsCount
    );
    requiredProducts = new List<ProductRequired>();
    List<ProductItem> productItems = new List<ProductItem>();
    for( Product2 p : parts )
    {
      requiredProducts.add( new ProductRequired(
        ParentRecordId = woli.Id,
        Product2Id = p.Id,
        QuantityRequired = 1
      ));
      productItems.add( new ProductItem(
        LocationId = warehouseLocation.Id,
        Product2Id = p.Id,
        QuantityOnHand = inventoryQuantityStart
      ) );
      productItems.add( new ProductItem(
        LocationId = woPickAndPackLocation.Id,
        Product2Id = p.Id,
        QuantityOnHand = 0
      ) );
    }
    insert requiredProducts;
    insert productItems;
  }

  @IsTest
  static void getWorkOrderAndUserLocations_Test()
  {
    Integer partsCount = 2;
    findWarehouse();
    findLocations();
    buildWorkOrderData( partsCount );
    User u = findUser();
    System.runAs( u )
    {
      Test.startTest();
      ProductTransferTool_Controller.LocationWrapper result =
        ProductTransferTool_Controller.getWorkOrderAndUserLocations( workOrder.Id );
      Test.stopTest();
      System.debug(result);
      System.assert( result.userBaseLocation != null );
      System.assert( result.workOrderLocation != null );
      System.assert( result.workOrderPickAndPackLocation != null );
    }
  }

  @IsTest
  static void fetchRequiredProductsForPickAndPack_Test()
  {
    Integer partsCount = 10;
    findWarehouse();
    findLocations();
    buildWorkOrderData( partsCount );

    Map<String, String> params = new Map<String, String>{
      'workOrderId' => String.valueOf( workOrder.Id ),
      'sourceLocationId' => String.valueOf( warehouseLocation.Id ),
      'destinationLocationId' => String.valueOf( woPickAndPackLocation.Id )
    };

    Test.startTest();
      List<ProductTransferTool_Controller.TransferWrapper> result = ProductTransferTool_Controller.fetchRequiredProducts(
        JSON.serialize( params )
      );
    Test.stopTest();
    System.assertEquals( partsCount, result.size() );

  }

  @IsTest
  static void transferSingle_Test()
  {
    Integer partsCount = 10;
    findWarehouse();
    findLocations();
    buildWorkOrderData( partsCount );
    ProductRequired pr = [
      SELECT
        Id,
        ParentRecordId,
        Product2Id,
        Product2.Name,
        Product2.ProductCode,
        QuantityRequired,
        QuantityUnitOfMeasure
      FROM ProductRequired
      WHERE Id = :requiredProducts[0].Id
    ];
    System.debug('pr');
    System.debug(pr);
    ProductItem sourceItem = [
      SELECT
        Id,
        LocationId,
        QuantityOnHand
      FROM ProductItem
      WHERE Product2Id = :pr.Product2Id
      AND LocationId = :warehouseLocation.Id
    ];
    ProductItem destinationItem = [
      SELECT
        Id,
        LocationId,
        QuantityOnHand
      FROM ProductItem
      WHERE Product2Id = :pr.Product2Id
      AND LocationId = :woPickAndPackLocation.Id
    ];
    System.debug( 'sourceItem');
    System.debug( sourceItem);
    System.debug('destinationItem');
    System.debug(destinationItem);
    ProductTransferTool_Controller.TransferWrapper wrapper =
      new ProductTransferTool_Controller.TransferWrapper(
        pr,
        sourceItem,
        destinationItem
      );
    wrapper.quantityTransferred = wrapper.quantityRequired;
  System.debug('wrapper');
  System.debug(wrapper);
    Test.startTest();
    ProductTransferTool_Controller.transferSingle(  wrapper );
    Test.stopTest();

    ProductItem[] pis = [
      SELECT
        Id,
        QuantityOnHand,
        LocationId
      FROM ProductItem
      WHERE Product2Id = :pr.Product2Id
      AND LocationId IN :new Set<Id>{ woPickAndPackLocation.Id, warehouseLocation.Id}
    ];

    System.assertEquals( 2, pis.size() );

    for( ProductItem pi : pis )
    {
      if( pi.LocationId == woPickAndPackLocation.Id )
      {
        System.assertEquals( 1,  pi.QuantityOnHand );
      }
      if( pi.LocationId == warehouseLocation.Id )
      {
        System.assertEquals( inventoryQuantityStart - 1,  pi.QuantityOnHand );
      }
    }

  }

//  @IsTest
//  static void transferSingle_NoSourceProductItem_Test()
//  {
//    Integer partsCount = 10;
//    findWarehouse();
//    findLocations();
//    buildWorkOrderData( partsCount );
//    ProductRequired pr = [
//      SELECT
//        Id,
//        ParentRecordId,
//        Product2Id,
//        Product2.Name,
//        Product2.ProductCode,
//        QuantityRequired,
//        QuantityUnitOfMeasure
//      FROM ProductRequired
//      WHERE Id = :requiredProducts[0].Id
//    ];
//    ProductItem sourceItem = [
//      SELECT
//        Id,
//        LocationId,
//        QuantityOnHand
//      FROM ProductItem
//      WHERE Product2Id = :pr.Product2Id
//      AND LocationId = :warehouseLocation.Id
//    ];
//    delete sourceItem;
//    sourceItem = new ProductItem(
//      LocationId = warehouseLocation.Id
//    );
//    ProductItem destinationItem = [
//      SELECT
//        Id,
//        LocationId,
//        QuantityOnHand
//      FROM ProductItem
//      WHERE Product2Id = :pr.Product2Id
//      AND LocationId = :woPickAndPackLocation.Id
//    ];
//    ProductTransferTool_Controller.TransferWrapper wrapper =
//      new ProductTransferTool_Controller.TransferWrapper(
//        pr,
//        sourceItem,
//        destinationItem
//      );
//    wrapper.quantityTransferred = wrapper.quantityRequired;
//
//    Test.startTest();
//    ProductTransferTool_Controller.transferSingle( wrapper );
//    Test.stopTest();
//
//    ProductItem[] pis = [
//      SELECT
//        Id,
//        QuantityOnHand,
//        LocationId
//      FROM ProductItem
//      WHERE Product2Id = :pr.Product2Id
//      AND LocationId IN :new Set<Id>{ woPickAndPackLocation.Id, warehouseLocation.Id}
//    ];
//
//    System.assertEquals( 2, pis.size() );
//
//    for( ProductItem pi : pis )
//    {
//      if( pi.LocationId == woPickAndPackLocation.Id )
//      {
//        System.assertEquals( 1,  pi.QuantityOnHand );
//      }
//      if( pi.LocationId == warehouseLocation.Id )
//      {
//        System.assertEquals( inventoryQuantityStart - 1,  pi.QuantityOnHand );
//      }
//    }
//
//  }

}