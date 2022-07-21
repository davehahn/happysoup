/**
 * Created by dave on 2020-08-04.
 */

public without sharing class PartnerBookingOrder_TriggerHandler extends TriggerHandler {
  //  protected override void bulkBefore()
  //  {
  //    system.debug('[PartnerBookingOrder_TriggerHandler] bulk before');
  //  }

  //  protected override void bulkAfter()
  //  {
  //    system.debug('[PartnerBookingOrder_TriggerHandler] bulk after');
  //  }

  protected override void beforeInsert() {
    for (Partner_Booking_Order__c pbo : (List<Partner_Booking_Order__c>) Trigger.new) {
      pbo.Uniquifier__c = pbo.Name + '-' + pbo.Account__c;
    }
  }

  //  protected override void beforeUpdate()
  //  {
  //    system.debug('[PartnerBookingOrder_TriggerHandler] before update');
  //  }

  //  protected override void beforeDelete()
  //  {
  //    system.debug('[PartnerBookingOrder_TriggerHandler] before delete');
  //  }

  //  protected override void afterInsert()
  //  {
  //    system.debug('[PartnerBookingOrder_TriggerHandler] after insert');
  //  }

  //  protected override void afterUpdate()
  //  {
  //    system.debug('[PartnerBookingOrder_TriggerHandler] after update');
  //  }

  //  protected override void afterDelete()
  //  {
  //    system.debug('[PartnerBookingOrder_TriggerHandler] after delete');
  //  }

  //  protected override void afterUndelete()
  //  {
  //    system.debug('[PartnerBookingOrder_TriggerHandler] after undelete');
  //  }

  //  protected override void finalActions()
  //  {
  //    system.debug('[PartnerBookingOrder_TriggerHandler] final actions');
  //  }
}
