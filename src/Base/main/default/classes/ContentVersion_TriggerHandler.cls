/**
 * Created by dave on 2021-12-13.
 */

public without sharing class ContentVersion_TriggerHandler extends TriggerHandler {

  //  protected override void bulkBefore()
  //  {
  //    system.debug('[ContentVersion_TriggerHandler] bulk before');
  //  }

  //  protected override void bulkAfter()
  //  {
  //    system.debug('[ContentVersion_TriggerHandler] bulk after');
  //  }

  protected override void beforeInsert() {
    setPrivacy((List<ContentVersion>) Trigger.new);
  }

  protected override void beforeUpdate() {
    setPrivacy((List<ContentVersion>) Trigger.new);
  }

  //  protected override void beforeDelete()
  //  {
  //    system.debug('[ContentVersion_TriggerHandler] before delete');
  //  }

  //  protected override void afterInsert()
  //  {
  //    system.debug('[ContentVersion_TriggerHandler] after insert');
  //  }

  //  protected override void afterUpdate()
  //  {
  //    system.debug('[ContentVersion_TriggerHandler] after update');
  //  }

  //  protected override void afterDelete()
  //  {
  //    system.debug('[ContentVersion_TriggerHandler] after delete');
  //  }

  //  protected override void afterUndelete()
  //  {
  //    system.debug('[ContentVersion_TriggerHandler] after undelete');
  //  }

  //  protected override void finalActions()
  //  {
  //    system.debug('[ContentVersion_TriggerHandler] final actions');
  //  }

  private static void setPrivacy(
    List<ContentVersion> newList
  ) {
    for (ContentVersion cv : newList) {
//      if( cv.Visibility__c == null ){
//        cv.Visibility__c = 'Public';
//      }
      if (cv.Visibility__c == 'Private') {
        cv.SharingPrivacy = 'P';
      }
    }
  }
}