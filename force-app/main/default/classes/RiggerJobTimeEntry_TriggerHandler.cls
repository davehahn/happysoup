/**
 * Created by dave on 2019-11-22.
 */

public without sharing class RiggerJobTimeEntry_TriggerHandler extends TriggerHandler
{

//  protected override void bulkBefore()
//  {
//    system.debug('[RiggerJobTimeEntry_TriggerHandler] bulk before');
//  }

//  protected override void bulkAfter()
//  {
//    system.debug('[RiggerJobTimeEntry_TriggerHandler] bulk after');
//  }

  protected override void beforeInsert()
  {
    setRigger( (List<Rigger_Job_Time_Entry__c>)Trigger.new );
    setActualTime( (List<Rigger_Job_Time_Entry__c>)Trigger.new, null );
  }

  protected override void beforeUpdate()
  {
    setActualTime( (List<Rigger_Job_Time_Entry__c>)Trigger.new, (Map<Id, Rigger_Job_Time_Entry__c>)Trigger.oldMap );
  }

//  protected override void beforeDelete()
//  {
//    system.debug('[RiggerJobTimeEntry_TriggerHandler] before delete');
//  }

//  protected override void afterInsert()
//  {
//    system.debug('[RiggerJobTimeEntry_TriggerHandler] after insert');
//  }

//  protected override void afterUpdate()
//  {
//    system.debug('[RiggerJobTimeEntry_TriggerHandler] after update');
//  }

//  protected override void afterDelete()
//  {
//    system.debug('[RiggerJobTimeEntry_TriggerHandler] after delete');
//  }

//  protected override void afterUndelete()
//  {
//    system.debug('[RiggerJobTimeEntry_TriggerHandler] after undelete');
//  }

//  protected override void finalActions()
//  {
//    system.debug('[RiggerJobTimeEntry_TriggerHandler] final actions');
//  }

  private static void setRigger( List<Rigger_Job_Time_Entry__c> listNew )
  {
    Set<Id> jobIds = new Set<Id>();
    for( Rigger_Job_Time_Entry__c entry : listNew )
    {
      jobIds.add( entry.Rigger_Job__c );
    }
    Map<Id, Rigger_Job__c> jobsMap = new Map<Id, Rigger_Job__c>([SELECT Id, Employee__c FROM Rigger_Job__c WHERE Id IN :jobIds ] );
    for( Rigger_Job_Time_Entry__c entry : listNew )
    {
      if( jobsMap.containsKey( entry.Rigger_Job__c ) )
        entry.Employee__c = jobsMap.get( entry.Rigger_Job__c ).Employee__c;
    }
  }

  private static void setActualTime( List<Rigger_Job_Time_Entry__c> listNew,
                                Map<Id, Rigger_Job_Time_Entry__c> oldMap )
  {
    for( Rigger_Job_Time_Entry__c rjte: listNew )
    {
      //on insert
      if( oldMap == null )
      {
        if( rjte.Start_At__c != null && rjte.End_At__c != null )
          rjte.Total_Time__c = calcTimeInMinutes( rjte.Start_At__c, rjte.End_At__c );
      }
      //on update
      if( oldMap != null )
      {
        Rigger_Job_Time_Entry__c old = oldMap.get( rjte.Id );
        if( ( rjte.Start_At__c != null &&
              rjte.Start_At__c != old.Start_At__c ) ||
            ( rjte.End_At__c != null &&
              rjte.End_At__c != old.End_At__c ) )
        {
          rjte.Total_Time__c = calcTimeInMinutes( rjte.Start_At__c, rjte.End_At__c );
        }
      }
    }
  }

  private static Long calcTimeInMinutes( DateTime startAt, DateTime endAt )
  {
    return ( endAt.getTime() - startAt.getTime() ) / 60000;
  }
}