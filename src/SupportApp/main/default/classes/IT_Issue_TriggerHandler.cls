/**
 * Created by dave on 2021-11-22.
 */

public without sharing class IT_Issue_TriggerHandler extends TriggerHandler
{
  public class IT_Issue_Exception extends Exception {}

  public Id itQueueId {
    get {
      if (itQueueId == null) {
        try {
          itQueueId = [
            SELECT Id
            FROM Group
            WHERE Type = 'Queue' AND Name = 'IT Issues'
            LIMIT 1
          ]
            .Id;
        } catch (Exception e) {
          throw new IT_Issue_Exception(
            'IT Issues Queue not found.  Please contact your administrator with the error'
          );
        }
      }
      return itQueueId;
    }
    set;
  }

//  protected override void bulkBefore()
//  {
//    system.debug('[IT_Issue_TriggerHandler] bulk before');
//  }

//  protected override void bulkAfter()
//  {
//    system.debug('[IT_Issue_TriggerHandler] bulk after');
//  }

  protected override void beforeInsert()
  {
    for( IT_Issue__c issue : (List<IT_Issue__c>)Trigger.new){
      issue.OwnerId = itQueueId;
    }
  }

  protected override void beforeUpdate()
  {
    for(IT_Issue__c iss : (List<IT_Issue__c>)Trigger.new ){
      IT_Issue__c oldIssue = (IT_Issue__c)Trigger.oldMap.get( iss.Id );
      if( !isAUser( oldIssue.OwnerId ) && isAUser(iss.OwnerId) && iss.Status__c == 'New' ){
        iss.Status__c = 'Accepted';
      }
    }
  }

//  protected override void beforeDelete()
//  {
//    system.debug('[IT_Issue_TriggerHandler] before delete');
//  }

//  protected override void afterInsert()
//  {
//    system.debug('[IT_Issue_TriggerHandler] after insert');
//  }

  protected override void afterUpdate()
  {
    system.debug('[IT_Issue_TriggerHandler] after update');
  }

//  protected override void afterDelete()
//  {
//    system.debug('[IT_Issue_TriggerHandler] after delete');
//  }

//  protected override void afterUndelete()
//  {
//    system.debug('[IT_Issue_TriggerHandler] after undelete');
//  }

//  protected override void finalActions()
//  {
//    system.debug('[IT_Issue_TriggerHandler] final actions');
//  }


  private Boolean isAUser( Id ownerId ){
    return ownerId.getSObjectType().getDescribe().getName() == 'User';
  }

}