/**
 * Created by dave on 2022-01-03.
 */

public inherited sharing class TA_CasePart_DeleteMaterials implements TriggerAction.BeforeDelete {
  public void beforeDelete(List<Case_Part__c> oldList) {
    Map<Id, Case_Part__c> oldMap = new Map<Id, Case_Part__c>(oldList);
    List<AcctSeedERP__Material__c> mats = Material_Selector.allByCasePartIds(oldMap.keySet());
    delete mats;
  }
}
