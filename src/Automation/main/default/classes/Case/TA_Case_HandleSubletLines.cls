/**
 * Created by dave on 2022-01-05.
 */

public without sharing class TA_Case_HandleSubletLines implements TriggerAction.AfterInsert, TriggerAction.AfterUpdate {
  public void afterInsert(List<Case> newList) {
    handleSublet(newList, null);
  }

  public void afterUpdate(List<Case> newList, List<Case> oldList) {
    Map<Id, Case> oldMap = new Map<Id, Case>(oldList);
    handleSublet(newList, oldMap);
  }

  private void handleSublet(List<Case> newList, Map<Id, Case> oldMap) {
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    Map<String, List<Case>> sortedCases = groupRequiredChanges(newList, OldMap);
    materials.addAll(handleNew(sortedCases.get('new')));
    materials.addAll(handleUpdate(sortedCases.get('update')));
    upsert materials;
    handleDelete(sortedCases.get('delete'));
  }

  private Map<String, List<Case>> groupRequiredChanges(List<Case> newList, Map<Id, Case> oldMap) {
    Id warrantyRtId = new Application_RecordType().getCaseRecordTypes().getWarrantyId();
    Map<String, List<Case>> result = new Map<String, List<Case>>{
      'new' => new List<Case>(),
      'update' => new List<Case>(),
      'delete' => new List<Case>()
    };
    for (Case c : newList) {
      Case oldCase = oldMap == null ? null : oldMap.get(c.Id);

      /** SUBLET INFORMATION IS POPULATED **/
      if (
        c.recordTypeId == warrantyRtId &&
        c.Sublet_Company__c != null &&
        c.Sublet_Price__c != null &&
        c.Warranty_ERP__c != null
      ) {
        /** NEW SUBLET INFORMATION **/
        if (
          oldCase == null ||
          (oldCase.Sublet_Company__c == null && (oldCase.Sublet_Price__c == null || oldCase.Sublet_Price__c == 0))
        ) {
          result.get('new').add(c);
        }
        /** SUBLET INFORMATION CHANGED **/
        if (
          oldCase != null &&
          ((oldCase.Sublet_Company__c != null &&
          c.Sublet_Company__c != null &&
          oldCase.Sublet_Company__c != c.Sublet_Company__c) ||
          (oldCase.Sublet_Price__c != null &&
          c.Sublet_Price__c != null &&
          oldCase.Sublet_Price__c != c.Sublet_Price__c))
        ) {
          result.get('update').add(c);
        }
      }

      /** SUBLET INFORMATION UNPOPULATED **/
      if (
        oldCase != null &&
        (c.Sublet_Price__c == null ||
        c.Sublet_Price__c == 0) &&
        c.Sublet_Company__c == null &&
        oldCase.Sublet_Price__c != null &&
        oldCase.Sublet_Price__c != 0 &&
        oldCase.Sublet_Company__c != null &&
        c.Warranty_ERP__c != null
      ) {
        result.get('delete').add(c);
      }
    }
    return result;
  }

  private List<AcctSeedERP__Material__c> handleNew(List<Case> cases) {
    List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();
    if (cases.size() == 0)
      return mats;

    String tn = '%' + ProjectTask_Service.warrantyPayableTaskName + '%';
    Map<Id, Case> erpId_Case_Map = new Map<Id, Case>();
    for (Case c : cases) {
      erpId_Case_Map.put(c.Warranty_ERP__c, c);
    }
    for (AcctSeed__Project__c p : [
      SELECT Id, (SELECT Id FROM AcctSeed__Project_Tasks__r WHERE Name LIKE :tn LIMIT 1)
      FROM AcctSeed__Project__c
      WHERE Id IN :erpId_Case_Map.keySet()
    ]) {
      if (p.AcctSeed__Project_Tasks__r.size() > 0) {
        Case c = erpId_Case_Map.get(p.Id);
        mats.add(
          CaseLexController.createSubletMaterialLine(
            p.Id,
            p.AcctSeed__Project_Tasks__r[0].Id,
            c.Sublet_Price__c,
            c.Sublet_Company__c
          )
        );
      }
    }
    return mats;
  }

  private List<AcctSeedERP__Material__c> handleUpdate(List<Case> cases) {
    if (cases.size() == 0)
      return new List<AcctSeedERP__Material__c>();

    Map<Id, Case> caseMap = new Map<Id, Case>();
    for (Case c : cases) {
      caseMap.put(c.Warranty_ERP__c, c);
    }
    AcctSeedERP__Material__c[] mats = [
      SELECT Id, AcctSeedERP__Project__c
      FROM AcctSeedERP__Material__c
      WHERE
        AcctSeedERP__Project__c = :caseMap.keySet()
        AND AcctSeedERP__Product__c = :Utility_Products__c.getOrgDefaults().Sublet__c
    ];
    for (AcctSeedERP__Material__c m : mats) {
      Case c = caseMap.get(m.AcctSeedERP__Project__c);
      m.AcctSeedERP__Comment__c = c.Sublet_Company__c;
      m.GMBLASERP__Unit_Price__c = c.Sublet_Price__c;
    }
    return mats;
  }

  private void handleDelete(List<Case> cases) {
    Set<Id> erpIds = new Set<Id>();
    for (Case c : cases) {
      erpIds.add(c.Warranty_ERP__c);
    }
    AcctSeedERP__Material__c[] mats = [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE
        AcctSeedERP__Project__c = :erpIds
        AND AcctSeedERP__Product__c = :Utility_Products__c.getOrgDefaults().Sublet__c
    ];
    delete mats;
  }
}
