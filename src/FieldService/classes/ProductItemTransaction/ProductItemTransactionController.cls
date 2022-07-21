/**
 * Created by aminrubel on 2019-08-28.
 */

public without sharing class ProductItemTransactionController {
  public static void updateAcctSeedInventory(List<ProductItemTransaction> listPIT) {
    Set<Id> setIdPIT = new Set<Id>();
    for (ProductItemTransaction pit : listPIT) {
      setIdPIT.add(pit.ProductItemId);
    }
    if (!setIdPIT.isEmpty()) {
      Map<Id, Id> mapIdWarehouseLocation = new Map<Id, Id>();
      /// Now collect all PI information for location
      Map<Id, ProductItem> mapIdPI = new Map<Id, ProductItem>();
      for (ProductItem pi : [
        SELECT Id, LocationId, Location.Warehouse__c, Product2Id
        FROM ProductItem
        WHERE Id IN :setIdPIT AND Location.Warehouse__c != NULL
      ]) {
        mapIdPI.put(pi.Id, pi);
        mapIdWarehouseLocation.put(pi.Location.Warehouse__c, null);
      }
      if (!mapIdWarehouseLocation.isEmpty()) {
        for (AcctSeedERP__Location__c loc : [
          SELECT Id, AcctSeedERP__Warehouse__c
          FROM AcctSeedERP__Location__c
          WHERE AcctSeedERP__Warehouse__c IN :mapIdWarehouseLocation.keySet()
        ]) {
          mapIdWarehouseLocation.put(loc.AcctSeedERP__Warehouse__c, loc.Id);
        }
      }
      Map<Id, Map<Id, Map<Id, Id>>> mapPWLB = new Map<Id, Map<Id, Map<Id, Id>>>();
      for (Id piId : mapIdPI.keySet()) {
        ProductItem pi = mapIdPI.get(piId);
        if (!mapPWLB.containsKey(pi.Product2Id)) {
          mapPWLB.put(
            pi.Product2Id,
            new Map<Id, map<Id, Id>>{
              pi.Location.Warehouse__c => new Map<Id, Id>{
                mapIdWarehouseLocation.get(pi.Location.Warehouse__c) => null
              }
            }
          );
        } else if (!mapPWLB.get(pi.Product2Id).containsKey(pi.Location.Warehouse__c)) {
          mapPWLB.get(pi.Product2Id)
            .put(
              pi.Location.Warehouse__c,
              new Map<Id, Id>{ mapIdWarehouseLocation.get(pi.Location.Warehouse__c) => null }
            );
        }
      }
      GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
    }
  }
}
