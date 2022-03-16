/**
 * Created by dhavalmacbook on 20/01/22.
 */

public without sharing class TA_DealerOrderLine_HandlePartnerPro implements TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {

  public void afterInsert(List<Dealer_Order_Line__c> newList) {
    System.debug('RUNNING TA_DealerOrderLine_HandlePartnerPro.afterInsert');
    DealerOrderLine_Service.handlePartnerProgram(newList);
  }

  public void afterUpdate(List<Dealer_Order_Line__c> newLIst, List<Dealer_Order_Line__c> oldList) {
    System.debug('RUNNING TA_DealerOrderLine_HandlePartnerPro.afterUpdate');
    DealerOrderLine_Service.handlePartnerProgram(newList);
  }

  public void afterDelete(List<Dealer_Order_Line__c> oldList) {
    System.debug('RUNNING TA_DealerOrderLine_HandlePartnerPro.AfterDelete');
    DealerOrderLine_Service.handlePartnerProgram(oldList);
  }
}
