/**
 * Created by Pooja on 2022-01-01.
 */

public inherited sharing class TA_User_Legacy
        implements
                        TriggerAction.BeforeInsert,
                        TriggerAction.BeforeUpdate,
                        TriggerAction.BeforeDelete,
                        TriggerAction.AfterInsert,
                        TriggerAction.AfterUpdate,
                        TriggerAction.AfterDelete
{

    public void beforeInsert(
            List<User> newList
    )
    {
        if (!gcUser.disableTrigger)
        {

            gcUser.triggerHandler(
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
            List<User> newList
    )
    {
        if (!gcUser.disableTrigger)
        {
            Map<Id, User> newMap =
                    new Map<Id, User>(newList);
            gcUser.triggerHandler(
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
            List<User> newList,
            List<User> oldList
    )
    {
        if (!gcUser.disableTrigger)
        {
            Map<Id, User> newMap =
                    new Map<Id, User>(newList);
            Map<Id, User> oldMap =
                    new Map<Id, User>(oldList);
            gcUser.triggerHandler(
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
            List<User> newList,
            List<User> oldList
    )
    {
        if (!gcUser.disableTrigger)
        {
            Map<Id, User> newMap =
                    new Map<Id, User>(newList);
            Map<Id, User> oldMap =
                    new Map<Id, User>(oldList);
            gcUser.triggerHandler(
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
            List<User> oldList
    )
    {
        if (!gcUser.disableTrigger)
        {
            Map<Id, User> oldMap =
                    new Map<Id, User>(oldList);
            gcUser.triggerHandler(
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
            List<User> oldList
    )
    {
        if (!gcUser.disableTrigger)
        {
            Map<Id, User> oldMap =
                    new Map<Id, User>(oldList);
            gcUser.triggerHandler(
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