/**
 * Created by dave on 2022-01-12.
 */

public inherited sharing class TA_CommRec2_CreateInitialPayments implements TriggerAction.AfterInsert
{
  public void afterInsert( List<CommissionRecord2__c> newList){
    Map<Id, CommissionRecord2__c> newMap = new Map<Id, CommissionRecord2__c>(newList);
    CommissionPayment2_Service.createInitialPayments( newMap.keySet(), 'Standard' );
  }
}