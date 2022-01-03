trigger LotExchange on Lot_Exchange__c (before insert,
        before update,
        before delete,
        after insert,
        after update,
        after delete,
        after undelete )
{
    new MetadataTriggerHandler().run();
}