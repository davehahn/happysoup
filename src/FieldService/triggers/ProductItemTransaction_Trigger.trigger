/**
 * Created by aminrubel on 2019-08-28.
 */
/* TODO: CONVERT TO TRIGGER ACTION FRAMEWORK */
trigger ProductItemTransaction_Trigger on ProductItemTransaction (before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    new ProductItemTransaction_TriggerHandler().run();
}
