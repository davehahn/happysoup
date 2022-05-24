/**
 * Created by dave on 2022-05-20.
 */

public without sharing class TA_SupportRequest_AssignToQueue implements TriggerAction.BeforeInsert
{
  public class Support_Request_Exception extends Exception {}

  public Id queueId {
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

  public void beforeInsert( List<Support_Request__c> newList){
    for( Support_Request__c req : newList ){
      req.OwnerId = queueId;
    }
  }
}