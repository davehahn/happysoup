@isTest
private class gcTest_CashDisbursement {

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

	static testMethod void coverage_Test()
	{
    gcCashDisbursement.coverage();
  }

  static testMethod void trigger_Test()
  {
    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    Account supplier = Factory_Account.insertSupplierAccounts(1)[0];
    AcctSeed__Accounting_Period__c period = [SELECT Id FROM AcctSeed__Accounting_Period__c LIMIT 1];
    AcctSeed__GL_Account__c bank = [SELECT Id
                                    FROM AcctSeed__GL_Account__c
                                    WHERE AcctSeed__Bank__c = true
                                    LIMIT 1];
    AcctSeed__Cash_Disbursement_Batch__c cdb = new AcctSeed__Cash_Disbursement_Batch__c(
      Name = 'Test'
    );
    insert cdb;
    insert new AcctSeed__Cash_Disbursement__c(
      AcctSeed__Amount__c = 10,
      AcctSeed__Accounting_Period__c = period.Id,
      AcctSeed__Bank_Account__c = bank.Id,
      AcctSeed__Cash_Disbursement_Batch__c = cdb.Id,
      AcctSeed__Ledger__c = ledger.Id,
      AcctSeed__Vendor__c = supplier.Id
    );
  }
}