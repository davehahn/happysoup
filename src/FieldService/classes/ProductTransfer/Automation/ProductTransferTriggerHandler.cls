/* TODO: CONVERT TO TRIGGER ACTION FRAMEWORK */
public without sharing class ProductTransferTriggerHandler extends TriggerHandler
{

  /*protected override void bulkBefore()
  {
      system.debug('[ProductTransferTriggerHandler] bulk before');
  }

  protected override void bulkAfter()
  {
      system.debug('[ProductTransferTriggerHandler] bulk after');
  }*/

  protected override void beforeInsert()
  {
    system.debug('[ProductTransferTriggerHandler] before insert');
    ProductTransfer_CreationControl.creationControl((list<ProductTransfer>)Trigger.new);
    ProductTransfers transfers = new ProductTransfers( Trigger.new, null );
    transfers.onBeforeInsert();
  }

  protected override void beforeUpdate()
  {
    system.debug('[ProductTransferTriggerHandler] before update');
    //ProductTransfer_UpdateControl.updateControl((list<ProductTransfer>)Trigger.new, (Map<Id,ProductTransfer>)Trigger.oldMap);
  }

  protected override void beforeDelete()
  {
    system.debug('[ProductTransferTriggerHandler] before delete');
    //ProductTransfer_DeleteControl.deleteControl((Map<Id,ProductTransfer>)Trigger.oldMap);
  }

  protected override void afterInsert()
  {
    ProductTransfers transfers = new ProductTransfers( Trigger.new, null );
    transfers.onAfterInsert();
  }
  /*
  protected override void afterUpdate()
  {
      system.debug('[ProductTransferTriggerHandler] after update');
  }*/

  /*protected override void afterDelete()
  {
      system.debug('[ProductTransferTriggerHandler] after delete');
  }

  protected override void afterUndelete()
  {
      system.debug('[ProductTransferTriggerHandler] after undelete');
  }

  protected override void finalActions()
  {
      system.debug('[ProductTransferTriggerHandler] final actions');
  }*/
}