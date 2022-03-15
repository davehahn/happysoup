/**
 * Created by dave on 2020-12-14.
 */

public virtual class ProductBinLocation_Selector extends Application_Selector
{

  private final List<String> defaultFields = new List<String>
  {
    'Id',
    'Aisle__c',
    'Name',
    'Product__c',
    'Product__r.Name',
    'Section__c',
    'Warehouse__c',
    'Warehouse__r.Name'
  };

  public ProductBinLocation_Selector()
  {
    this.sObjectName = 'Product_Bin_Location__c';
    this.fields = defaultFields;
  }

  public static List<Product_Bin_Location__c> allByProductIdsAndWarehouseId(
    Set<Id> prodIds,
    Id warehouseId
  )
  {
    ProductBinLocation_Selector selector = new ProductBinLocation_Selector();
    selector.addWhereIdInField( prodIds, 'Product__c' )
      .addWhere('Warehouse__c = \'' + String.valueOf(warehouseId) + '\'');
    return selector.query();
  }
}