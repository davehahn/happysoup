/**
 * Created by dhavalmacbook on 20/01/22.
 */

public without sharing class TA_DealerOrderLine_DelMotorRequests implements TriggerAction.AfterDelete {
  public void afterDelete(List<Dealer_Order_Line__c> oldList) {
    Set<Id> motorRequestIds = new Set<Id>();

    for (Dealer_Order_Line__c dol : oldList) {
      if (dol.Dealer_Motor_Request__c != null)
        motorRequestIds.add(dol.Dealer_Motor_Request__c);
    }
    if (motorRequestIds.size() > 0)
      DealerOrderLine_Service.deleteDealerMotorRequests(motorRequestIds);
  }
}
