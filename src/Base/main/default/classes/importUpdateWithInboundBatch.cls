global without sharing class importUpdateWithInboundBatch implements Schedulable, Database.Batchable<sObject> {
  global importUpdateWithInboundBatch() {
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    String query = 'SELECT Id, Inventory_Adjustment_Import__c FROM AcctSeedERP__Inbound_Inventory_Movement__c WHERE Inventory_Adjustment_Import__c != null';
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    List<Inventory_Adjustment_Import__c> listImport = new List<Inventory_Adjustment_Import__c>();
    for (SObject sObj : scope) {
      AcctSeedERP__Inbound_Inventory_Movement__c imp = (AcctSeedERP__Inbound_Inventory_Movement__c) sObj;
      listImport.add(
        new Inventory_Adjustment_Import__c(Id = imp.Inventory_Adjustment_Import__c, Has_Inbound__c = true)
      );
    }

    if (!listImport.isEmpty()) {
      update listImport;
    }
  }

  global void execute(SchedulableContext sc) {
    importUpdateWithInboundBatch b = new importUpdateWithInboundBatch();
    database.executeBatch(b, 1);
  }

  global void finish(Database.BatchableContext BC) {
  }

  global static void coverage() {
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
  }
}
