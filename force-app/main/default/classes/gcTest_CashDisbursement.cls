@isTest
private class gcTest_CashDisbursement {

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
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

    AcctSeed__Cash_Disbursement__c cd = new AcctSeed__Cash_Disbursement__c(
      AcctSeed__Amount__c = 10,
      AcctSeed__Accounting_Period__c = period.Id,
      AcctSeed__Bank_Account__c = bank.Id,
      AcctSeed__Cash_Disbursement_Batch__c = cdb.Id,
      AcctSeed__Ledger__c = ledger.Id,
      AcctSeed__Vendor__c = supplier.Id,
      AcctSeed__Status__c = 'Approved',
      AcctSeed__Disbursement_Date__c = Date.today(),
      AcctSeed__Debit_GL_Account__c = gcConstants.idGlAPayable
    );
    Test.startTest();
    insert cd;
    AcctSeed.PostResult[] postResults = AcctSeed.CashDisbursementPostService.postCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{cd});
    for (AcctSeed.PostResult theResult : postResults) {
      if (!theResult.isSuccess) {
        for (AcctSeed.PostResult.PostErrorResult errorResult: theResult.errors) {
          throw new gcException('Cash Disbursement was not posted. Please try again. REASON: ' + errorResult.message);
        }
      }
    }
    AcctSeed__Cash_Disbursement__c cdUpd = [SELECT  Id, GMBLASG__Posted__c, AcctSeed__Disbursement_Date__c FROM AcctSeed__Cash_Disbursement__c WHERE Id=:cd.Id][0];
    System.assertEquals( cdUpd.GMBLASG__Posted__c, true);
    cdUpd.AcctSeed__Disbursement_Date__c = Date.today()-1;
    try {
      update cd;
    }catch( Exception ex ){
      System.assertEquals( ex.getMessage().contains('You cannot update the Posting Status, Payment Status'),true);
    }
    Test.stopTest();
  }
}