/**
 * Created by Legend on 10/5/22.
 */

public inherited sharing class TA_Shipment_CreateBilling implements TriggerAction.AfterUpdate {
  public void afterUpdate(List<AcctSeedERP__Shipment__c> newList, List<AcctSeedERP__Shipment__c> oldList) {
    set<Id> setIdShip = new Set<Id>();
    Map<Id, AcctSeedERP__Shipment__c> oldMap = new Map<Id, AcctSeedERP__Shipment__c>(oldList);

    for (AcctSeedERP__Shipment__c ship : newList) {
      AcctSeedERP__Shipment__c oldShip = oldMap.get(ship.Id);
      if (ship.AcctSeedERP__Status__c == 'Shipped' && oldShip.AcctSeedERP__Status__c != 'Shipped') {
        setIdShip.add(ship.Id);
      }
    }
    if (!setIdShip.isEmpty())
      Shipment_Service.createBilling(setIdShip);
  }
}
