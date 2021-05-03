/**
 * Created by dave on 2020-01-02.
 */

public without sharing class SystemIssue_TriggerHandler extends TriggerHandler
{
  public class SystemIssue_Exception extends Exception{}

  public Id devQueueId {
    get {
      if( devQueueId == null )
      {
        try
        {
          devQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Development' LIMIT 1].Id;
        }
        catch( Exception e )
        {
          throw new SystemIssue_Exception('Development Queue not found.  Please contact your administrator with the error');
        }
      }
      return devQueueId;
    }
    set;
  }
//  protected override void bulkBefore()
//  {
//  }

//  protected override void bulkAfter()
//  {
//  }

  protected override void beforeInsert()
  {
    for( System_Issue__c si :(List<System_Issue__c>)Trigger.new )
    {
      si.OwnerId = devQueueId;
    }
  }

//  protected override void beforeUpdate()
//  {
//  }

//  protected override void beforeDelete()
//  {
//  }

  protected override void afterInsert()
  {
    new JiraConnect( Trigger.new, Trigger.oldMap ).createIssues();
  }

  protected override void afterUpdate()
  {
    new JiraConnect( Trigger.new, Trigger.oldMap ).updateIssues();
  }

//  protected override void afterDelete()
//  {
//  }

//  protected override void afterUndelete()
//  {
//  }

//  protected override void finalActions()
//  {
//  }
}