/**
 * Created by Pooja on 2022-01-01.
 */

public inherited sharing class TA_InventoryAdjustment_Legacy implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate, TriggerAction.BeforeDelete, TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {
  public void beforeInsert(List<GMBLASERP__Inventory_Adjustment__c> newList) {
    if (!gcInventoryAdjustment.disableTrigger) {
      gcInventoryAdjustment.triggerHandler(null, null, newList, true, true, false, false);
    }
  }

  public void afterInsert(List<GMBLASERP__Inventory_Adjustment__c> newList) {
    if (!gcInventoryAdjustment.disableTrigger) {
      Map<Id, GMBLASERP__Inventory_Adjustment__c> newMap = new Map<Id, GMBLASERP__Inventory_Adjustment__c>(newList);
      gcInventoryAdjustment.triggerHandler(null, newMap, newList, false, true, false, false);
    }
  }

  public void beforeUpdate(
    List<GMBLASERP__Inventory_Adjustment__c> newList,
    List<GMBLASERP__Inventory_Adjustment__c> oldList
  ) {
    if (!gcInventoryAdjustment.disableTrigger) {
      Map<Id, GMBLASERP__Inventory_Adjustment__c> newMap = new Map<Id, GMBLASERP__Inventory_Adjustment__c>(newList);
      Map<Id, GMBLASERP__Inventory_Adjustment__c> oldMap = new Map<Id, GMBLASERP__Inventory_Adjustment__c>(oldList);
      gcInventoryAdjustment.triggerHandler(oldMap, newMap, newList, true, false, true, false);
    }
  }

  public void afterUpdate(
    List<GMBLASERP__Inventory_Adjustment__c> newList,
    List<GMBLASERP__Inventory_Adjustment__c> oldList
  ) {
    if (!gcInventoryAdjustment.disableTrigger) {
      Map<Id, GMBLASERP__Inventory_Adjustment__c> newMap = new Map<Id, GMBLASERP__Inventory_Adjustment__c>(newList);
      Map<Id, GMBLASERP__Inventory_Adjustment__c> oldMap = new Map<Id, GMBLASERP__Inventory_Adjustment__c>(oldList);
      gcInventoryAdjustment.triggerHandler(oldMap, newMap, newList, false, false, true, false);
    }
  }

  public void beforeDelete(List<GMBLASERP__Inventory_Adjustment__c> oldList) {
    if (!gcInventoryAdjustment.disableTrigger) {
      Map<Id, GMBLASERP__Inventory_Adjustment__c> oldMap = new Map<Id, GMBLASERP__Inventory_Adjustment__c>(oldList);
      gcInventoryAdjustment.triggerHandler(oldMap, null, null, true, false, false, true);
    }
  }

  public void afterDelete(List<GMBLASERP__Inventory_Adjustment__c> oldList) {
    if (!gcInventoryAdjustment.disableTrigger) {
      Map<Id, GMBLASERP__Inventory_Adjustment__c> oldMap = new Map<Id, GMBLASERP__Inventory_Adjustment__c>(oldList);
      gcInventoryAdjustment.triggerHandler(oldMap, null, null, false, false, false, true);
    }
  }
}
