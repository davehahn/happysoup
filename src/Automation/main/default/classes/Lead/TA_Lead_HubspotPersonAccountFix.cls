/**
 * Created by dave on 2022-06-15.
 */

/**
 * This is for Hubspot since it submits Leads with Company populated
 * to something like [none], which still counts as something so when we
 * use the default convert lead mechanism, it creates a Business Account
 * since the Company field is not null
 **/
public without sharing class TA_Lead_HubspotPersonAccountFix implements TriggerAction.BeforeInsert {
  public void beforeInsert(List<Lead> newList) {
    for (Lead l : newList) {
      if (l.isPersonAccount__c == true) {
        l.Company = null;
      }
    }
  }
}
