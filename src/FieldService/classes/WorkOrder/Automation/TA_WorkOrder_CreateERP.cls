/**
 * Created by dave on 2021-06-03.
 */

public inherited sharing class TA_WorkOrder_CreateERP implements TriggerAction.AfterInsert, TriggerAction.AfterUpdate
{

  public void afterInsert(
    List<WorkOrder> newList
  )
  {
    Set<Id> requiresERP = new Set<Id>();
    for( WorkOrder wo : newList )
    {
      if( wo.ERP_Order__c == null )
      {
        requiresERP.add( wo.Id );
      }
    }
    if( requiresERP.size() > 0 )
    {
      Project_ServiceFSL.createFromWorkOrderIds( requiresERP );
    }
  }

  public void afterUpdate(
          List<WorkOrder> newList,
          List<WorkOrder> oldList
  )
  {
    Set<Id> requiresERP = new Set<Id>();
    for( WorkOrder wo : newList )
    {
      /// This is so far only specific to Manufacturing WO
      System.debug('Here for creating Task and ERP');
      if( wo.ERP_Order__c == null)
      {
        requiresERP.add( wo.Id );
      }
    }
    if( requiresERP.size() > 0 )
    {
      Project_ServiceFSL.createFromWorkOrderIds( requiresERP );
    }
  }

}