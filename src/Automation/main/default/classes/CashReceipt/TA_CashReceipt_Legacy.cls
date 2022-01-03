/**
 * Created by Pooja on 2022-01-01.
 */

public inherited sharing class TA_CashReceipt_Legacy
        implements
                        TriggerAction.BeforeInsert,
                        TriggerAction.BeforeUpdate,
                        TriggerAction.BeforeDelete,
                        TriggerAction.AfterInsert,
                        TriggerAction.AfterUpdate,
                        TriggerAction.AfterDelete
{

    public void beforeInsert(
            List<AcctSeed__Cash_Receipt__c> newList
    )
    {
        if (!gcCashReceipt.disableTrigger)
        {

            gcCashReceipt.triggerHandler(
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
            List<AcctSeed__Cash_Receipt__c> newList
    )
    {
        if (!gcCashReceipt.disableTrigger)
        {
            Map<Id, AcctSeed__Cash_Receipt__c> newMap =
                    new Map<Id, AcctSeed__Cash_Receipt__c>(newList);
            gcCashReceipt.triggerHandler(
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
            List<AcctSeed__Cash_Receipt__c> newList,
            List<AcctSeed__Cash_Receipt__c> oldList
    )
    {
        if (!gcCashReceipt.disableTrigger)
        {
            Map<Id, AcctSeed__Cash_Receipt__c> newMap =
                    new Map<Id, AcctSeed__Cash_Receipt__c>(newList);
            Map<Id, AcctSeed__Cash_Receipt__c> oldMap =
                    new Map<Id, AcctSeed__Cash_Receipt__c>(oldList);
            gcCashReceipt.triggerHandler(
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
            List<AcctSeed__Cash_Receipt__c> newList,
            List<AcctSeed__Cash_Receipt__c> oldList
    )
    {
        if (!gcCashReceipt.disableTrigger)
        {
            Map<Id, AcctSeed__Cash_Receipt__c> newMap =
                    new Map<Id, AcctSeed__Cash_Receipt__c>(newList);
            Map<Id, AcctSeed__Cash_Receipt__c> oldMap =
                    new Map<Id, AcctSeed__Cash_Receipt__c>(oldList);
            gcCashReceipt.triggerHandler(
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
            List<AcctSeed__Cash_Receipt__c> oldList
    )
    {
        if (!gcCashReceipt.disableTrigger)
        {
            Map<Id, AcctSeed__Cash_Receipt__c> oldMap =
                    new Map<Id, AcctSeed__Cash_Receipt__c>(oldList);
            gcCashReceipt.triggerHandler(
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
            List<AcctSeed__Cash_Receipt__c> oldList
    )
    {
        if (!gcCashReceipt.disableTrigger)
        {
            Map<Id, AcctSeed__Cash_Receipt__c> oldMap =
                    new Map<Id, AcctSeed__Cash_Receipt__c>(oldList);
            gcCashReceipt.triggerHandler(
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