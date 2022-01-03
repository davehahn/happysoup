/**
 * Created by Pooja on 2022-01-01.
 */

public inherited sharing class TA_LotExchange_Legacy
        implements
                        TriggerAction.BeforeInsert,
                        TriggerAction.BeforeUpdate,
                        TriggerAction.BeforeDelete,
                        TriggerAction.AfterInsert,
                        TriggerAction.AfterUpdate,
                        TriggerAction.AfterDelete
{

    public void beforeInsert(
            List<Lot_Exchange__c> newList
    )
    {
        if (!gcLotExchange.disableTrigger)
        {

            gcLotExchange.triggerHandler(
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
            List<Lot_Exchange__c> newList
    )
    {
        if (!gcLotExchange.disableTrigger)
        {
            Map<Id, Lot_Exchange__c> newMap =
                    new Map<Id, Lot_Exchange__c>(newList);
            gcLotExchange.triggerHandler(
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
            List<Lot_Exchange__c> newList,
            List<Lot_Exchange__c> oldList
    )
    {
        if (!gcLotExchange.disableTrigger)
        {
            Map<Id, Lot_Exchange__c> newMap =
                    new Map<Id, Lot_Exchange__c>(newList);
            Map<Id, Lot_Exchange__c> oldMap =
                    new Map<Id, Lot_Exchange__c>(oldList);
            gcLotExchange.triggerHandler(
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
            List<Lot_Exchange__c> newList,
            List<Lot_Exchange__c> oldList
    )
    {
        if (!gcLotExchange.disableTrigger)
        {
            Map<Id, Lot_Exchange__c> newMap =
                    new Map<Id, Lot_Exchange__c>(newList);
            Map<Id, Lot_Exchange__c> oldMap =
                    new Map<Id, Lot_Exchange__c>(oldList);
            gcLotExchange.triggerHandler(
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
            List<Lot_Exchange__c> oldList
    )
    {
        if (!gcLotExchange.disableTrigger)
        {
            Map<Id, Lot_Exchange__c> oldMap =
                    new Map<Id, Lot_Exchange__c>(oldList);
            gcLotExchange.triggerHandler(
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
            List<Lot_Exchange__c> oldList
    )
    {
        if (!gcLotExchange.disableTrigger)
        {
            Map<Id, Lot_Exchange__c> oldMap =
                    new Map<Id, Lot_Exchange__c>(oldList);
            gcLotExchange.triggerHandler(
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