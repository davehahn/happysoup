/**
 * Created by dave on 2021-06-07.
 */

public inherited sharing class TA_ProductRequired_CreateMaterials implements TriggerAction.AfterInsert, TriggerAction.beforeUpdate {
  public static void beforeUpdate(List<ProductRequired> newList, List<ProductRequired> oldList) {
    filterAndCreateMaterials(newList);
  }

  public static void afterInsert(List<ProductRequired> newList) {
    filterAndCreateMaterials(newList);
  }

  private static void filterAndCreateMaterials(List<ProductRequired> newList) {
    Set<Id> toCreateMaterials = new Set<Id>();
    for (ProductRequired pr : newList) {
      if (pr.Material__c == null) {
        toCreateMaterials.add(pr.Id);
      }
    }

    if (toCreateMaterials.size() > 0) {
      Material_ServiceFSL.createFromProductRequiredIds_queue(toCreateMaterials);
    }
  }
}
