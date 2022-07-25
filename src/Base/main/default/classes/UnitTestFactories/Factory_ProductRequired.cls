/**
 * Created by dave on 2021-06-07.
 */
@IsTest
public class Factory_ProductRequired {
  public static ProductRequired buildRecord(Id parentId, Id productId, Decimal quantityEach) {
    return new ProductRequired(
      ParentRecordId = parentId,
      Product2Id = productId,
      QuantityRequired = quantityEach,
      QuantityUnitOfMeasure = 'Each'
    );
  }

  public static List<ProductRequired> buildRecords(Id parentId, List<Product2> products, Decimal quantityEach) {
    List<ProductRequired> result = new List<ProductRequired>();
    for (Product2 prod : products) {
      result.add(buildRecord(parentId, prod.Id, quantityEach));
    }
    return result;
  }

  public static List<ProductRequired> buildRecordFromMaterials(Id parentId, List<AcctSeedERP__Material__c> materials) {
    List<ProductRequired> result = new List<ProductRequired>();
    for (AcctSeedERP__Material__c mat : materials) {
      ProductRequired pr = buildRecord(parentId, mat.AcctSeedERP__Product__c, mat.AcctSeedERP__Quantity_Per_Unit__c);
      pr.Material__c = mat.Id;
      result.add(pr);
    }
    return result;
  }
}
