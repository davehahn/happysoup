/**
 * Created by dave on 2020-11-18.
 */

public virtual class ProductRequestLineItem_Selector extends Application_Selector
{
  private final List<String> defaultFields = new List<String>
  {
    'Id',
    'Product2',
    'QuantityRequested',
    'ShipmentType',
    'Status',
    'WorkOrderId',
    'WorkOrderLineItemId',
    'DestinationLocationId',
    'SourceLocationId'
  };

  public ProductRequestLineItem_Selector()
  {
    this.sObjectName = 'ProductRequestLineItem';
    this.fields = defaultFields;
  }
}