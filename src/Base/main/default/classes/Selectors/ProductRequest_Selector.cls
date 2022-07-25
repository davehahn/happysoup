/**
 * Created by dave on 2020-11-18.
 */

public virtual class ProductRequest_Selector extends Application_Selector {
  private final List<String> defaultFields = new List<String>{
    'Id',
    'DestinationLocationId',
    'ShipmentType',
    'SourceLocationId',
    'Status',
    'WorkOrderLineItemId',
    'WorkOrderId'
  };

  public ProductRequest_Selector() {
    this.sObjectName = 'ProductRequest';
    this.fields = defaultFields;
  }

  public static List<ProductRequest> allByWO_for_SourceDestination(
    Id workOrderId,
    Id sourceLocationId,
    Id destinationLocationId
  ) {
    ProductRequest_Selector selector = new ProductRequest_Selector();
    selector.addWhere('WorkOrderId \'' + workOrderId + '\'')
      .addWhere('SourceLocationId = \'' + sourceLocationId + '\'', 'AND')
      .addWHere('DestinationLocationId = \'' + destinationLocationId + '\'')
      .addChildQuery(new ProductRequestLineItem_Selector());
    return selector.query();
  }
}
