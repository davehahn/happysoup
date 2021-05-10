/**
 * Created by dave on 2020-02-18.
 */

public without sharing class CommissionPayment2_TriggerHandler extends TriggerHandler
{

//  protected override void bulkBefore()
//  {
//  }

//  protected override void bulkAfter()
//  {
//  }

  protected override void beforeInsert()
  {
    CommissionPayment2_Service.setInitialValues( (List<CommissionPayment2__c>)Trigger.new );
  }

//  protected override void beforeUpdate()
//  {
//  }

//  protected override void beforeDelete()
//  {
//  }

  protected override void afterInsert()
  {
    Set<Id> setIdCommPay = new Set<Id>();
    for(CommissionPayment2__c cp : (List<CommissionPayment2__c>) Trigger.new){
      if(cp.Type__c != 'Manager')
        setIdCommPay.add(cp.Id);
    }
    if(!setIdCommPay.isEmpty()) {
      System.debug(setIdCommPay);
      CommissionPayment2_Service.createManagersCommissionFuture(setIdCommPay);
    }
  }

  protected override void afterUpdate()
  {
    Map<Id, CommissionPayment2__c> oldMap = (Map<Id, CommissionPayment2__c>)Trigger.oldMap;
    List<CommissionRecord2__c> disputedRecords = new List<CommissionRecord2__c>();
    Map<Id, Set<Id>> resolvedComRecId_paymentsMap = new Map<Id, Set<Id>>();
    for( CommissionPayment2__c payment : (List<CommissionPayment2__c>)Trigger.new )
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