/**
 * Created by dave on 2022-05-20.
 */

public without sharing class TA_SupportRequest_AssignToQueue implements TriggerAction.AfterInsert
{
  public class Support_Request_Exception extends Exception {}

  public static Id queueId {
    get {
      if (queueId == null) {
        try {
          queueId = [
            SELECT Id
            FROM Group
            WHERE Type = 'Queue' AND Name = 'Support Queue'
            LIMIT 1
          ].Id;
        } catch (Exception e) {
          throw new Support_Request_Exception(
            'Support Request Queue not found.  Please contact your administrator with the error'
          );
        }
      }
      return queueId;
    }
    set;
  }

  public void afterInsert( List<Support_Request__c> newList){
    Map<Id, Support_Request__c> newMap = new Map<id, Support_Request__c>(newList);
    sendToQueue( newMap.keySet() );
  }

  @Future
  public static void sendToQueue( Set<Id> ids ){
    List<Support_Request__c> reqs = new List<Support_Request__c>();
    Database.DmlOptions option = new Database.DmlOptions();
    option.emailHeader.triggerUserEmail = true;

    for( Id reqId : ids  ){
      reqs.add( new Support_Request__c(
        Id = reqId,
        OwnerId = queueId
      ));
    }

    Database.update(reqs, option);
  }
}
