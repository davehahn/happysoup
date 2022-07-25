global class DealerPartOrdersStatement_Batch implements Database.Batchable<sObject> {
  global Database.QueryLocator start(Database.BatchableContext BC) {
    String query = 'SELECT Id FROM Account WHERE RecordType.Name = \'Dealer\' AND Is_Internal__c = false AND Active__c = true AND Type = \'Dealer\'';
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<Account> accounts) {
    System.debug(accounts);
    List<Id> accountIds = new List<Id>();
    for (Account a : accounts) {
      accountIds.add(a.Id);
    }
    ContentDocumentLink[] statements = DealerPartOrdersStatement_Controller.attachStatements(accountIds);
    DealerPartOrdersStatement_Controller.notifyDealers(statements);
  }

  global void finish(Database.BatchableContext BC) {
  }
}
