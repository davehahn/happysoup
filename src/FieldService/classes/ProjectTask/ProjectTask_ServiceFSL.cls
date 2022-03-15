/**
 * Created by dave on 2022-03-08.
 */
/* TODO: REQUIRES UNIT TESTS */
/* TODO: MERGE INTO PROJECTTASK_SERVICE WHEN FSL MOVES TO PROD */
public with sharing class ProjectTask_ServiceFSL {
  public static List<AcctSeed__Project_Task__c> newFromWorkOrderLineItemIds(Set<Id> workOrderLineitemIds) {
    List<WorkOrderLineItem> wolis = WorkOrderLineItem_Selector.selectAllById_includingWorkOrderWithERP(
      workOrderLineitemIds
    );
    return createFromWorkOrderLineItems(wolis);
  }
  public static void newFromWorkOrderLineItemIds_queue(Set<Id> workOrderLineItemIds) {
    if (Test.isRunningTest()) {
      CreateProjectTasksQueue cptq = new CreateProjectTasksQueue(workOrderLineItemIds);
      cptq.execute(null);
    } else {
      QueueableUtil.enqueueJob(new CreateProjectTasksQueue(workOrderLineItemIds));
    }
  }

  public static void deleteERPOrderTask(List<WorkOrderLineItem> wolis) {
    Set<Id> setIdTask = new Set<Id>();
    for (WorkOrderLineItem woli : wolis) {
      if (woli.ERP_Order_Task__c != null)
        setIdTask.add(woli.ERP_Order_Task__c);
    }
    if (!setIdTask.isEmpty()) {
      delete [SELECT Id FROM AcctSeed__Project_Task__c WHERE Id IN :setIdTask];
    }
  }

  private static List<AcctSeed__Project_Task__c> createFromWorkOrderLineItems(List<WorkOrderLineItem> wolis) {
    Map<Id, AcctSeed__Project_Task__c> woliId_task_map = new Map<Id, AcctSeed__Project_Task__c>();
    for (WorkOrderLineItem woli : wolis) {
      AcctSeed__Project_Task__c pt = buildFromWorkOrderLineItem(woli);
      System.debug(LoggingLevel.ERROR, 'pt:' + pt);
      woliId_task_map.put(woli.Id, pt);
    }
    insert woliId_task_map.values();
    for (WorkOrderLineItem woli : wolis) {
      woli.ERP_Order_Task__c = woliId_task_map.get(woli.Id).Id;
    }
    update wolis;
    return woliId_task_map.values();
  }

  private static AcctSeed__Project_Task__c buildFromWorkOrderLineItem(WorkOrderLineItem woli) {
    /** TODO: figure out how to handle DisplayOnCustomerInvoice **/
    String taskName = woli.WorkTypeId != null
      ? woli.WorkType.Name.left(80)
      : (woli.Description != null ? woli.Description.left(80) : 'Unknown');
    AcctSeed__Project_Task__c pTask = new AcctSeed__Project_Task__c(
      DisplayOnCustomerInvoice__c = woli.Visible_to_Customer__c,
      Name = taskName,
      Work_Order_Line_item__c = woli.Id,
      AcctSeed__Project__c = woli.WorkOrder.ERP_Order__c,
      IsFinishedGoodTask__c = true
    );
    return pTask;
  }
  // Always use in after context
  public static AcctSeed__Project_Task__c buildFromMFGWorkOrder(WorkOrder wo, WorkOrderLineItem woli) {
    return new AcctSeed__Project_Task__c(
      DisplayOnCustomerInvoice__c = woli.Visible_to_Customer__c,
      Name = 'PRE-RIG',
      Work_Order_Line_item__c = woli.Id,
      Product__c = wo.Manufacturing_Product_Id__c,
      AcctSeed__Project__c = wo.ERP_Order__c
    );
  }

  public class CreateProjectTasksQueue implements Queueable {
    public final Set<Id> recordIds;

    public CreateProjectTasksQueue(Set<Id> recordIds) {
      this.recordIds = recordIds;
    }

    public void execute(QueueableContext context) {
      ProjectTask_ServiceFSL.newFromWorkOrderLineItemIds(this.recordIds);
    }
  }
}
