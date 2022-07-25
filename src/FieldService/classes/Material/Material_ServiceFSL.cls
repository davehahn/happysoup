/**
 * Created by dave on 2022-03-07.
 */
/* TODO: MERGE WITH MATERIAL_SERVICE WHEN FSL MOVES TO PROD */
public inherited sharing class Material_ServiceFSL {
  public static List<AcctSeedERP__Material__c> createFromProductRequiredIds(Set<Id> productRequiredIds) {
    return createFromProductRequireds(ProductRequired_Selector.selectAllWithoutMaterialByIds(productRequiredIds));
  }

  public static void createFromProductRequiredIds_queue(Set<Id> productRequiredIds) {
    if (Test.isRunningTest())
      System.enqueueJob(new CreateERP_MaterialsQueue(productRequiredIds));
    else
      QueueableUtil.enqueueJob(new CreateERP_MaterialsQueue(productRequiredIds));
  }

  public static void deleteMaterials(List<ProductRequired> prs) {
    Set<Id> setIdMaterial = new Set<Id>();
    for (ProductRequired pr : prs) {
      if (pr.Material__c != null)
        setIdMaterial.add(pr.Material__c);
    }
    if (!setIdMaterial.isEmpty()) {
      delete [SELECT Id FROM AcctSeedERP__Material__C WHERE Id IN :setIdMaterial];
    }
  }

  private static List<AcctSeedERP__Material__c> createFromProductRequireds(List<ProductRequired> prs) {
    if (prs.size() == 0)
      return null;
    Map<Id, AcctSeedERP__Material__c> prId_mat_map = new Map<Id, AcctSeedERP__Material__c>();
    Map<Id, List<ProductRequired>> woliId_prList_map = new Map<Id, List<ProductRequired>>();
    if (prs != null) {
      for (ProductRequired pr : prs) {
        if (pr.ParentRecordType == 'WorkOrderLineItem') {
          if (!woliId_prList_map.containsKey(pr.ParentRecordId))
            woliId_prList_map.put(pr.ParentRecordId, new List<ProductRequired>());
          woliId_prList_map.get(pr.ParentRecordId).add(pr);
        }
      }

      Map<Id, WorkOrderLineItem> woliMap = new Map<Id, WorkOrderLineItem>();
      for (
        WorkOrderLineItem woli : WorkOrderLineItem_Selector.selectAllWithTaskById_includingWorkOrderWithERP(
          woliId_prList_map.keySet()
        )
      ) {
        woliMap.put(woli.Id, woli);
      }
      for (Id woliId : woliId_prList_map.keySet()) {
        if (woliMap.containsKey(woliId)) {
          for (ProductRequired pr : woliId_prList_map.get(woliId)) {
            if (pr.Material__c == null) {
              prId_mat_map.put(
                pr.Id,
                new AcctSeedERP__Material__c(
                  AcctSeedERP__Product__c = pr.Product2Id,
                  AcctSeedERP__Project_Task__c = woliMap.get(woliId).ERP_Order_Task__c,
                  AcctSeedERP__Project__c = woliMap.get(woliId).WorkOrder.ERP_Order__c,
                  AcctSeedERP__Quantity_Per_Unit__c = pr.QuantityRequired
                )
              );
            } else {
              prId_mat_map.put(
                pr.Id,
                new AcctSeedERP__Material__c(
                  Id = pr.Material__c,
                  AcctSeedERP__Quantity_Per_Unit__c = pr.QuantityRequired
                )
              );
            }
          }
        }
      }
      if (prId_mat_map.values().size() > 0) {
        upsert prId_mat_map.values();
        List<ProductRequired> updatedProductRequired = new List<ProductRequired>();
        for (Id prId : prId_mat_map.keySet()) {
          updatedProductRequired.add(new ProductRequired(Id = prId, Material__c = prId_mat_map.get(prId).Id));
        }

        TriggerBase.bypass('ProductRequired');
        update updatedProductRequired;
        TriggerBase.clearBypass('ProductRequired');
      }
    }
    return prId_mat_map.values();
  }

  public class CreateERP_MaterialsQueue implements Queueable {
    public final Set<Id> recordIds;

    public CreateERP_MaterialsQueue(Set<Id> recordIds) {
      System.debug('MaterialService.CreateERP_MaterialsQueue.constructor');
      System.debug(recordIds);
      this.recordIds = recordIds;
    }

    public void execute(QueueableContext context) {
      Material_ServiceFSL.createFromProductRequiredIds(this.recordIds);
    }
  }
}
