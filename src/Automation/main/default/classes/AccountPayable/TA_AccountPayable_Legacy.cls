/**
 * Created by dave on 2021-12-22.
 */

public inherited sharing class TA_AccountPayable_Legacy
        implements
                        TriggerAction.BeforeInsert,
                        TriggerAction.BeforeUpdate,
                        TriggerAction.BeforeDelete,
                        TriggerAction.AfterInsert,
                        TriggerAction.AfterUpdate,
                        TriggerAction.AfterDelete
{

    public void beforeInsert(
            List<AcctSeed__Account_Payable__c> newList
    )
    {
        if (!gcAccountPayable.disableTrigger)
        {

            gcAccountPayable.triggerHandler(
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
            List<AcctSeed__Account_Payable__c> newList
    )
    {
        if (!gcAccountPayable.disableTrigger)
        {
            Map<Id, AcctSeed__Account_Payable__c> newMap =
                    new Map<Id, AcctSeed__Account_Payable__c>(newList);
            gcAccountPayable.triggerHandler(
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
            List<AcctSeed__Account_Payable__c> newList,
            List<AcctSeed__Account_Payable__c> oldList
    )
    {
        if (!gcAccountPayable.disableTrigger)
        {
            Map<Id, AcctSeed__Account_Payable__c> newMap =
                    new Map<Id, AcctSeed__Account_Payable__c>(newList);
            Map<Id, AcctSeed__Account_Payable__c> oldMap =
                    new Map<Id,AcctSeed__Account_Payable__c>(oldList);
            gcAccountPayable.triggerHandler(
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
            List<AcctSeed__Account_Payable__c> newList,
            List<AcctSeed__Account_Payable__c> oldList
    )
    {
        if (!gcAccountPayable.disableTrigger)
        {
            Map<Id, AcctSeed__Account_Payable__c> newMap =
                    new Map<Id, AcctSeed__Account_Payable__c>(newList);
            Map<Id, AcctSeed__Account_Payable__c> oldMap =
                    new Map<Id, AcctSeed__Account_Payable__c>(oldList);
            gcAccountPayable.triggerHandler(
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
            List<AcctSeed__Account_Payable__c> oldList
    )
    {
        if (!gcAccountPayable.disableTrigger)
        {
            Map<Id, AcctSeed__Account_Payable__c> oldMap =
                    new Map<Id, AcctSeed__Account_Payable__c>(oldList);
            gcAccountPayable.triggerHandler(
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
            List<AcctSeed__Account_Payable__c> oldList
    )
    {
        if (!gcAccountPayable.disableTrigger)
        {
            Map<Id, AcctSeed__Account_Payable__c> oldMap =
                    new Map<Id, AcctSeed__Account_Payable__c>(oldList);
            gcAccountPayable.triggerHandler(
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