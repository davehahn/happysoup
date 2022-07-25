/**
 * Created by dave on 2022-01-04.
 */

public without sharing class TA_Case_PartnerWarrantyDefaults implements TriggerAction.BeforeInsert {
  public void beforeInsert(List<Case> newList) {
    Id warrantyRtId = new Application_RecordType().getCaseRecordTypes().getWarrantyId();
    try {
      User u = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
      for (Case c : newList) {
        if (c.RecordTypeId == warrantyRtId) {
          c.Price_Book__c = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;
        }
        if (c.ContactId == null) {
          c.ContactId = u.ContactId;
        }
      }
    } catch (Exception e) {
      //In case trigger is invoked by automatedProcess and UserInfo will fail
    }
  }
}
