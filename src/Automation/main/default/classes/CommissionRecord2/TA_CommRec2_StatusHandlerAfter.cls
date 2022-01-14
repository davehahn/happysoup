/**
 * Created by dave on 2022-01-13.
 */

public inherited sharing class TA_CommRec2_StatusHandlerAfter implements TriggerAction.AfterUpdate
{
  public void afterUpdate( List<CommissionRecord2__c> newList, List<CommissionRecord2__c> oldList){
    Map<Id, CommissionRecord2__c> oldMap = new Map<Id, CommissionRecord2__c>( oldList );
    Set<Id> resolved = new Set<Id>();
    Set<Id> approved = new Set<Id>();
    Set<Id> approvedNow = new Set<Id>();
    Set<Id> disApproved = new Set<Id>();
    Set<Id> unApproved = new Set<Id>();
    Map<Id, Id> wasReviewed = new Map<Id, Id>();
    Map<Id, Id> wasApproved = new Map<Id, Id>();
    for( CommissionRecord2__c record : newList )
    {
      CommissionRecord2__c oldRecord = oldMap.get( record.Id );
      if( oldRecord.Status__c != record.Status__c )
      {
        if( oldRecord.Status__c == 'Disputed')
        {
          resolved.add( record.Id );
        }
        if( oldRecord.Status__c == 'Approved' )
        {
          unApproved.add( record.Id );
        }
        if( record.Status__c == 'Approved' &&
          oldRecord.Status__c != 'Disputed' )
        {
          approved.add( record.Id );
        }
        if( record.Status__c != 'Approved' &&
          oldRecord.Status__c == 'Approved' )
        {
          disApproved.add( record.Id );
        }
        if( record.Status__c == 'Approved' &&
          oldRecord.Status__c != 'Approved' )
        {
          approvedNow.add( record.Id );
        }
        if( record.Status__c == 'New' )
        {
          if( oldRecord.Status__c == 'Reviewed' )
          {
            wasReviewed.put( record.Id, oldRecord.Reviewed_By__c );
          }
          if( oldRecord.Status__c == 'Approved' )
          {
            wasApproved.put( record.Id, oldRecord.Approved_By__c );
          }
        }
      }
    }
    CommissionPayment2_Service.propagateCommissionRecordStageChange(
      resolved, unApproved
    );
    CommissionRecord2_Service.postRevertedMessage(
      wasReviewed, wasApproved
    );
//    if( approved.size() > 0 )
//    {
//      CommissionRecord2_Service.postApprovedMessage( approved );
//    }
    if( approvedNow.size() > 0 )
    {
      JournalEntry_Service.takeExpense(approvedNow);
    }
    if( disApproved.size() > 0 )
    {
      JournalEntry_Service.unTakeExpense(disApproved);
    }
  }
}