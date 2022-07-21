/**
 * Created by dave on 2022-03-04.
 */
/* TODO: REQUIRES UNIT TEST */
public inherited sharing class TA_Outbound_CreateInvTransactionsFSL implements TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {
  public void afterInsert(List<AcctSeedERP__Outbound_Inventory_Movement__c> newList) {
    ProductItemTransaction_Service.createTransactions((List<SObject>) newList);
  }
  public void afterUpdate(
    List<AcctSeedERP__Outbound_Inventory_Movement__c> newList,
    List<AcctSeedERP__Outbound_Inventory_Movement__c> oldList
  ) {
    Map<Id, SObject> oldMap = new Map<Id, SObject>(oldList);
    List<SObject> required = new List<SObject>();
    for (SObject movement : newList) {
      if (movement.get('AcctSeedERP__Quantity__c') != oldMap.get(movement.Id).get('AcctSeedERP__Quantity__c')) {
        SObject movementNew = movement.clone(false, true);
        movementNew.put(
          'AcctSeedERP__Quantity__c',
          ((Decimal) movement.get('AcctSeedERP__Quantity__c') -
          (Decimal) oldMap.get(movement.Id).get('AcctSeedERP__Quantity__c'))
        );
        required.add((SObject) movement);
      }
    }
    if (!required.isEmpty()) {
      ProductItemTransaction_Service.createTransactions(required);
    }
  }
  public void afterDelete(List<AcctSeedERP__Outbound_Inventory_Movement__c> oldList) {
    ProductItemTransaction_Service.createTransactions((List<SObject>) oldList);
  }
}
