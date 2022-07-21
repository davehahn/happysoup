/**
 * Created by dave on 2022-01-12.
 */

public without sharing class TA_CommRec2_CreateInitialLines implements TriggerAction.AfterInsert {
  public void afterInsert(List<CommissionRecord2__c> newList) {
    CommissionLineItem2_Service.createDefaultLineItems(newList);
  }
}
