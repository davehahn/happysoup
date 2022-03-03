/* TODO: CONVERT TO TRIGGER ACTION FRAMEWORK */
trigger ProductTransferTrigger on ProductTransfer (after delete, after insert, after undelete, after update, before delete, before insert, before update)
{
    new ProductTransferTriggerHandler().run();
}