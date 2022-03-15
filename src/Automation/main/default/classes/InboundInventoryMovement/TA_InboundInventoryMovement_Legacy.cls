/**
 * Created by Pooja on 2022-01-01.
 */

public inherited sharing class TA_InboundInventoryMovement_Legacy implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate, TriggerAction.BeforeDelete, TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {
  public void beforeInsert(List<AcctSeedERP__Inbound_Inventory_Movement__c> newList) {
    if (!gcInboundInventoryMovement.disableTrigger) {
      gcInboundInventoryMovement.triggerHandler(null, null, newList, true, true, false, false);
    }
  }

  public void afterInsert(List<AcctSeedERP__Inbound_Inventory_Movement__c> newList) {
    if (!gcInboundInventoryMovement.disableTrigger) {
      Map<Id, AcctSeedERP__Inbound_Inventory_Movement__c> newMap = new Map<Id, AcctSeedERP__Inbound_Inventory_Movement__c>(
        newList
      );
      gcInboundInventoryMovement.triggerHandler(null, newMap, newList, false, true, false, false);
    }
  }

  public void beforeUpdate(
    List<AcctSeedERP__Inbound_Inventory_Movement__c> newList,
    List<AcctSeedERP__Inbound_Inventory_Movement__c> oldList
  ) {
    if (!gcInboundInventoryMovement.disableTrigger) {
      Map<Id, AcctSeedERP__Inbound_Inventory_Movement__c> newMap = new Map<Id, AcctSeedERP__Inbound_Inventory_Movement__c>(
        newList
      );
      Map<Id, AcctSeedERP__Inbound_Inventory_Movement__c> oldMap = new Map<Id, AcctSeedERP__Inbound_Inventory_Movement__c>(
        oldList
      );
      gcInboundInventoryMovement.triggerHandler(oldMap, newMap, newList, true, false, true, false);
    }
  }

  public void afterUpdate(
    List<AcctSeedERP__Inbound_Inventory_Movement__c> newList,
    List<AcctSeedERP__Inbound_Inventory_Movement__c> oldList
  ) {
    if (!gcInboundInventoryMovement.disableTrigger) {
      Map<Id, AcctSeedERP__Inbound_Inventory_Movement__c> newMap = new Map<Id, AcctSeedERP__Inbound_Inventory_Movement__c>(
        newList
      );
      Map<Id, AcctSeedERP__Inbound_Inventory_Movement__c> oldMap = new Map<Id, AcctSeedERP__Inbound_Inventory_Movement__c>(
        oldList
      );
      gcInboundInventoryMovement.triggerHandler(oldMap, newMap, newList, false, false, true, false);
    }
  }

  public void beforeDelete(List<AcctSeedERP__Inbound_Inventory_Movement__c> oldList) {
    if (!gcInboundInventoryMovement.disableTrigger) {
      Map<Id, AcctSeedERP__Inbound_Inventory_Movement__c> oldMap = new Map<Id, AcctSeedERP__Inbound_Inventory_Movement__c>(
        oldList
      );
      gcInboundInventoryMovement.triggerHandler(oldMap, null, null, true, false, false, true);
    }
  }

  public void afterDelete(List<AcctSeedERP__Inbound_Inventory_Movement__c> oldList) {
    if (!gcInboundInventoryMovement.disableTrigger) {
      Map<Id, AcctSeedERP__Inbound_Inventory_Movement__c> oldMap = new Map<Id, AcctSeedERP__Inbound_Inventory_Movement__c>(
        oldList
      );
      gcInboundInventoryMovement.triggerHandler(oldMap, null, null, false, false, false, true);
    }
  }
}
