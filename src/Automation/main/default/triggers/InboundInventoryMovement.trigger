trigger InboundInventoryMovement on AcctSeedERP__Inbound_Inventory_Movement__c (before insert,
        before update,
        before delete,
        after insert,
        after update,
        after delete,
        after undelete )
{
    new MetadataTriggerHandler().run();
}