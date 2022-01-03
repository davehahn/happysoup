/**
 * Created by Pooja on 2022-01-01.
 */

public inherited sharing class TA_PurchaseOrder_Legacy
        implements
                        TriggerAction.BeforeInsert,
                        TriggerAction.BeforeUpdate,
                        TriggerAction.BeforeDelete,
                        TriggerAction.AfterInsert,
                        TriggerAction.AfterUpdate,
                        TriggerAction.AfterDelete
{

    public void beforeInsert(
            List<AcctSeedERP__Purchase_Order__c> newList
    )
    {
        if (!gcPurchaseOrder.disableTrigger)
        {

            gcPurchaseOrder.triggerHandler(
                    null,
                    null,
                    newList,
                    true,
                    true,
                    false,
                    false
            );
        }
    }

    public void afterInsert(
            List<AcctSeedERP__Purchase_Order__c> newList
    )
    {
        if (!gcPurchaseOrder.disableTrigger)
        {
            Map<Id, AcctSeedERP__Purchase_Order__c> newMap =
                    new Map<Id, AcctSeedERP__Purchase_Order__c>(newList);
            gcPurchaseOrder.triggerHandler(
                    null,
                    newMap,
                    newList,
                    false,
                    true,
                    false,
                    false
            );
        }
    }

    public void beforeUpdate(
            List<AcctSeedERP__Purchase_Order__c> newList,
            List<AcctSeedERP__Purchase_Order__c> oldList
    )
    {
        if (!gcPurchaseOrder.disableTrigger)
        {
            Map<Id, AcctSeedERP__Purchase_Order__c> newMap =
                    new Map<Id, AcctSeedERP__Purchase_Order__c>(newList);
            Map<Id, AcctSeedERP__Purchase_Order__c> oldMap =
                    new Map<Id, AcctSeedERP__Purchase_Order__c>(oldList);
            gcPurchaseOrder.triggerHandler(
                    oldMap,
                    newMap,
                    newList,
                    true,
                    false,
                    true,
                    false
            );
        }
    }

    public void afterUpdate(
            List<AcctSeedERP__Purchase_Order__c> newList,
            List<AcctSeedERP__Purchase_Order__c> oldList
    )
    {
        if (!gcPurchaseOrder.disableTrigger)
        {
            Map<Id, AcctSeedERP__Purchase_Order__c> newMap =
                    new Map<Id, AcctSeedERP__Purchase_Order__c>(newList);
            Map<Id, AcctSeedERP__Purchase_Order__c> oldMap =
                    new Map<Id, AcctSeedERP__Purchase_Order__c>(oldList);
            gcPurchaseOrder.triggerHandler(
                    oldMap,
                    newMap,
                    newList,
                    false,
                    false,
                    true,
                    false
            );
        }
    }

    public void beforeDelete(
            List<AcctSeedERP__Purchase_Order__c> oldList
    )
    {
        if (!gcPurchaseOrder.disableTrigger)
        {
            Map<Id, AcctSeedERP__Purchase_Order__c> oldMap =
                    new Map<Id, AcctSeedERP__Purchase_Order__c>(oldList);
            gcPurchaseOrder.triggerHandler(
                    oldMap,
                    null,
                    null,
                    true,
                    false,
                    false,
                    true
            );
        }
    }

    public void afterDelete(
            List<AcctSeedERP__Purchase_Order__c> oldList
    )
    {
        if (!gcPurchaseOrder.disableTrigger)
        {
            Map<Id, AcctSeedERP__Purchase_Order__c> oldMap =
                    new Map<Id, AcctSeedERP__Purchase_Order__c>(oldList);
            gcPurchaseOrder.triggerHandler(
                    oldMap,
                    null,
                    null,
                    false,
                    false,
                    false,
                    true
            );
        }
    }

}