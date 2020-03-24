/**
 * Created by dave on 2020-02-05.
 */

public with sharing class CommissionRecord2_Controller
{
  public class CommissionRecord2_Exception extends Exception{}

  @AuraEnabled(Cacheable=true)
  public static List<CommissionWrapper.Record> fetchCommissionRecords( String erpId )
  {
    List<CommissionWrapper.Record> results = new List<CommissionWrapper.Record>();
    for( CommissionRecord2__c r : doCommissionRecordFetch(erpId) )
    {
      results.add( new CommissionWrapper.Record( r ) );
    }
    return results;
  }

  @AuraEnabled(Cacheable=true)
  public static CommissionWrapper.Record fetchCommissionRecord( String recordId )
  {
    List<CommissionWrapper.Record> results = new List<CommissionWrapper.Record>();
    for( CommissionRecord2__c r : doCommissionRecordFetch(recordId) )
    {
      results.add( new CommissionWrapper.Record( r ) );
    }
    if( results.size() > 0 )
      return results[0];
    return null;
  }

  @AuraEnabled
  public static CommissionWrapper.Record updateCommissionRecordStatus( String recordId, String status )
  {
    try
    {
      if( !Schema.sObjectType.CommissionRecord2__c.fields.Status__c.isUpdateable() )
        throw new CommissionRecord2_Exception('You do not have access to change the Status of Commission Records');

      CommissionRecord2__c record = CommissionRecord2_Selector.allById( new Set<Id>{recordId} )[0];

//      if( record.Status__c == 'Approved' &&
//          !LGND_Utilities.CustomPermissions.canReOpenCommissionRecord )
//        throw new CommissionRecord2_Exception('You do not have permission to re-open an Approved Commission Record');

      record.Status__c = status;
      update record;

      return new CommissionWrapper.Record(
        CommissionRecord2_Selector.allById( new Set<Id>{record.Id} )[0]
      );
    }
    catch( Exception e )
    {
      throw new AuraHandledException( e.getMessage() );
    }
  }

  @AuraEnabled(Cacheable=true)
  public static List<CommissionWrapper.LineItem> fetchCommissionLineItems( String comRecId )
  {
    try
    {
      CommissionWrapper.LineItems result = new CommissionWrapper.LineItems();
      result.addAll(CommissionLineItem2_Selector.allByCommissionRecordId(comRecId));
      return result.groupKits();
    }
    catch( Exception e )
    {
      throw new AuraHandledException( e.getMessage() );
    }
  }

  @AuraEnabled(Cacheable=true)
  public static List<CommissionWrapper.Payment> fetchCommissionPayments( String comRecId )
  {
    return wrapPayments( CommissionPayment2_Selector.allByCommissionRecordId( comRecId ) );
  }

  @AuraEnabled
  public static CommissionWrapper.LineItem upsertLineItem( String lineItemJSON )
  {
    CommissionWrapper.LineItem lineItem =
      (CommissionWrapper.LineItem)JSON.deserialize(
        lineItemJSON,
        CommissionWrapper.LineItem.class
      );
    try
    {
      return lineItem.upsertLineItem();
    }
    catch( Exception e )
    {
      throw new AuraHandledException( e.getMessage() );
    }
  }

  @AuraEnabled
  public static void deleteLineItem( String recordId )
  {
    try
    {
      delete new CommissionLineItem2__c(Id = recordId);
    }
    catch( Exception e )
    {
      throw new AuraHandledException( e.getMessage() );
    }
  }

  @AuraEnabled
  public static List<CommissionWrapper.Payment> upsertCommissionPayments( String updatePaymentsJSON,
                                                                          String deletePaymentsJSON )
  {
    List<CommissionWrapper.Payment> payments =
      (List<CommissionWrapper.Payment>)JSON.deserialize(
        updatePaymentsJSON,
        List<CommissionWrapper.Payment>.class
      );
    List<CommissionPayment2__c> records = new List<CommissionPayment2__c>();
    for( CommissionWrapper.Payment p : payments )
    {
      records.add( p.toSObject() );
    }
    upsert records;
    if( deletePaymentsJSON != null )
    {
      List<CommissionWrapper.Payment> delete_payments =
        (List<CommissionWrapper.Payment>)JSON.deserialize(
          deletePaymentsJSON,
          List<CommissionWrapper.Payment>.class
        );
      if( delete_payments.size() > 0 )
      {
        List<CommissionPayment2__c> d_records = new List<CommissionPayment2__c>();
        for (CommissionWrapper.Payment p : delete_payments)
        {
          d_records.add(p.toSObject());
        }
        delete d_records;
      }
    }
    Set<Id> recordIds = LGND_Utilities.getIdSetFromList( (List<SObject>)records );
    return wrapPayments( CommissionPayment2_Selector.allByIds( recordIds ) );
  }

  @AuraEnabled
  public static CommissionWrapper.Payment paymentStatusChange( String recordId,
                                                               String status,
                                                               String disputeReason)
  {
    CommissionPayment2__c payment = new CommissionPayment2__c(
      Id = recordId,
      Status__c = status
    );
    try
    {
      update payment;
      payment = CommissionPayment2_Selector.allByIds( new Set<Id>{ payment.Id} )[0];
      if( status == 'Disputed' )
      {
        CommissionRecord2__c cRec = CommissionRecord2_Selector.allById(
          new Set<Id>
          {
            payment.Commission_Record2__c
          }
        )[0];
        CommissionRecord2_Service.makeDisputedChatter(cRec, disputeReason);
      }
      return new CommissionWrapper.Payment( payment );
    }
    catch( Exception e )
    {
      throw new AuraHandledException( e.getMessage() );
    }
  }

  private static List<CommissionRecord2__c> doCommissionRecordFetch( String recordId )
  {
    List<CommissionRecord2__c> results = new List<CommissionRecord2__c>();
    switch on LGND_Utilities.sObjectNameFromId( recordId )
    {
      when 'AcctSeed__Project__c'
      {
        results = CommissionRecord2_Selector.allByErpId( recordId );
      }
      when 'AcctSeed__Project_Task__c'
      {
        results = CommissionRecord2_Selector.allByProjectTaskId( recordId );
      }
      when 'CommissionRecord2__c'
      {
        results = CommissionRecord2_Selector.allById( new Set<Id>{recordId} );
      }
    }
    return results;
  }

  private static List<CommissionWrapper.Payment> wrapPayments( List<CommissionPayment2__c> commissionPayments )
  {
    System.debug( commissionPayments );
    List<CommissionWrapper.Payment> result = new List<CommissionWrapper.Payment>();
    for( CommissionPayment2__c cp : commissionPayments )
    {
      result.add( new CommissionWrapper.Payment( cp ) );
    }
    return result;
  }

}
