/**
 * Created by dave on 2022-01-12.
 */

public without sharing class TA_CommRec2_StatusHandlerBefore implements TriggerAction.BeforeUpdate
{
  public void beforeUpdate( List<CommissionRecord2__c> newList, List<CommissionRecord2__c> oldList ){
    Map<Id, CommissionRecord2__c> oldMap = new Map<Id, CommissionRecord2__c>(oldList);
    if( CommissionRecord2_Service.canUpdateStatus(newList, oldMap) )
    {
      Set<Id> setId = new Set<Id>();
      for (CommissionRecord2__c record : newList)
      {
        CommissionRecord2__c oRecord = oldMap.get(record.Id);
        if ( oRecord.Status__c != record.Status__c)
        {
          if( record.Status__c == 'Reviewed' )
          {
            record.Reviewed_By__c = UserInfo.getUserId();
          }
          if(record.Status__c == 'Approved')
          {
            record.Approved_By__c = UserInfo.getUserId();
            record.Approved_On__c = DateTime.now();
            setId.add(record.Id);
          }
          if(oRecord.Status__c == 'Reviewed' && record.Status__c != 'Approved' )
          {
            record.Reviewed_By__c = null;
          }
          if(oRecord.Status__c == 'Approved')
          {
            record.Approved_By__c = null;
            record.Approved_On__c = null;
            record.Previously_Approved_on__c = oRecord.Approved_On__c;
          }
        }
      }
    }
  }
}