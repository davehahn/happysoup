/**
 * Created by dhavalmacbook on 27/01/22.
 */

public without sharing class TA_Opportunity_setPrimaryContactInfo_AI implements TriggerAction.AfterInsert {
  public void afterInsert(List<Opportunity> newList) {
    Map<Id, Opportunity> newMap = new Map<Id, Opportunity>(newList);
    Opportunity[] opps = [
      SELECT
        Id,
        Delivery_Date__c,
        Pickup_Location__c,
        On_Water_Orientation__c,
        BoatId__c,
        BoatId__r.Name,
        Name,
        StageName,
        Probability,
        AccountId,
        Invoice_Document_Id__c,
        Account.isPersonAccount,
        Account.PersonEmail,
        Account.AccountEmail__c,
        Account.PersonContactId,
        createdFromLeadConversion__c
      FROM Opportunity
      WHERE Id IN :newMap.keySet()
    ];

    Opportunity_Service.setPrimaryContactInformation(opps);
  }
}
