/**
 * Created by dave on 2022-06-15.
 */

public without sharing class TA_Lead_SetClosestPartner implements TriggerAction.AfterInsert, TriggerAction.AfterUpdate {
  public void afterInsert(List<Lead> newList) {
    shouldSetClosestPartner(newList, null);
  }

  public void afterUpdate(List<Lead> newList, List<Lead> oldList) {
    Map<Id, Lead> oldMap = new Map<Id, Lead>(oldList);
    shouldSetClosestPartner(newList, oldMap);
  }

  private static void shouldSetClosestPartner(List<Lead> listNew, Map<Id, Lead> oldMap) {
    Set<Id> setClosestPartner = new Set<Id>();
    for (Lead l : listNew) {
      // during INSERT
      if (oldMap == null) {
        if (
          Lead_Service.factoryAccountIdByLeadSource.containsKey(l.LeadSource) ||
          l.PostalCode != null ||
          l.IP_City__c != null ||
          l.hubspot_IP_City_Lead__c != null
        ) {
          setClosestPartner.add(l.Id);
        }
      }
      // during UPDATE
      if (oldMap != null) {
        //skip any records with a specific Lead Source found in Lead_Source_Assignment__mdt
        if (Lead_Service.factoryAccountIdByLeadSource.containsKey(l.LeadSource))
          continue;

        Lead oldLead = oldMap.get(l.Id);
        if (
          (l.PostalCode != null &&
          l.PostalCode != oldLead.PostalCode) ||
          (l.IP_City__c != null &&
          l.IP_City__c != oldLead.IP_City__c) ||
          (l.hubspot_IP_City_Lead__c != null &&
          l.hubspot_IP_City_Lead__c != oldLead.IP_City__c)
        ) {
          setClosestPartner.add(l.Id);
        }
      }
    }
    if (setClosestPartner.size() > 0) {
      System.enqueueJob(new ClosestPartnerQueue(setClosestPartner));
    }
  }
}
