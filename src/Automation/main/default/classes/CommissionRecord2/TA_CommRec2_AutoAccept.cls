/**
 * Created by dave on 2022-01-13.
 */

public without sharing class TA_CommRec2_AutoAccept implements TriggerAction.AfterUpdate {
  public void afterUpdate(List<CommissionRecord2__c> newList, List<CommissionRecord2__c> oldList) {
    Map<Id, CommissionRecord2__c> oldMap = new Map<Id, CommissionRecord2__c>(oldList);
    Set<Id> approvalExpired = new Set<Id>();
    for (CommissionRecord2__c rec : newList) {
      CommissionRecord2__c oldRec = oldMap.get(rec.Id);
      if (rec.Sales_Acceptable_Expired__c && !oldRec.Sales_Acceptable_Expired__c) {
        approvalExpired.add(rec.Id);
      }
    }
    if (approvalExpired.size() > 0) {
      CommissionPayment2_Service.autoAcceptForCommissionRecords(approvalExpired);
    }
  }
}
