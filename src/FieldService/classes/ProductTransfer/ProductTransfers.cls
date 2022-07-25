/**
 * Created by dave on 2020-11-13.
 */

public with sharing class ProductTransfers {
  public List<ProductTransfer> records;
  public Map<Id, ProductTransfer> oldRecordMap;

  public ProductTransfers(List<sObject> records, Map<Id, sObject> oldMap) {
    this.records = (List<ProductTransfer>) records;
    this.oldRecordMap = (Map<Id, ProductTransfer>) oldMap;
  }

  public void onBeforeInsert() {
    /* make sure we have a Product Item for every Location/Product
       IF the Product is an Inventory Product
    */
    verifyProductItems();
    //make sure inventory is available in the source location
    //if it a serialized product, quantity should only be 1
  }

  public void onAfterInsert() {
    Set<Id> productRequiredIds = new Set<Id>();
    for (ProductTransfer pt : this.records) {
      if (pt.ProductRequired__c != null && (pt.Is_Transfer_To_Pick_And_Pack__c || pt.Is_Transfer_To_Employee__c)) {
        productRequiredIds.add(pt.ProductRequired__c);
      }
    }
    if (productRequiredIds.size() > 0)
      updateProductRequiredQuantities(productRequiredIds);
  }

  private void verifyProductItems() {
    Set<Id> productIds = new Set<Id>();
    Set<Id> locationIds = new Set<Id>();
    List<ProductItem> newPIs = new List<ProductItem>();
    for (ProductTransfer pt : this.records) {
      productIds.add(pt.Product2Id);
      locationIds.add(pt.SourceLocationId);
      locationIds.add(pt.DestinationLocationId);
    }
    productIds.remove(null);
    locationIds.remove(null);
    if (productIds.size() > 0 && locationIds.size() > 0) {
      Map<Id, Product2> prodMap = Product_Selector.allByIdAsMap(productIds);
      Map<String, ProductItem> uniqPIs = new Map<String, ProductItem>();
      for (ProductItem pi : ProductItem_Selector.allByProductAndLocation(productIds, locationIds)) {
        String key = String.valueOf(pi.Product2Id) + ':' + String.valueOf(pi.LocationId);
        uniqPIs.put(key, pi);
      }
      for (ProductTransfer pt : this.records) {
        if (prodMap.get(pt.Product2Id).AcctSeed__Inventory_Product__c) {
          String sourceKey = String.valueOf(pt.Product2Id) + ':' + String.valueOf(pt.SourceLocationId);
          String destKey = String.valueOf(pt.Product2Id) + ':' + String.valueOf(pt.DestinationLocationId);
          if (!uniqPIs.containsKey(sourceKey))
            newPIs.add(newProductItemFromTransfer(pt, pt.SourceLocationId));
          if (!uniqPIs.containsKey(destKey))
            newPIs.add(newProductItemFromTransfer(pt, pt.DestinationLocationId));
        }
      }
    }
    if (newPIs.size() > 0)
      insert newPIs;
  }

  private ProductItem newProductItemFromTransfer(ProductTransfer pt, Id locationId) {
    return new ProductItem(
      LocationId = locationId,
      Product2Id = pt.Product2Id,
      QuantityOnHand = 0,
      QuantityUnitOfMeasure = pt.QuantityUnitOfMeasure
    );
  }

  private void updateProductRequiredQuantities(Set<Id> prodRequiredIds) {
    Map<Id, ProductRequired> prMap = ProductRequired_Selector.allByIdMap(prodRequiredIds);
    for (ProductTransfer pt : this.records) {
      if (pt.ProductRequired__c != null && prMap.containsKey(pt.ProductRequired__c)) {
        if (pt.Is_Transfer_To_Pick_And_Pack__c) {
          if (prMap.get(pt.ProductRequired__c).QuantityPickAndPack__c == null)
            prMap.get(pt.ProductRequired__c).QuantityPickAndPack__c = pt.QuantityReceived;
          else
            prMap.get(pt.ProductRequired__c).QuantityPickAndPack__c += pt.QuantityReceived;
        }
        if (pt.Is_Transfer_To_Employee__c) {
          if (prMap.get(pt.ProductRequired__c).QuantityHandedOut__c == null)
            prMap.get(pt.ProductRequired__c).QuantityHandedOut__c = pt.QuantityReceived;
          else
            prMap.get(pt.ProductRequired__c).QuantityHandedOut__c += pt.QuantityReceived;
        }
      }
    }
    update prMap.values();
  }
}
