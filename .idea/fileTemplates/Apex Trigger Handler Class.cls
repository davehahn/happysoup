#parse("Apex File Header.cls")

public without sharing class ${NAME} extends TriggerHandler
{

    protected override void bulkBefore()
    {
        system.debug('[${NAME}] bulk before');
    }

    protected override void bulkAfter()
    {
        system.debug('[${NAME}] bulk after');
    }

    protected override void beforeInsert()
    {
        system.debug('[${NAME}] before insert');
    }

    protected override void beforeUpdate()
    {
        system.debug('[${NAME}] before update');
    }

    protected override void beforeDelete()
    {
        system.debug('[${NAME}] before delete');     
    }

    protected override void afterInsert()
    {
        system.debug('[${NAME}] after insert');      
    }

    protected override void afterUpdate()
    {
        system.debug('[${NAME}] after update');      
    }

    protected override void afterDelete()
    {
        system.debug('[${NAME}] after delete');        
    }

    protected override void afterUndelete()
    {
        system.debug('[${NAME}] after undelete');       
    }

    protected override void finalActions()
    {
        system.debug('[${NAME}] final actions');
    }
}