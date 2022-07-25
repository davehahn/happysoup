/**
 * Created by dhavalmacbook on 20/01/22.
 */

public without sharing class TA_DealerOrderLine_SetLineTotal implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate {
  public void beforeInsert(List<Dealer_Order_Line__c> newList) {
    DealerOrderLine_Service.setLineTotal(newList);
  }

  public void beforeUpdate(List<Dealer_Order_Line__c> newList, List<Dealer_Order_Line__c> oldList) {
    DealerOrderLine_Service.setLineTotal(newList);
  }
}
