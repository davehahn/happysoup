public without sharing class ProductConsumedTriggerHandler extends TriggerHandler
{

    /*protected override void bulkBefore()
    {
        system.debug('[ProductConsumedTriggerHandler] bulk before');
    }

    protected override void bulkAfter()
    {
        system.debug('[ProductConsumedTriggerHandler] bulk after');
    }*/

    protected override void beforeInsert()
    {
        system.debug('[ProductConsumedTriggerHandler] before insert ');
        ProductConsumed_CreationControl.creationControl((list<ProductConsumed>)Trigger.new);
    }

    /*protected override void beforeUpdate()
    {
        system.debug('[ProductConsumedTriggerHandler] before update');
    }

    protected override void beforeDelete()
    {
        system.debug('[ProductConsumedTriggerHandler] before delete');     
    }

    protected override void afterInsert()
    {
        system.debug('[ProductConsumedTriggerHandler] after insert');      
    }

    protected override void afterUpdate()
    {
        system.debug('[ProductConsumedTriggerHandler] after update');      
    }*/

    /*protected override void afterDelete()
    {
        system.debug('[ProductConsumedTriggerHandler] after delete');        
    }

    protected override void afterUndelete()
    {
        system.debug('[ProductConsumedTriggerHandler] after undelete');       
    }

    protected override void finalActions()
    {
        system.debug('[ProductConsumedTriggerHandler] final actions');
    }*/
}