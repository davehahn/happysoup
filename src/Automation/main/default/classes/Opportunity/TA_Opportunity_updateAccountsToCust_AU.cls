/**
 * Created by dhavalmacbook on 27/01/22.
 */

public without sharing class TA_Opportunity_updateAccountsToCust_AU implements TriggerAction.AfterUpdate {
  public void afterUpdate(List<Opportunity> newList, List<Opportunity> oldList) {
    Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>(oldList);
    Set<Id> nowCustomerAccountIds = new Set<Id>();
    for (Opportunity opp : newList) {
      Opportunity oOpp = oldMap.get(opp.Id);

      if (opp.Approved__c && !oOpp.Approved__c) {
        nowCustomerAccountIds.add(opp.AccountId);
      }
    }

    if (nowCustomerAccountIds.size() > 0) {
      Opportunity_Service.updateAccountsToCustomers(nowCustomerAccountIds);
    }
  }
}
