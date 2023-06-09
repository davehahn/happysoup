@isTest
private class gcTest_CashDisbursement {
  static AcctSeed__Cash_Disbursement__c cd;
  static AcctSeed__GL_Account__c bank;
  static final Integer checkNum = 12345;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    AcctSeed__Cash_Disbursement_Batch__c cdb = new AcctSeed__Cash_Disbursement_Batch__c(Name = 'Test');
    insert cdb;
  }

  static void init(Id debitGlAccount) {
    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    AcctSeed__Cash_Disbursement_Batch__c cdb = [SELECT Id FROM AcctSeed__Cash_Disbursement_Batch__c LIMIT 1][0];
    AcctSeed__Accounting_Period__c period = [SELECT Id FROM AcctSeed__Accounting_Period__c LIMIT 1];
    bank = [SELECT Id FROM AcctSeed__GL_Account__c WHERE AcctSeed__Bank__c = TRUE AND Uniquefier__c = 'CASH' LIMIT 1];
    Account supplier = Factory_Account.insertSupplierAccounts(1)[0];
    cd = new AcctSeed__Cash_Disbursement__c(
      AcctSeed__Amount__c = 10,
      AcctSeed__Accounting_Period__c = period.Id,
      AcctSeed__Bank_Account__c = bank.Id,
      AcctSeed__Cash_Disbursement_Batch__c = cdb.Id,
      AcctSeed__Ledger__c = ledger.Id,
      AcctSeed__Vendor__c = supplier.Id,
      AcctSeed__Status__c = 'Approved',
      AcctSeed__Disbursement_Date__c = Date.today(),
      AcctSeed__Cash_Flow_Category__c = gcConstants.idGlRevenueCF,
      AcctSeed__Debit_GL_Account__c = debitGlAccount,
      AcctSeed__Check_Number__c = checkNum
    );
  }

  static AcctSeed__Cash_Disbursement__c cloneCD( String fieldName , Object value) {
    AcctSeed__Cash_Disbursement__c clone =  cd.clone(false, true);
    clone.put(fieldName, value);
    return clone;
  }

  @IsTest
  static void insert_update_Unique_Check_Number_Test() {
    init(null);
    AcctSeed__Cash_Disbursement__c cd_iResult;
    AcctSeed__Cash_Disbursement__c cd_uResult;
    Test.startTest();
    insert cd;
    cd_iResult = [SELECT Id, Unique_Check_Number__c FROM AcctSeed__Cash_Disbursement__c WHERE Id = :cd.Id];
    cd.AcctSeed__Check_Number__c = null;
    update cd;
    cd_uResult = [SELECT Id, Unique_Check_Number__c FROM AcctSeed__Cash_Disbursement__c WHERE Id = :cd.Id];

    Test.stopTest();

    System.assertEquals(bank.Id + String.valueOf(checkNum), cd_iResult.Unique_Check_Number__c);
    System.assertEquals(null, cd_uResult.Unique_Check_Number__c);
  }

  static testMethod void trigger_TestInsertPost() {
    init(null);
    Test.startTest();
    insert cd;
    AcctSeed.PostResult[] postResults = AcctSeed.CashDisbursementPostService.postCashDisbursements(
      new List<AcctSeed__Cash_Disbursement__c>{ cd }
    );
    String errorMsg = '';
    for (AcctSeed.PostResult theResult : postResults) {
      if (!theResult.isSuccess) {
        for (AcctSeed.PostResult.PostErrorResult errorResult : theResult.errors) {
          errorMsg += errorResult.message;
        }
      }
    }
    System.assertEquals(cd.GMBLASG__Posted__c, false, errorMsg);
    Test.stopTest();
  }

  static testMethod void trigger_TestInsert() {
    init(gcConstants.idGlCustomerRefund);
    Test.startTest();
    insert cd;
    AcctSeed.PostResult[] postResults = AcctSeed.CashDisbursementPostService.postCashDisbursements(
      new List<AcctSeed__Cash_Disbursement__c>{ cd }
    );
    String errorMsg = '';
    for (AcctSeed.PostResult theResult : postResults) {
      if (!theResult.isSuccess) {
        for (AcctSeed.PostResult.PostErrorResult errorResult : theResult.errors) {
          errorMsg += errorResult.message;
        }
      }
    }
    AcctSeed__Cash_Disbursement__c cdUpd = [
      SELECT Id, GMBLASG__Posted__c, AcctSeed__Disbursement_Date__c
      FROM AcctSeed__Cash_Disbursement__c
      WHERE Id = :cd.Id
    ][0];
    System.assertEquals(cdUpd.GMBLASG__Posted__c, true);
    Test.stopTest();
  }

  static testMethod void trigger_TestUpdate() {
    init(gcConstants.idGlCustomerRefund);
    Test.startTest();
    insert cd;
    AcctSeed.PostResult[] postResults = AcctSeed.CashDisbursementPostService.postCashDisbursements(
      new List<AcctSeed__Cash_Disbursement__c>{ cd }
    );
    String errorMsg = '';
    for (AcctSeed.PostResult theResult : postResults) {
      if (!theResult.isSuccess) {
        for (AcctSeed.PostResult.PostErrorResult errorResult : theResult.errors) {
          errorMsg += errorResult.message;
        }
      }
    }
    cd.AcctSeed__Disbursement_Date__c = Date.today() - 1;
    try {
      update cd;
    } catch (Exception ex) {
      System.assertEquals(ex.getMessage().contains('You cannot update the Posting Status, Payment Status'), true);
    }
    Test.stopTest();
  }

  @IsTest
  static void postedValidation_Test() {
    init(gcConstants.idGlCustomerRefund);
    AcctSeed__Cash_Disbursement__c c_cd = cd.clone(false, true);
    c_cd.AcctSeed__Check_Number__c = 9876;

    gcCashDisbursement.postedValidation(c_cd, cd);

    List<Database.Error> errors = c_cd.getErrors();

    System.assertEquals( 1, errors.size() );
    System.assertEquals(
      gcCashDisbursement.genPostedErrorMsg('AcctSeed__Check_Number__c'),
      errors.get(0).getMessage()
    );
  }
}
