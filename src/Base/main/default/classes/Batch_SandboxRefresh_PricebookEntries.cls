global class Batch_SandboxRefresh_PricebookEntries implements Database.Batchable<sObject> {
  String query;

  global Batch_SandboxRefresh_PricebookEntries() {
    query = 'SELECT Id FROM PricebookEntry';
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    for (sObject obj : scope) {
      obj.put('Dump_Id__c', obj.Id);
    }
    update scope;
  }

  global void finish(Database.BatchableContext BC) {
    //AsyncApexJob a = [SELECT Id,
    //                           Status,
    //                           ExtendedStatus,
    //                           NumberOfErrors,
    //                           JobItemsProcessed,
    //                           TotalJobItems,
    //                           CreatedBy.Email
    //                    FROM AsyncApexJob
    //                    WHERE Id =:BC.getJobId()];

    //  Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //  String[] toAddresses = new String[] {a.CreatedBy.Email};
    //  mail.setToAddresses(toAddresses);
    //  mail.setSubject('Sandbox Refresh Batch Jobs - ' + a.Status);
    //  mail.setPlainTextBody( 'Sandbox Refresh Batch jobs complete' );
    //  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
  }
}
