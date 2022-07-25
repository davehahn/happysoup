@isTest(seeAllData=false)
public with sharing class gcAccountPayable_T {
  @TestSetup
  static void testData() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Factory_AccountPayable.insertAccountPayable(5);
  }

  @isTest
  static void testBulkData() {
    List<AcctSeed__Account_Payable__c> lstAccountPayable = [
      SELECT
        Id,
        Name,
        GL_Account_Variable_3__c,
        Tax_Override__c,
        Tax_Rate_Retail__c,
        Payee_New__c,
        Tax_Amount_Fixed__c,
        AcctSeed__Fixed_Asset__c,
        AcctSeed__Proprietary_Payable_Number__c,
        GL_Account_Variable_1__c,
        GL_Account_Variable_2__c,
        Approval_Date__c,
        Approved__c,
        Submitted_Date__c,
        AcctSeed__VAT_Line_Count__c,
        AcctSeed__Vendor__c
      FROM AcctSeed__Account_Payable__c
    ];

    List<AcctSeed__Accounting_Variable__c> lstAccVariable = [
      SELECT Id, AcctSeed__Type__c
      FROM AcctSeed__Accounting_Variable__c
      WHERE AcctSeed__Type__c = 'GL Account Variable 3'
    ];
    for (AcctSeed__Account_Payable__c accPayable : lstAccountPayable) {
      accPayable.Tax_Amount_Fixed__c = false;
      accPayable.Tax_Override__c = false;
      accPayable.Tax_Amount_Retail__c = 1235;
      accPayable.GL_Account_Variable_3__c = lstAccVariable[0].Id;
    }
    Test.startTest();
    update lstAccountPayable;
    Test.stopTest();

    lstAccountPayable = [
      SELECT Id, Tax_Amount_Fixed__c, Tax_Override__c, GL_Account_Variable_3__c
      FROM AcctSeed__Account_Payable__c
    ];
    system.assertEquals(false, lstAccountPayable[0].Tax_Amount_Fixed__c);
    system.assertEquals(false, lstAccountPayable[0].Tax_Override__c);
    system.assertEquals(lstAccVariable[0].Id, lstAccountPayable[0].GL_Account_Variable_3__c);
  }

  @isTest
  static void testTaxAmountFixed() {
    List<AcctSeed__Account_Payable__c> lstAccountPayable = [
      SELECT
        Id,
        Name,
        GL_Account_Variable_3__c,
        Tax_Override__c,
        Tax_Rate_Retail__c,
        Payee_New__c,
        Tax_Amount_Fixed__c,
        AcctSeed__Fixed_Asset__c,
        AcctSeed__Proprietary_Payable_Number__c,
        GL_Account_Variable_1__c,
        GL_Account_Variable_2__c,
        Approval_Date__c,
        Approved__c,
        Submitted_Date__c,
        AcctSeed__VAT_Line_Count__c,
        AcctSeed__Vendor__c
      FROM AcctSeed__Account_Payable__c
      LIMIT 1
    ];

    List<AcctSeed__Accounting_Variable__c> lstAccVariable = [
      SELECT Id, AcctSeed__Type__c
      FROM AcctSeed__Accounting_Variable__c
      WHERE AcctSeed__Type__c = 'GL Account Variable 3'
    ];

    AcctSeed__Accounting_Period__c accPeriod = [
      SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, Name
      FROM AcctSeed__Accounting_Period__c
      LIMIT 1
    ];

    lstAccountPayable[0].Tax_Amount_Fixed__c = true;
    lstAccountPayable[0].Tax_Override__c = false;
    lstAccountPayable[0].Tax_Amount_Retail__c = 1235;
    lstAccountPayable[0].GL_Account_Variable_3__c = lstAccVariable[0].Id;
    lstAccountPayable[0].AcctSeed__Date__c = System.today() + 5;
    lstAccountPayable[0].AcctSeed__Accounting_Period__c = accPeriod.id;

    Test.startTest();
    update lstAccountPayable[0];
    Test.stopTest();

    lstAccountPayable = [
      SELECT Id, Tax_Amount_Fixed__c, Tax_Override__c, GL_Account_Variable_3__c, Tax_Amount_Retail__c, AcctSeed__Date__c
      FROM AcctSeed__Account_Payable__c
    ];
    system.assertEquals(true, lstAccountPayable[0].Tax_Amount_Fixed__c);
    system.assertEquals(true, lstAccountPayable[0].Tax_Override__c);
    system.assertEquals(lstAccVariable[0].Id, lstAccountPayable[0].GL_Account_Variable_3__c);
    system.assertEquals(System.today() + 5, lstAccountPayable[0].AcctSeed__Date__c);
  }

  @isTest
  static void testTaxOverride_AccSeedDateChanged() {
    List<AcctSeed__Account_Payable__c> lstAccountPayable = [
      SELECT
        Id,
        Name,
        GL_Account_Variable_3__c,
        Tax_Override__c,
        Tax_Rate_Retail__c,
        Payee_New__c,
        Tax_Amount_Fixed__c,
        AcctSeed__Fixed_Asset__c,
        AcctSeed__Proprietary_Payable_Number__c,
        GL_Account_Variable_1__c,
        GL_Account_Variable_2__c,
        Approval_Date__c,
        Approved__c,
        Submitted_Date__c,
        AcctSeed__VAT_Line_Count__c,
        AcctSeed__Vendor__c
      FROM AcctSeed__Account_Payable__c
      LIMIT 1
    ];

    List<AcctSeed__Accounting_Variable__c> lstAccVariable = [
      SELECT Id, AcctSeed__Type__c
      FROM AcctSeed__Accounting_Variable__c
      WHERE AcctSeed__Type__c = 'GL Account Variable 3'
    ];

    Test.startTest();
    lstAccountPayable[0].Tax_Amount_Fixed__c = true;
    lstAccountPayable[0].Tax_Override__c = false;
    lstAccountPayable[0].GL_Account_Variable_3__c = lstAccVariable[0].Id;
    lstAccountPayable[0].AcctSeed__Date__c = System.today() + 5;
    lstAccountPayable[0].Tax_Amount_Retail__c = 1234;
    AcctSeed.AccountPayablePostService.postAccountPayables(lstAccountPayable);
    Test.stopTest();

    lstAccountPayable = [
      SELECT
        Id,
        Tax_Amount_Fixed__c,
        Tax_Override__c,
        GL_Account_Variable_3__c,
        Tax_Amount_Retail__c,
        AcctSeed__Date__c,
        AcctSeed__Status__c
      FROM AcctSeed__Account_Payable__c
    ];

    system.assertEquals('Posted', lstAccountPayable[0].AcctSeed__Status__c);

    gcAccountPayable.disableTrigger = null;
    gcAccountPayable.disableTrigger = true;
    gcAccountPayable.disableTrigger = false;
  }
}
