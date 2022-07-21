/**
 * Created by dave on 2019-08-29.
 */

public with sharing class ERPOrder_PartnerBoatSaleToWO_Promise {
  public static Set<Id> ignoreProductRecordTypes {
    get {
      if (ignoreProductRecordTypes == null) {
        Application_RecordType.ProductRTs pRts = new Application_RecordType().getProductRecordTypes();
        ignoreProductRecordTypes = new Set<Id>{ pRts.getFeesId() };
      }
      return ignoreProductRecordTypes;
    }
    private set;
  }

  public static Set<String> ignoreProductFamilies {
    get {
      if (ignoreProductFamilies == null) {
        ignoreProductFamilies = new Set<String>{ 'Labour' };
      }
      return ignoreProductFamilies;
    }
    private set;
  }

  public void execute(Set<Id> erpIds) {
    System.debug('ERPOrder_PartnerBoatSaleToWO_Promise');
    new Promise(new createWorkOrders_Promise())
      .then(new createWorkOrderLineItems_Promise())
      .then(new createProductRequireds_Promise())
      .error(new ErrorHandler())
      .done(new DoneHandler())
      .execute(erpIds);
  }

  @TestVisible
  private static List<WorkOrder> doStepOne(Set<Id> erpIds) {
    Map<Id, WorkOrder> resultMap = new Map<Id, WorkOrder>();
    List<AcctSeed__Project__c> erps = Project_Selector.selectAllPartnerBoatSalesById(erpIds);
    for (AcctSeed__Project__c erp : erps) {
      resultMap.put(erp.Id, WorkOrder_Service.newFromPartnerBoatSaleERP(erp));
    }
    insert resultMap.values();
    for (AcctSeed__Project__c erp : erps) {
      erp.Work_Order__c = resultMap.get(erp.Id).Id;
    }
    Boolean origTriggerState = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    update erps;
    gcProject.disableTrigger = origTriggerState;
    return resultMap.values();
  }

  @TestVisible
  private static List<WorkOrderLineItem> doStepTwo(List<WorkOrder> workOrders) {
    Map<Id, WorkOrderLineItem> resultMap = new Map<Id, WorkOrderLineItem>();
    Map<Id, WorkOrder> erpId_WorkOrder_map = new Map<Id, WorkOrder>();
    for (WorkOrder wo : workOrders) {
      erpId_WorkOrder_map.put(wo.ERP_Order__c, wo);
    }
    List<AcctSeed__Project_Task__c> tasks = ProjectTask_Selector.selectAllByProjectId(erpId_WorkOrder_map.keySet());
    for (AcctSeed__Project_Task__c task : tasks) {
      resultMap.put(
        task.Id,
        WorkOrderLineItem_Service.newFromProjectTask(task, erpId_WorkOrder_map.get(task.AcctSeed__Project__c).Id)
      );
    }
    insert resultMap.values();
    for (AcctSeed__Project_Task__c task : tasks) {
      task.Work_Order_Line_Item__c = resultMap.get(task.Id).Id;
    }
    Boolean origTriggerState = gcProjectTask.disableTrigger;
    gcProjectTask.disableTrigger = true;
    update tasks;
    gcProjectTask.disableTrigger = origTriggerState;
    return resultMap.values();
  }

  private static void doStepThree(List<WorkOrderLineItem> workOrderLineItems) {
    Map<Id, WorkOrderLineItem> woliByTaskId = new Map<Id, WorkOrderLineItem>();
    List<ProductRequired> result = new List<ProductRequired>();
    for (WorkOrderLineItem woli : workOrderLineItems) {
      woliByTaskId.put(woli.ERP_Order_Task__c, woli);
    }
    for (AcctSeedERP__Material__c mat : Material_Selector.selectAllByTaskId(woliByTaskId.keySet())) {
      if (
        !ignoreProductRecordTypes.contains(mat.AcctSeedERP__Product__r.RecordTypeId) &&
        !ignoreProductFamilies.contains(mat.AcctSeedERP__Product__r.Family)
      ) {
        result.add(ProductRequired_Service.newFromMaterial(mat, woliByTaskId.get(mat.AcctSeedERP__Project_Task__c).Id));
      }
    }
    insert result;
  }

  /* DEFERRED CLASSES */

  public class createWorkOrders_Promise implements Promise.Deferred {
    private List<WorkOrder> workOrders;
    public Object resolve(Object erpIds) {
      workOrders = ERPOrder_PartnerBoatSaleToWO_Promise.doStepOne((Set<Id>) erpIds);
      return workOrders;
    }
  }

  public class createWorkOrderLineItems_Promise implements Promise.Deferred {
    private List<WorkOrderLineItem> workOrderLineItems;
    public Object resolve(Object workOrders) {
      workOrderLineItems = ERPOrder_PartnerBoatSaleToWO_Promise.doStepTwo((List<WorkOrder>) workOrders);
      return workOrderLineItems;
    }
  }

  public class createProductRequireds_Promise implements Promise.Deferred {
    public Object resolve(Object workOrderLineItems) {
      ERPOrder_PartnerBoatSaleToWO_Promise.doStepThree((List<WorkOrderLineItem>) workOrderLineItems);
      return null;
    }
  }

  /* HANDLER CLASSES */

  public class DoneHandler implements Promise.Done {
    public DoneHandler() {
    }
    public void done(Object error) {
      if (error != null) {
        ErrorHandler e = (ErrorHandler) error;
        new Queueable_Exception_Logger()
          .setModule('DealerOrder To WorkOrder')
          .setInitialInputType('Set<Id>')
          .setInitialInput(e.initialInputs)
          .log(e.theException);
      }
    }
  }

  public class ErrorHandler implements Promise.Error {
    public Exception theException;
    public Object initialInputs;
    public Object error(Exception e) {
      this.theException = e;
      this.initialInputs = initialInputs;
      return this;
    }
  }
}
