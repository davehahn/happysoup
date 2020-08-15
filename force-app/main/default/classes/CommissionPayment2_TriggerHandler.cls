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
    Set<Id> setIdCommissionRecord = new Set<Id>();
    Map<Id,CommissionPayment2__c> managerCP = new Map<Id,CommissionPayment2__c>();
    // Adding all CR ids to find out existing managers record;
    for(CommissionPayment2__c cp : (List<CommissionPayment2__c>) Trigger.new){
      setIdCommissionRecord.add(cp.Commission_Record2__c);
    }
    // Checking for Manages Payment
    Set<Id> setIdCRWithManagers = CommissionPayment2_Service.checkManagersCommission(setIdCommissionRecord);
    System.debug('setIdCRWithManagers');
    System.debug(setIdCRWithManagers);
    // loop and validate
    for(CommissionPayment2__c cp : (List<CommissionPayment2__c>) Trigger.new){
      /// Creating false Managers list to check and validate
      if(!setIdCRWithManagers.contains(cp.Commission_Record2__c))
        managerCP.put(cp.Commission_Record2__c, new CommissionPayment2__c(Commission_Record2__c = cp.Commission_Record2__c, Type__c = 'Manager'));
    }
    // Check with false records
    CommissionPayment2_Service.setInitialValues(managerCP.values());
    // now lets check to see if any payments have zero amount. Then we will discard those
    // List<CommissionPayment2__c> cpManagersListTOInsert = new List<CommissionPayment2__c>();
    Set<Id> setIdManagersCP = new Set<Id>();
    for(CommissionPayment2__c cp : managerCP.values()){
      if(cp.Gross_Margin_Payment_Percent__c != 0 && cp.Gross_Margin_Payment_Percent__c != null){
        setIdManagersCP.add(cp.Commission_Record2__c);
      }
    }
    // Now do the actual managers payments
    if(!setIdManagersCP.isEmpty())
      CommissionPayment2_Service.createInitialPayments( setIdCommissionRecord, 'Manager' );
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