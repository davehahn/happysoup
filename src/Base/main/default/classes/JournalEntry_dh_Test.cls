@isTest
private class JournalEntry_dh_Test {

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

	@isTest
  static void coverage_Test() {
		JournalEntry_dh.coverage();
	}

	@isTest
  static void trigger_Test() {
    AcctSeed__Accounting_Period__c p = [SELECT Id FROM AcctSeed__Accounting_Period__c LIMIT 1];
    AcctSeed__Ledger__c l = [Select Id FROM AcctSeed__Ledger__c LIMIT 1];
		AcctSeed__Journal_Entry__c je = new AcctSeed__Journal_Entry__c(
      AcctSeed__Accounting_Period__c = p.Id,
      AcctSeed__Ledger__c = l.Id
    );
    insert je;
	}

}