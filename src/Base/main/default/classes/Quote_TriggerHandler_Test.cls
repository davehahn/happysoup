@isTest
private class Quote_TriggerHandler_Test {
  static Opportunity opp;
  static Quote quot;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account cust = Factory_Account.insertCustomerAccounts(1)[0];
    Opportunity o = Factory_Opportunity.insertOpportunity(cust, Test.getStandardPricebookId());
    Quote q = Factory_Quote.insertQuote(o);
  }

  private static void init() {
    opp = [SELECT Id, (SELECT Id FROM Quotes) FROM Opportunity LIMIT 1];
    quot = opp.Quotes[0];
  }

  private static Trade_In_Record__c insertTradeInRecord(Id qId) {
    Trade_In_Record__c tr = new Trade_In_Record__c(
      Quote__c = qId,
      Opportunity__c = opp.Id,
      Total_Value__c = 1000,
      Lien_Amount__c = 500,
      IsSyncing__c = false
    );
    insert tr;
    return tr;
  }

  @isTest
  static void trigger_Test() {
    init();
    quot.Name = 'Test Quote 2';
    update quot;
  }

  @isTest
  static void syncTradeInRecord_Test() {
    init();
    Trade_In_Record__c tr = insertTradeInRecord(quot.Id);
    opp.SyncedQuoteId = quot.Id;
    update opp;
    Trade_In_Record__c tr_after = [SELECT Id, IsSyncing__c FROM Trade_In_Record__c WHERE Id = :tr.Id];
    System.assertEquals(false, tr.IsSyncing__c);
    System.assertEquals(true, tr_after.IsSyncing__c);
  }

  @isTest
  static void deleteTradeInRecord_Test() {
    init();
    Id qId = quot.Id;
    Trade_In_Record__c tr = insertTradeInRecord(quot.Id);
    delete quot;
    Trade_In_Record__c[] trs = [SELECT Id FROM Trade_In_Record__c WHERE Quote__c = :qId];
    System.assertEquals(0, trs.size());
  }
}
