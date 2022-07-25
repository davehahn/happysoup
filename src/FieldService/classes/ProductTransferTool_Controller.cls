/**
 * Created by dave on 2020-10-20.
 */

public with sharing class ProductTransferTool_Controller {
  public class TransferWrapper {
    @AuraEnabled
    public String id { get; set; }
    @AuraEnabled
    public String productRequiredId { get; set; }
    @AuraEnabled
    public String productId { get; set; }
    @AuraEnabled
    public String productName { get; set; }
    @AuraEnabled
    public String productCode { get; set; }
    @AuraEnabled
    public String aisle { get; set; }
    @AuraEnabled
    public String binNumber { get; set; }
    @AuraEnabled
    public String section { get; set; }
    @AuraEnabled
    public Decimal quantityRequired { get; set; }
    @AuraEnabled
    public Decimal quantityAvailable { get; set; }
    @AuraEnabled
    public Decimal quantityTransferred { get; set; }
    @AuraEnabled
    public String quantityUnitOfMeasure { get; set; }
    @AuraEnabled
    public String sourceLocationId { get; set; }
    @AuraEnabled
    public String destinationLocationId { get; set; }
    @AuraEnabled
    public String workOrderLineItemId { get; set; }
    //    public String workOrderId { get; set; }

    public TransferWrapper() {
    }

    public TransferWrapper(ProductItem pi, String destinationId) {
      this.id = LGND_Utilities.generateRandomString(10);
      this.sourceLocationId = pi.LocationId;
      this.destinationLocationId = destinationId;
      this.productId = pi.Product2Id;
      this.productName = pi.ProductName;
      this.productCode = pi.Product2.ProductCode;
      this.quantityAvailable = pi.QuantityOnHand;
      this.quantityTransferred = 0;
      this.quantityUnitOfMeasure = pi.QuantityUnitOfMeasure;
    }

    public TransferWrapper(ProductRequired pr, ProductItem sourceItem, ProductItem destinationItem) {
      this.id = LGND_Utilities.generateRandomString(10);
      this.sourceLocationId = sourceItem.LocationId;
      this.destinationLocationId = destinationItem.LocationId;
      //      if( pr.ParentRecordType == 'WorkOrderLineItem' )
      this.workOrderLineItemId = pr.ParentRecordId;
      //      if( pr.ParentRecordType == 'WorkOrder' )
      //        this.workOrderId = pr.ParentRecordId;
      this.productRequiredId = pr.Id;
      this.productId = pr.Product2Id;
      this.productName = pr.Product2.Name;
      this.productCode = pr.Product2.ProductCode;
      this.quantityRequired = pr.QuantityRequired - destinationItem.QuantityOnHand;
      this.quantityTransferred = 0;
      this.quantityAvailable = sourceItem.Id == null ? 0 : sourceItem.QuantityOnHand;
      this.quantityUnitOfMeasure = pr.QuantityUnitOfMeasure;
      this.binNumber = '--';
      this.section = '--';
      this.aisle = '--';
    }

    public ProductTransfer toProductTransfer() {
      return new ProductTransfer(
        DestinationLocationId = this.destinationLocationId,
        SourceLocationId = this.sourceLocationId,
        Work_Order_Line_Item__c = this.workOrderLineItemId,
        ProductRequired__c = this.productRequiredId,
        Product2Id = this.productId,
        QuantitySent = this.quantityTransferred,
        QuantityReceived = this.quantityTransferred,
        QuantityUnitOfMeasure = this.quantityUnitOfMeasure,
        IsReceived = true
      );
    }

    public TransferWrapper addBinLocation(Product_Bin_Location__c bin) {
      this.aisle = bin.Aisle__c == null ? '--' : bin.Aisle__c;
      this.binNumber = bin.Name == null ? '--' : bin.Name;
      this.section = bin.Section__c == null ? '--' : bin.Section__c;
      return this;
    }

    public ProductTransfer transfer() {
      ProductTransfer pt = toProductTransfer();
      insert pt;
      return pt;
    }
  }

  public class LocationWrapper {
    @AuraEnabled
    public Schema.Location userBaseLocation { get; set; }
    @AuraEnabled
    public Schema.Location workOrderLocation { get; set; }
    @AuraEnabled
    public Schema.Location pickAndPackLocation { get; set; }
    @AuraEnabled
    public Schema.Location warehouseLocation { get; set; }
    @AuraEnabled
    public Schema.Location workOrderPickAndPackLocation { get; set; }
    @AuraEnabled
    public List<Schema.Location> employeeLocations { get; set; }

    public LocationWrapper(Id workOrderId) {
      this.userBaseLocation = CurrentUser.getBaseLocation();
      this.employeeLocations = new List<Schema.Location>();
      setupLocations(workOrderId);
    }

    private void setupLocations(String workOrderId) {
      WorkOrder_Service woService = new WorkOrder_Service(workOrderId);
      this.workOrderLocation = woService.getLocation();
      this.workOrderPickAndPackLocation = woService.getPickAndPackLocation();
      for (AssignedResource ar : woService.getAssignedResources()) {
        this.employeeLocations.add(ar.ServiceResource.Location);
      }
    }
  }

  @AuraEnabled
  public static LocationWrapper getWorkOrderAndUserLocations(Id workOrderId) {
    return new LocationWrapper(workOrderId);
  }

  @AuraEnabled
  public static List<WorkOrderLineItem> fetchWorkOrderLineItems(Id workOrderId) {
    WorkOrder_Service woService = new WorkOrder_Service(workOrderId);
    return woService.getLineItems();
  }

  /*
    @jsonParams needs to be
    {
     workOrderId: 'xxxxx',
     sourceLocationId: 'xxxxx',
     destinationLocationId: 'xxxxx'
    }
  */
  @AuraEnabled
  public static List<TransferWrapper> fetchRequiredProducts(String jsonParams) {
    Map<String, String> params = (Map<String, String>) JSON.deserialize(jsonParams, Map<String, String>.class);
    WorkOrder_Service woService = new WorkOrder_Service(params.get('workOrderId'));
    List<TransferWrapper> result = new List<TransferWrapper>();
    List<ProductRequired> requiredProducts;
    Schema.Location destination = Location_Selector.getById(Id.valueOf(params.get('destinationLocationId')));
    if (destination.ParentLocation.LocationType == 'Pick and Pack') {
      requiredProducts = woService.getRequiredProductsForPickAndPack();
    } else {
      requiredProducts = woService.getRequiredProducts();
    }

    if (requiredProducts.size() > 0) {
      Map<Id, Map<Id, ProductItem>> productItemMap = getSourceProductItemsMap(
        requiredProducts,
        Id.valueOf(params.get('sourceLocationId')),
        Id.valueOf(params.get('destinationLocationId'))
      );

      result.addAll(
        buildTransferList(
          productItemMap,
          requiredProducts,
          params.get('sourceLocationId'),
          params.get('destinationLocationId')
        )
      );
    }
    return result;
  }

  @AuraEnabled
  public static List<TransferWrapper> fetchProductsForReturn(String sourceLocationId, String destinationLocationId) {
    List<TransferWrapper> result = new List<TransferWrapper>();
    for (ProductItem pItem : ProductItem_Selector.allByLocationWithQuantity(sourceLocationId)) {
      result.add(new TransferWrapper(pItem, destinationLocationId));
    }
    return result;
  }

  @AuraEnabled
  public static void transferSingle(TransferWrapper transfer) {
    try {
      transfer.transfer();
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void transferMultiple(List<TransferWrapper> transfers) {
    List<ProductTransfer> pts = new List<ProductTransfer>();
    System.debug(transfers);
    for (TransferWrapper t : transfers) {
      pts.add(t.toProductTransfer());
    }
    try {
      insert pts;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static ProductRequired createProductRequired(Id woliId, Id productId, Decimal quantity) {
    ProductRequired result = new ProductRequired(
      ParentRecordId = woliId,
      Product2Id = productId,
      QuantityRequired = quantity,
      QuantityUnitOfMeasure = 'each'
    );
    insert result;
    return result;
  }

  private static Map<Id, Map<Id, ProductItem>> getSourceProductItemsMap(
    List<ProductRequired> requiredProducts,
    Id sourceLocationId,
    Id destinationLocationId
  ) {
    Set<Id> productIds = new Set<Id>();
    Set<Id> locationIds = new Set<Id>{ sourceLocationId, destinationLocationId };
    Map<Id, Map<Id, ProductItem>> result = new Map<Id, Map<Id, ProductItem>>{
      sourceLocationId => new Map<Id, ProductItem>(),
      destinationLocationId => new Map<Id, ProductItem>()
    };
    //    for( WorkOrderLineItem woli : wolis )
    //    {
    for (ProductRequired pr : requiredProducts) {
      productIds.add(pr.Product2Id);
    }
    //    }
    if (productIds.size() > 0) {
      for (ProductItem pi : ProductItem_Selector.allByProductAndLocation(productIds, locationIds)) {
        result.get(pi.LocationId).put(pi.Product2Id, pi);
      }
    }
    return result;
  }

  private static List<TransferWrapper> buildTransferList(
    Map<Id, Map<Id, ProductItem>> productItemMap,
    List<ProductRequired> requiredProducts,
    String sourceId,
    String destinationId
  ) {
    Map<Id, Product_Bin_Location__c> binLocationsByProductId;
    Schema.Location source = Location_Selector.getById(Id.valueOf(sourceId));
    if (source.Warehouse__c != null) {
      binLocationsByProductId = getBinLocations(source.Warehouse__c, requiredProducts);
    }
    List<TransferWrapper> result = new List<TransferWrapper>();
    for (ProductRequired pr : requiredProducts) {
      ProductItem sourceItem = productItemMap.get(sourceId).containsKey(pr.Product2Id)
        ? productItemMap.get(sourceId).get(pr.Product2Id)
        : new ProductItem(LocationId = sourceId);
      ProductItem destinationItem = productItemMap.get(destinationId).containsKey(pr.Product2Id)
        ? productItemMap.get(destinationId).get(pr.Product2Id)
        : new ProductItem(LocationId = destinationId, QuantityOnHand = 0);
      TransferWrapper wrapper = new TransferWrapper(pr, sourceItem, destinationItem);
      if (binLocationsByProductId != null && binLocationsByProductId.containsKey(pr.Product2Id))
        wrapper.addBinLocation(binLocationsByProductId.get(pr.Product2Id));
      if (wrapper.quantityRequired > 0)
        result.add(wrapper);
    }
    return result;
  }

  private static Map<Id, Product_Bin_Location__c> getBinLocations(
    Id warehouseId,
    List<ProductRequired> requiredProducts
  ) {
    Set<Id> prodIds = new Set<Id>();
    Map<Id, Product_Bin_Location__c> result = new Map<Id, Product_Bin_Location__c>();
    for (ProductRequired pr : requiredProducts) {
      prodIds.add(pr.Product2Id);
    }
    for (
      Product_Bin_Location__c bin : ProductBinLocation_Selector.allByProductIdsAndWarehouseId(prodIds, warehouseId)
    ) {
      result.put(bin.Product__c, bin);
    }
    return result;
  }
}
