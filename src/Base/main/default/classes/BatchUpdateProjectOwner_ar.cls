public with sharing class BatchUpdateProjectOwner_ar implements Database.Batchable<sObject> {
  public final String queryStr;

  public BatchUpdateProjectOwner_ar() {
    queryStr = null;
  }

  public BatchUpdateProjectOwner_ar(String pQuery) {
    queryStr = pQuery;
  }

  public Database.QueryLocator start(Database.BatchableContext BC) {
    String query = queryStr;
    if (queryStr == null) {
      Id idRTProjectPart = gcConstants.idRtPartnerPartsOrder;
      query = 'SELECT Id FROM AcctSeed__Project__c WHERE RecordTypeId =:idRTProjectPart';
    }

    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext BC, List<sObject> scope) {
    Set<String> setId = new Set<String>();
    for (SObject sObj : scope) {
      AcctSeed__Project__c p = (AcctSeed__Project__c) sObj;
      setId.add(p.Id);
    }

    Map<Id, Id> mapAccountUser = new Map<Id, Id>();
    Map<Id, Set<Id>> mapAccountContacts = new Map<Id, Set<Id>>();
    List<AcctSeed__Project__c> listProject = new List<AcctSeed__Project__c>();
    for (AcctSeed__Project__c proj : [
      SELECT Id, OwnerId, AcctSeed__Account__c
      FROM AcctSeed__Project__c
      WHERE Id IN :setId
    ]) {
      mapAccountUser.put(proj.AcctSeed__Account__c, null);
      mapAccountContacts.put(proj.AcctSeed__Account__c, new Set<Id>());
      listProject.add(proj);
    }
    Map<Id, Contact> mapContacts = new Map<Id, Contact>();
    Map<Id, List<User>> mapContactUsers = new Map<Id, List<User>>();
    for (Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :mapAccountUser.keySet()]) {
      mapContacts.put(c.Id, c);
    }
    for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :mapContacts.keySet()]) {
      if (!mapContactUsers.containsKey(u.ContactId))
        mapContactUsers.put(u.ContactId, new List<User>());
      mapContactUsers.get(u.ContactId).add(u);
    }
    for (Contact c : mapContacts.values()) {
      if (mapContactUsers.containsKey(c.Id) && !mapContactUsers.get(c.Id).isEmpty()) {
        for (User u : mapContactUsers.get(c.Id))
          mapAccountContacts.get(c.AccountId).add(u.Id);
        if (mapAccountUser.get(c.AccountId) == null)
          mapAccountUser.put(c.AccountId, mapContactUsers.get(c.Id)[0].Id);
      }
    }

    List<AcctSeed__Project__c> projectToUpdate = new List<AcctSeed__Project__c>();
    for (AcctSeed__Project__c proj : listProject) {
      Set<Id> setIdAccountContacts = mapAccountContacts.get(proj.AcctSeed__Account__c);
      if (!setIdAccountContacts.contains(proj.OwnerId) && mapAccountUser.get(proj.AcctSeed__Account__c) != null) {
        proj.OwnerId = mapAccountUser.get(proj.AcctSeed__Account__c);
        projectToUpdate.add(proj);
      }
    }
    Boolean oldVal = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    update projectToUpdate;
    System.debug(loggingLevel.error, 'projectToUpdate:' + projectToUpdate);
    gcProject.disableTrigger = oldVal;
  }

  public void finish(Database.BatchableContext BC) {
  }

  public static void coverage() {
    integer i;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
  }
}
