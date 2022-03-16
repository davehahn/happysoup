/**
 * Created by dave on 2022-01-25.
 */

public without sharing class TA_CommPay2_SetInitialValues implements TriggerAction.BeforeInsert
{
  public void beforeInsert( List<CommissionPayment2__c> newList ){
    CommissionPayment2_Service.setInitialValues( newList );
  }
}