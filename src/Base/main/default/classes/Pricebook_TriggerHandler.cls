/**
 * Created by dave on 2021-11-02.
 */

public without sharing class Pricebook_TriggerHandler extends TriggerHandler {
  //  protected override void bulkBefore()
  //  {
  //    system.debug('[Pricebook_TriggerHandler] bulk before');
  //  }

  //  protected override void bulkAfter()
  //  {
  //    system.debug('[Pricebook_TriggerHandler] bulk after');
  //  }

  protected override void beforeInsert() {
    setUniquefier();
  }

  protected override void beforeUpdate() {
    setUniquefier();
  }

  //  protected override void beforeDelete()
  //  {
  //    system.debug('[Pricebook_TriggerHandler] before delete');
  //  }

  //  protected override void afterInsert()
  //  {
  //    system.debug('[Pricebook_TriggerHandler] after insert');
  //  }

  //  protected override void afterUpdate()
  //  {
  //    system.debug('[Pricebook_TriggerHandler] after update');
  //  }

  //  protected override void afterDelete()
  //  {
  //    system.debug('[Pricebook_TriggerHandler] after delete');
  //  }

  //  protected override void afterUndelete()
  //  {
  //    system.debug('[Pricebook_TriggerHandler] after undelete');
  //  }

  //  protected override void finalActions()
  //  {
  //    system.debug('[Pricebook_TriggerHandler] final actions');
  //  }

  private void setUniquefier() {
    Application_RecordType appRt = new Application_RecordType();
    for (Pricebook2 pb : (List<Pricebook2>) Trigger.new) {
      String rtName = 'none';
      String vName = 'v.0';
      String salesYear = String.valueOf(Date.today().year());
      if (pb.RecordTypeId != null) {
        rtName = appRt.getDeveloperNameById(pb.RecordTypeId);
      }
      if (pb.Version__c != null) {
        vName = 'v.' + String.valueOf(pb.Version__c);
      }
      if (pb.Sales_Year__c != null) {
        salesYear = String.valueOf(pb.Sales_Year__c);
      }
      pb.Uniquefier__c = salesYear + '_' + rtName + '_' + vName;
    }
  }
}
