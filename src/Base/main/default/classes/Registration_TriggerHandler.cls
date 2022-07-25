/**
 * Created by dave on 2019-10-07.
 */

public without sharing class Registration_TriggerHandler extends TriggerHandler {
  protected override void bulkBefore() {
    system.debug('[Registration_TriggerHandler] bulk before');
  }

  protected override void bulkAfter() {
    system.debug('[Registration_TriggerHandler] bulk after');
  }

  protected override void beforeInsert() {
    system.debug('[Registration_TriggerHandler] before insert');
    Registration_Domain.setDefaults((List<Registration__c>) Trigger.new);
  }

  protected override void beforeUpdate() {
    system.debug('[Registration_TriggerHandler] before update');
  }

  protected override void beforeDelete() {
    system.debug('[Registration_TriggerHandler] before delete');
  }

  protected override void afterInsert() {
    system.debug('[Registration_TriggerHandler] after insert');
    Registration_Helper.executeAfterInsert(
      (Map<Id, Registration__c>) Trigger.newMap,
      (Map<Id, Registration__c>) Trigger.oldMap
    );
  }

  protected override void afterUpdate() {
    system.debug('[Registration_TriggerHandler] after update');
    Registration_Helper.setRegistrationDateOnSerial(
      (List<Registration__c>) Trigger.new,
      (Map<Id, Registration__c>) Trigger.oldMap
    );
  }

  protected override void afterDelete() {
    system.debug('[Registration_TriggerHandler] after delete');
  }

  protected override void afterUndelete() {
    system.debug('[Registration_TriggerHandler] after undelete');
  }

  protected override void finalActions() {
    system.debug('[Registration_TriggerHandler] final actions');
  }
}
