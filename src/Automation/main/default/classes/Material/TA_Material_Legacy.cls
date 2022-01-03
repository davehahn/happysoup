/**
 * Created by Pooja on 2022-01-01.
 */

public inherited sharing class TA_Material_Legacy
        implements
                        TriggerAction.BeforeInsert,
                        TriggerAction.BeforeUpdate,
                        TriggerAction.BeforeDelete,
                        TriggerAction.AfterInsert,
                        TriggerAction.AfterUpdate,
                        TriggerAction.AfterDelete
{

    public void beforeInsert(
            List<AcctSeedERP__Material__c> newList
    )
    {
        if (!gcMaterial.disableTrigger)
        {

            gcMaterial.triggerHandler(
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
            List<AcctSeedERP__Material__c> newList
    )
    {
        if (!gcMaterial.disableTrigger)
        {
            Map<Id, AcctSeedERP__Material__c> newMap =
                    new Map<Id, AcctSeedERP__Material__c>(newList);
            gcMaterial.triggerHandler(
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
            List<AcctSeedERP__Material__c> newList,
            List<AcctSeedERP__Material__c> oldList
    )
    {
        if (!gcMaterial.disableTrigger)
        {
            Map<Id, AcctSeedERP__Material__c> newMap =
                    new Map<Id, AcctSeedERP__Material__c>(newList);
            Map<Id, AcctSeedERP__Material__c> oldMap =
                    new Map<Id, AcctSeedERP__Material__c>(oldList);
            gcMaterial.triggerHandler(
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
            List<AcctSeedERP__Material__c> newList,
            List<AcctSeedERP__Material__c> oldList
    )
    {
        if (!gcMaterial.disableTrigger)
        {
            Map<Id, AcctSeedERP__Material__c> newMap =
                    new Map<Id, AcctSeedERP__Material__c>(newList);
            Map<Id, AcctSeedERP__Material__c> oldMap =
                    new Map<Id, AcctSeedERP__Material__c>(oldList);
            gcMaterial.triggerHandler(
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
            List<AcctSeedERP__Material__c> oldList
    )
    {
        if (!gcMaterial.disableTrigger)
        {
            Map<Id, AcctSeedERP__Material__c> oldMap =
                    new Map<Id, AcctSeedERP__Material__c>(oldList);
            gcMaterial.triggerHandler(
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
            List<AcctSeedERP__Material__c> oldList
    )
    {
        if (!gcMaterial.disableTrigger)
        {
            Map<Id, AcctSeedERP__Material__c> oldMap =
                    new Map<Id, AcctSeedERP__Material__c>(oldList);
            gcMaterial.triggerHandler(
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