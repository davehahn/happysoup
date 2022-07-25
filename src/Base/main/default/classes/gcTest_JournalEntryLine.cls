@isTest
private class gcTest_JournalEntryLine {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static testMethod void coverageTest() {
    gcJournalEntryLine.coverage();
  }

  static testMethod void trigger_Test() {
    AcctSeed__Accounting_Period__c period = [SELECT Id FROM AcctSeed__Accounting_Period__c LIMIT 1];
    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    AcctSeed__GL_Account__c glAccount = [SELECT Id FROM AcctSeed__GL_Account__c LIMIT 1];
    AcctSeed__Journal_Entry__c je = new AcctSeed__Journal_Entry__c(
      AcctSeed__Accounting_Period__c = period.Id,
      AcctSeed__Ledger__c = ledger.Id
    );
    insert je;
    AcctSeed__Journal_Entry_Line__c jel = new AcctSeed__Journal_Entry_Line__c(
      AcctSeed__Journal_Entry__c = je.Id,
      AcctSeed__GL_Account__c = glAccount.Id,
      AcctSeed__Credit__c = 100
    );
    insert jel;
  }
}
