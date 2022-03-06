/**
 * Created by dave on 2021-06-04.
 */

public inherited sharing class TA_WorkOrderLineItem_CreateErpOrderTask implements TriggerAction.AfterInsert, TriggerAction.AfterUpdate
{

  public void afterInsert(
    List<WorkOrderLineItem> newList
  )
  {
    Map<Id, WorkOrderLineItem> newMap = new Map<Id, WorkOrderLineItem>( newList );
    Set<Id> requiresOrderTask = new Set<Id>();
    List<WorkOrderLineItem> wolis =
      WorkOrderLineItem_Selector.selectAllWithoutTaskById_includingWorkOrderWithERP(
        newMap.keySet()
      );
    for( WorkOrderLineItem wo : wolis )
    {
      requiresOrderTask.add( wo.Id );
    }
    if( requiresOrderTask.size() > 0 )
      ProjectTask_ServiceFSL.newFromWorkOrderLineItemIds_queue( requiresOrderTask );
  }

  public void afterUpdate (List<WorkOrderLineItem> newList, List<WorkOrderLineItem> oldList)
  {
    Map<Id, WorkOrderLineItem> newMap = new Map<Id, WorkOrderLineItem>( newList );
    System.debug('I am here to create ERP Task newMap' + newList);
    Set<Id> requiresOrderTask = new Set<Id>();
    List<WorkOrderLineItem> wolis =
            WorkOrderLineItem_Selector.selectAllWithoutTaskById_includingWorkOrderWithERP(
                    newMap.keySet()
            );
    for( WorkOrderLineItem wo : wolis )
    {
      System.debug('I am here to create ERP Task');
      requiresOrderTask.add( wo.Id );
    }
    if( requiresOrderTask.size() > 0 )
      ProjectTask_ServiceFSL.newFromWorkOrderLineItemIds_queue( requiresOrderTask );
  }

}