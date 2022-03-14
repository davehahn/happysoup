trigger PurchaseOrder on AcctSeedERP__Purchase_Order__c (before insert,
        before update,
        before delete,
        after insert,
        after update,
        after delete,
        after undelete )
{
    new MetadataTriggerHandler().run();
}