/**
 * Created by dave on 2019-08-06.
 */

public with sharing class WorkOrderLineItem_Service {

  public static WorkOrderLineItem createForRetailBoatSale( Id workOrderId )
  {
    WorkOrderLineItem woli = new WorkOrderLineItem(
      WorkOrderId = workOrderId,
      Description = 'Retail Sale',
      Is_From_Opportunity__c = true,
      Visible_to_Customer__c = true
    );
    insert woli;
    return woli;
  }

  public static WorkOrderLineItem createForManufacturing( WorkOrder wo)
  {
    WorkOrderLineItem woli = new WorkOrderLineItem(
        WorkOrderId = wo.Id,
        Description = 'PRE-RIG',
        Visible_to_Customer__c = true/*,
        WorkTypeId = wo.WorkTypeId*/
    );
    return woli;
  }

  public static WorkOrderLineItem newFromProjectTask( AcctSeed__Project_Task__c task, Id workOrderId )
  {
    return new WorkOrderLineItem(
      WorkOrderId = workOrderId,
      Description = task.Name,
      Visible_to_Customer__c = task.DisplayOnCustomerInvoice__c,
      ERP_Order_Task__c = task.Id
    );
  }

}