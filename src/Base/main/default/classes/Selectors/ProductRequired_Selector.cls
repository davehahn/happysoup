/**
 * Created by dave on 2019-08-16.
 */

public virtual class ProductRequired_Selector extends Application_Selector {
  private final List<String> defaultFields = new List<String>{
    'Id',
    'Product2Id',
    'Product2.Name',
    'Product2.ProductCode',
    'QuantityRequired',
    'QuantityPickAndPack__c',
    'QuantityHandedOut__c',
    'QuantityUnitOfMeasure',
    'ParentRecordType',
    'ParentRecordId',
    'Material__c',
    'IsPickAndPackComplete__c',
    'IsHandOutComplete__c'
  };

  public ProductRequired_Selector() {
    this.sObjectName = 'ProductRequired';
    this.fields = defaultFields;
  }

  public static Map<Id, ProductRequired> allByIdMap(Set<Id> recordIds) {
    ProductRequired_Selector selector = new ProductRequired_Selector();
    selector.addWhereIdIn(recordIds);
    return new Map<Id, ProductRequired>((List<ProductRequired>) selector.query());
  }

  public static ProductRequired[] selectAllWithoutMaterialByIds(Set<Id> recordIds) {
    return new ProductRequired_Selector().addWhereIdIn(recordIds).addWhere('Material__c = null').query();
  }

  public static ProductRequired[] selectAllByWorkOrderLineIds(Set<Id> recordIds) {
    return new ProductRequired_Selector().addWhereIdInField(recordIds, 'ParentRecordId').query();
  }
}
