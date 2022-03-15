/**
 * Created by aminrubel on 2019-08-30.
 */
/* TODO: CONVERT TO TRIGGER ACTION FRAMEWORK AND ADD TESTS */
public without sharing class ProductItemTransaction_TriggerHandler extends TriggerHandler {

    protected override void bulkBefore() {
        system.debug('[ProductItemTransactionController] bulk before');
    }

    protected override void bulkAfter() {
        system.debug('[ProductItemTransactionController] bulk after');
    }

    protected override void beforeInsert() {
        system.debug('[ProductItemTransactionController] before insert');
        Inventory_Service.validateForSerializedItems(Trigger.new);
    }

    protected override void beforeUpdate() {
        system.debug('[ProductItemTransactionController] before update');
    }

    protected override void beforeDelete() {
        system.debug('[ProductItemTransactionController] before delete');
    }

    protected override void afterInsert() {
        system.debug('[ProductItemTransactionController] after insert');
        Inventory_Service.createAcctSeedInv(Trigger.new);
    }

    protected override void afterUpdate() {
        system.debug('[ProductItemTransactionController] after update');
    }

    protected override void finalActions() {
        system.debug('[ProductItemTransactionController] final actions');
    }
}