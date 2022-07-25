/**
 * Created by dave on 2020-11-13.
 */

public virtual class ProductItem_Selector extends Application_Selector {
  private final List<String> defaultFields = new List<String>{
    'Id',
    'LocationId',
    'Location.Name',
    'Product2Id',
    'ProductName',
    'Product2.ProductCode',
    'QuantityOnHand',
    'QuantityUnitOfMeasure',
    'SerialNumber'
  };

  public ProductItem_Selector() {
    this.sObjectName = 'ProductItem';
    this.fields = defaultFields;
  }

  public static List<ProductItem> allByLocationWithQuantity(Id locationId) {
    ProductItem_Selector selector = new ProductItem_Selector();
    selector.addWhere('LocationId = \'' + locationId + '\'').addWhere('QuantityOnHand > 0', 'AND');
    return selector.query();
  }

  public static List<ProductItem> allByProductAndLocation(Set<Id> productIds, Set<Id> locationIds) {
    System.debug('ProductIds size = ' + productIds.size());
    System.debug('locationIds size = ' + locationIds.size());
    ProductItem_Selector selector = new ProductItem_Selector();
    selector.addWhereIdInField(productIds, 'Product2Id', 'AND').addWhereIdInField(locationIds, 'LocationId');
    return selector.query();
  }
}
