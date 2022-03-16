/**
 * Created by dave on 2022-01-25.
 */

public without sharing class TA_CommPay2_HandleStatusChange implements TriggerAction.AfterUpdate
{
  public void afterUpdate( List<CommissionPayment2__c> newList, List<CommissionPayment2__c> oldList ){
    Map<Id, CommissionPayment2__c> oldMap = new Map<Id, CommissionPayment2__c>( oldList );
    List<CommissionRecord2__c> disputedRecords = new List<CommissionRecord2__c>();
    Map<Id, Set<Id>> resolvedComRecId_paymentsMap = new Map<Id, Set<Id>>();
    for( CommissionPayment2__c payment :newList )
    {
      if( payment.Status__c != oldMap.get( payment.Id ).Status__c )
      {
        if( payment.Status__c == 'Disputed' )
        {
          disputedRecords.add( new CommissionRecord2__c(
            Id = payment.Commission_Record2__c,
            Status__c = 'Disputed'
          ) );
        }
        if( oldMap.get( payment.Id ).Status__c == 'Disputed' )
        {
          if( !resolvedComRecId_paymentsMap.containsKey( payment.Commission_Record2__c) )
          {
            resolvedComRecId_paymentsMap.put( payment.Commission_Record2__c, new Set<Id>() );
          }
          resolvedComRecId_paymentsMap.get( payment.Commission_Record2__c ).add( payment.Owner__c );
        }
      }
    }
    if( disputedRecords.size() > 0 )
      update disputedRecords;
    if( resolvedComRecId_paymentsMap.size() > 0 )
    {
      CommissionRecord2_Service.postResolveMessage( resolvedComRecId_paymentsMap );
    }
  }
}