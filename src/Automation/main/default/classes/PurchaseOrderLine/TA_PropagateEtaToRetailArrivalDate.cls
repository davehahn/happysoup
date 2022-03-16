/**
 * Created by dave on 2021-07-27.
 */

public without sharing class TA_PropagateEtaToRetailArrivalDate implements TriggerAction.AfterInsert, TriggerAction.AfterUpdate {
  public void afterInsert(List<AcctSeedERP__Purchase_Order_Line__c> newList) {
    Set<Id> deliverDateSet = new Set<Id>();
    for (AcctSeedERP__Purchase_Order_Line__c pol : newList) {
      if (pol.deliverDate__c != null) {
        deliverDateSet.add(pol.Id);
      }
    }
    if (deliverDateSet.size() > 0) {
      PurchaseOrderLine_Service.propagateDeliveryDate(deliverDateSet);
    }
  }

  public void afterUpdate(
    List<AcctSeedERP__Purchase_Order_Line__c> newList,
    List<AcctSeedERP__Purchase_Order_Line__c> oldList
  ) {
    Map<Id, AcctSeedERP__Purchase_Order_Line__c> oldMap = new Map<Id, AcctSeedERP__Purchase_Order_Line__c>(oldList);
    Set<Id> hasDeliverDateChanges = new Set<Id>();
    for (AcctSeedERP__Purchase_Order_Line__c pol : newList) {
      AcctSeedERP__Purchase_Order_Line__c oldPol = oldMap.get(pol.Id);
      if (
        pol.deliverDate__c != oldPol.deliverDate__c ||
        pol.AcctSeedERP__Project__c != oldPol.AcctSeedERP__Project__c
      ) {
        hasDeliverDateChanges.add(pol.Id);
      }
    }
    if (hasDeliverDateChanges.size() > 0) {
      PurchaseOrderLine_Service.propagateDeliveryDate(hasDeliverDateChanges);
    }
  }
}
