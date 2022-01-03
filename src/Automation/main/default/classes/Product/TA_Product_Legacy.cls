/**
 * Created by Pooja on 2022-01-01.
 */

public inherited sharing class TA_Product_Legacy
        implements
                        TriggerAction.BeforeInsert,
                        TriggerAction.BeforeUpdate,
                        TriggerAction.BeforeDelete,
                        TriggerAction.AfterInsert,
                        TriggerAction.AfterUpdate,
                        TriggerAction.AfterDelete
{

    public void beforeInsert(
            List<Product2> newList
    )
    {
        if (!gcProduct.disableTrigger)
        {

            gcProduct.triggerHandler(
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
            List<Product2> newList
    )
    {
        if (!gcProduct.disableTrigger)
        {
            Map<Id, Product2> newMap =
                    new Map<Id, Product2>(newList);
            gcProduct.triggerHandler(
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
            List<Product2> newList,
            List<Product2> oldList
    )
    {
        if (!gcProduct.disableTrigger)
        {
            Map<Id, Product2> newMap =
                    new Map<Id, Product2>(newList);
            Map<Id, Product2> oldMap =
                    new Map<Id, Product2>(oldList);
            gcProduct.triggerHandler(
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
            List<Product2> newList,
            List<Product2> oldList
    )
    {
        if (!gcProduct.disableTrigger)
        {
            Map<Id, Product2> newMap =
                    new Map<Id, Product2>(newList);
            Map<Id, Product2> oldMap =
                    new Map<Id, Product2>(oldList);
            gcProduct.triggerHandler(
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
            List<Product2> oldList
    )
    {
        if (!gcProduct.disableTrigger)
        {
            Map<Id, Product2> oldMap =
                    new Map<Id, Product2>(oldList);
            gcProduct.triggerHandler(
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
            List<Product2> oldList
    )
    {
        if (!gcProduct.disableTrigger)
        {
            Map<Id, Product2> oldMap =
                    new Map<Id, Product2>(oldList);
            gcProduct.triggerHandler(
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