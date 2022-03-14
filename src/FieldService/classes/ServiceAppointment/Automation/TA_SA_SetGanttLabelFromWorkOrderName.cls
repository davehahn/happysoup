/**
 * Created by dave on 2021-06-07.
 */

public inherited sharing class TA_SA_SetGanttLabelFromWorkOrderName implements TriggerAction.AfterInsert
{

  public static void afterInsert(
    List<ServiceAppointment> newList
  )
  {
    Map<Id, ServiceAppointment> newMap = new Map<Id, ServiceAppointment>( newList );
    List<ServiceAppointment> toUpdate = new List<ServiceAppointment>();
    for( ServiceAppointment sa : ServiceAppointment_Selector.allById( newMap.keySet() ) )
    {
      if( sa.ParentRecordId != null )
      {
        sa.FSL__GanttLabel__c = sa.ParentRecord.Name;
        toUpdate.add( sa );
      }
    }
    if( toUpdate.size() > 0 )
    {
      TriggerBase.bypass( 'ServiceAppointment' );
      update toUpdate;
      TriggerBase.clearByPass( 'ServiceAppointment' );
    }
  }

}