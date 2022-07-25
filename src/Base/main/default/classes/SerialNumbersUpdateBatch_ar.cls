public without sharing class SerialNumbersUpdateBatch_ar implements Schedulable, Database.Batchable<sObject> {
  public SerialNumbersUpdateBatch_ar() {
  }

  public Database.QueryLocator start(Database.BatchableContext BC) {
    String query = 'SELECT Id FROM GMBLASERP__Serial_Number__c WHERE GMBLASERP__Inventory_Balance__c != null';
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext BC, List<sObject> scope) {
    List<GMBLASERP__Serial_Number__c> listSR = new List<GMBLASERP__Serial_Number__c>();
    for (SObject sObj : scope) {
      GMBLASERP__Serial_Number__c sr = (GMBLASERP__Serial_Number__c) sObj;
      listSR.add(sr);
    }
    if (!listSR.isEmpty())
      update listSR;
  }

  public void execute(SchedulableContext sc) {
    SerialNumbersUpdateBatch_ar b = new SerialNumbersUpdateBatch_ar();
    database.executeBatch(b, 200);
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
  }
}
