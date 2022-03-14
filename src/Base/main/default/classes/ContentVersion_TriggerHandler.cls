/**
 * Created by dave on 2021-12-13.
 */

public without sharing class ContentVersion_TriggerHandler extends TriggerHandler {

  protected override void beforeInsert() {
    setPrivacy((List<ContentVersion>) Trigger.new);
  }

  protected override void beforeUpdate() {
    setPrivacy((List<ContentVersion>) Trigger.new);
  }

  private static void setPrivacy(List<ContentVersion> newList) {
    for (ContentVersion cv : newList) {
      if( cv.Visibility__c == null ){
        cv.Visibility__c = 'Public';
      }
      if (cv.Visibility__c == 'Private') {
        cv.SharingPrivacy = 'P';
      }
    }
  }
}
