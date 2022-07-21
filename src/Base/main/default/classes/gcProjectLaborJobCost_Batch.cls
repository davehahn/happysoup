global without sharing class gcProjectLaborJobCost_Batch implements Database.Batchable<sObject> {
  set<Date> setDate;
  AcctSeed__Accounting_Period__c period;
  set<Id> setIdProject;

  global gcProjectLaborJobCost_Batch() {
    for (AcctSeed__Accounting_Period__c p : [
      SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c
      FROM AcctSeed__Accounting_Period__c
      WHERE AcctSeed__Status__c = 'Open' AND AcctSeed__Start_Date__c <= TODAY AND AcctSeed__End_Date__c >= TODAY
      LIMIT 1
    ]) {
      period = p;
      collectDates();
    }
  }

  global gcProjectLaborJobCost_Batch(Id idPeriod) {
    for (AcctSeed__Accounting_Period__c p : [
      SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c
      FROM AcctSeed__Accounting_Period__c
      WHERE AcctSeed__Status__c = 'Open' AND Id = :idPeriod
      LIMIT 1
    ]) {
      period = p;
      collectDates();
    }
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    String soql = 'SELECT Id FROM AcctSeed__Project__c WHERE Id IN :setIdProject';

    if (period == null)
      return Database.getQueryLocator(soql);

    setIdProject = new Set<Id>();

    for (AcctSeed__Transaction__c txn : [
      SELECT Id, AcctSeed__Project__c
      FROM AcctSeed__Transaction__c
      WHERE
        AcctSeed__Accounting_Period__c = :period.Id
        AND AcctSeed__GL_Account__r.Uniquefier__c = 'ProjectLabor'
        AND AcctSeed__Project__c != NULL
    ]) {
      setIdProject.add(txn.AcctSeed__Project__c);
    }

    for (AcctSeed__Time_Card_Day__c tcd : [
      SELECT Id, AcctSeed__Time_Card_Line__r.AcctSeed__Project__c
      FROM AcctSeed__Time_Card_Day__c
      WHERE AcctSeed__Date__c IN :setDate AND AcctSeed__Time_Card_Line__r.AcctSeed__Project__c != NULL
    ]) {
      setIdProject.add(tcd.AcctSeed__Time_Card_Line__r.AcctSeed__Project__c);
    }

    setIdProject.remove(null);

    return Database.getQueryLocator(soql);
  }

  global void execute(Database.BatchableContext BC, list<sObject> scope) {
    Set<Id> setIdTemp = new Set<Id>();
    for (sObject obj : scope)
      setIdTemp.add(obj.Id);
    gcProjectLaborJobCost.refreshJobCost(setIdTemp, setDate);
  }

  global void finish(Database.BatchableContext BC) {
    //if there are any unposted job-cost journal entries in the selected period, delete them
    if (period == null)
      return;

    list<AcctSeed__Journal_Entry__c> listJeDelete = new List<AcctSeed__Journal_Entry__c>();

    listJeDelete.addAll(
      [
        SELECT Id
        FROM AcctSeed__Journal_Entry__c
        WHERE
          Name = 'Job Cost Labor'
          AND AcctSeed__Status__c != 'Posted'
          AND AcctSeed__Accounting_Period__c = :period.Id
      ]
    );

    if (!listJeDelete.isEmpty())
      delete listJeDelete;
  }

  private void collectDates() {
    setDate = new Set<Date>();

    for (Integer i = 0; period.AcctSeed__Start_Date__c.addDays(i) <= period.AcctSeed__End_Date__c; i++) {
      setDate.add(period.AcctSeed__Start_Date__c.addDays(i));
    }
  }
}
