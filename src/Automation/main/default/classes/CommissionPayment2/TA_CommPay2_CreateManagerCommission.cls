/**
 * Created by dave on 2022-01-25.
 */

public without sharing class TA_CommPay2_CreateManagerCommission implements TriggerAction.AfterInsert
{
  public void afterInsert( List<CommissionPayment2__c> newList){
    Set<Id> setIdCommPay = new Set<Id>();
    for(CommissionPayment2__c cp : newList){
      if(cp.Type__c != 'Manager')
        setIdCommPay.add(cp.Id);
    }
    if(!setIdCommPay.isEmpty()) {
      CommissionPayment2_Service.createManagersCommissionFuture(setIdCommPay);
    }
  }
}