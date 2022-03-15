/**
 * Created by dave on 2022-03-07.
 */
/* TODO: MERGE WITH PROJECT_SERVICE WHEN FSL MOVES TO PROD */
public inherited sharing class Project_ServiceFSL {
  public static void deleteERPOrder(List<WorkOrder> wos) {
    Set<Id> setIdProject = new Set<Id>();
    for (WorkOrder wo : wos) {
      if (wo.ERP_Order__c != null)
        setIdProject.add(wo.ERP_Order__c);
    }
    if (!setIdProject.isEmpty()) {
      delete [SELECT Id FROM AcctSeed__Project__c WHERE Id IN :setIdProject];
    }
  }
  public static AcctSeed__Project__c constructFromOpportunityAndWorkOrder(Opportunity opp, WorkOrder wo) {
    AcctSeed__Project__c result = new Project_service.Project().buildFromOpportunity(opp).getRecord();
    result.Work_Order__c = wo.Id;
    return result;
  }
  public static AcctSeed__Project__c constructFromWorkOrder(WorkOrder wo) {
    return new AcctSeed__Project__c(
      Name = (wo.Account.Name + ' - ' + String.valueOf(wo.WorkOrderNumber)).LEFT(80),
      AcctSeed__Account__c = wo.AccountId,
      Work_Order__c = wo.Id
    );
  }

  public static AcctSeed__Project__c constructMFGFromWorkOrder(WorkOrder wo) {
    return new AcctSeed__Project__c(
      RecordTypeId = Project_Service.recordTypes.getManufacturingId(),
      Name = (wo.Warehouse_Name__c +
      ' - ' +
      wo.Serial_Name__c),
      Serial_Number__c = wo.Serial_Number__c,
      AcctSeedERP__Manufactured_Product__c = wo.Manufacturing_Product_Id__c,
      Work_Order__c = wo.Id
    );
  }
  public static AcctSeed__Project__c createFromOpportunityAndWorkOrder(Opportunity opp, WorkOrder wo) {
    AcctSeed__Project__c result = constructFromOpportunityAndWorkOrder(opp, wo);
    System.debug('ERP CREATED');
    System.debug(result);
    insert result;
    wo.ERP_Order__c = result.Id;
    update wo;
    return result;
  }

  public static void createFromWorkOrderIds(Set<Id> workOrderIds) {
    System.debug('Project_Service.createFromWorkOrderIds');
    if (Test.isRunningTest()) {
      CreateERPsQueue queue = new CreateERPsQueue(workOrderIds);
      queue.execute(null);
    } else {
      QueueableUtil.enqueueJob(new CreateERPsQueue(workOrderIds));
    }
  }

  public class CreateERPsQueue implements Queueable {
    public final Set<Id> workOrderIds;

    public CreateERPsQueue(Set<Id> workOrderIds) {
      this.workOrderIds = workOrderIds;
    }

    public void execute(QueueableContext context) {
      Id manuWoRtID = new Application_RecordType().getWorkOrderRecordTypes().getManufacturingId();
      List<WorkOrder> workOrders = WorkOrder_Selector.selectAllWithOutERPOrders_ByIds(this.workOrderIds);
      Map<Id, WorkOrder> WO_Map = new Map<Id, WorkOrder>();
      for (WorkOrder wo : workOrders) {
        WO_Map.put(wo.Id, wo);
      }
      if (workOrders.size() == 0)
        return;
      Map<Id, WorkOrder> oppId_WO_Map = new Map<Id, WorkOrder>();
      Map<Id, WorkOrderLineItem> mapWOLineItemByWO = new Map<Id, WorkOrderLineItem>();
      Map<Id, WorkOrderLineItem> mapWOLineItemByWOReady = new Map<Id, WorkOrderLineItem>();
      Map<Id, AcctSeed__Project__c> woId_ERP_Map = new Map<Id, AcctSeed__Project__c>();
      List<WorkOrderLineItem> listALLWOLItoUpdate = new List<WorkOrderLineItem>();
      Set<Id> setIdMFGWO = new Set<Id>();
      for (WorkOrder wo : workOrders) {
        if (wo.RecordTypeId == manuWoRtID) {
          /// We do not want the ERP if there is not Serial Number
          /// Discussed with Dave on 1 June 2021
          if (wo.Serial_Number__c != null) {
            setIdMFGWO.add(wo.Id);
          }
        } else if (wo.Opportunity__c != null)
          oppId_WO_Map.put(wo.Opportunity__c, wo);
        else
          woId_ERP_Map.put(wo.Id, constructFromWorkOrder(wo));
      }
      if (!oppId_WO_Map.isEmpty()) {
        for (Opportunity opp : Opportunity_Selector.allByIds(oppId_WO_Map.keySet())) {
          WorkOrder wo = oppId_WO_Map.get(opp.Id);
          woId_ERP_Map.put(wo.Id, constructFromOpportunityAndWorkOrder(opp, wo));
        }
      }
      if (!woId_ERP_Map.isEmpty()) {
        insert woId_ERP_Map.values();
        workOrders = new List<WorkOrder>();
        for (Id woId : woId_ERP_Map.keySet()) {
          workOrders.add(new WorkOrder(Id = woId, ERP_Order__c = woId_ERP_Map.get(woId).Id));
        }
        update workOrders;
      }
      /// Call Queueable for creating all ERP, Task and Materials
      if (!setIdMFGWO.isEmpty()) {
        new MFGWorkOrderToERP_Promise().execute(setIdMFGWO);
      }
    }
  }
}
