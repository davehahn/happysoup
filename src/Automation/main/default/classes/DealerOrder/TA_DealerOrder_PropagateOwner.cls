public without sharing class TA_DealerOrder_PropagateOwner implements TriggerAction.AfterUpdate {
  public void afterUpdate(List<Dealer_Order__c> newList, List<Dealer_Order__c> oldList) {
    Map<Id, Dealer_Order__c> oldMap = new Map<Id, Dealer_Order__c>(oldList);
    Map<Id, Id> ownerChanged = new Map<Id, Id>();

    for (Dealer_Order__c newOrder : newList) {
      Dealer_Order__c oldOrder = oldMap.get(newOrder.Id);

      if (oldOrder.OwnerId != newOrder.OwnerId) {
        ownerChanged.put(newOrder.Id, newOrder.OwnerId);
      }
    }

    DealerOrder_Service.propagateOwner(ownerChanged);
  }
}
