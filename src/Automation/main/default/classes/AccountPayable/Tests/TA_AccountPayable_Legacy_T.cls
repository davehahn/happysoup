@isTest
public class TA_AccountPayable_Legacy_T {
  static List<AcctSeed__Account_Payable__c> lstAccountPayable;
  @TestSetup
  static void testData() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Factory_AccountPayable.insertAccountPayable(5);
    new Factory_AccountingVariables();
  }

  @IsTest
  static void beforeInsertTest() {
    Test.startTest();
    lstAccountPayable = getData();
    new TA_AccountPayable_Legacy().beforeInsert(lstAccountPayable);
    Test.stopTest();
  }
  @IsTest
  static void afterInsertTest() {
    Test.startTest();
    new TA_AccountPayable_Legacy().afterInsert(getData());
    Test.stopTest();
  }
  @IsTest
  static void afterUpdateTest() {
    Test.startTest();
    lstAccountPayable = getData();
    AcctSeed__Account_Payable__c accPayableClone = lstAccountPayable[0].clone(true, true, true, true);
    new TA_AccountPayable_Legacy()
      .afterUpdate(
        new List<AcctSeed__Account_Payable__c>{ lstAccountPayable[0] },
        new List<AcctSeed__Account_Payable__c>{ accPayableClone }
      );
    Test.stopTest();
  }
  @IsTest
  static void beforeUpdateTest() {
    Test.startTest();
    lstAccountPayable = getData();
    AcctSeed__Account_Payable__c accPayableClone = lstAccountPayable[0].clone(true, true, true, true);
    new TA_AccountPayable_Legacy()
      .beforeUpdate(
        new List<AcctSeed__Account_Payable__c>{ lstAccountPayable[0] },
        new List<AcctSeed__Account_Payable__c>{ accPayableClone }
      );
    Test.stopTest();
  }
  @IsTest
  static void beforeDeleteTest() {
    Test.startTest();
    new TA_AccountPayable_Legacy().beforeDelete(getData());
    Test.stopTest();
  }
  @IsTest
  static void afterDeleteTest() {
    Test.startTest();
    new TA_AccountPayable_Legacy().afterDelete(getData());
    Test.stopTest();
  }
  static private List<AcctSeed__Account_Payable__c> getData() {
    return [
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
        AcctSeed__Vendor__c,
        Tax_is_Harmonized__c,
        AcctSeed__Status__c,
        Tax_Rate_Federal__c,
        Tax_Rate_Provincial__c,
        Tax_Amount_Federal__c,
        Tax_Amount_Provincial__c,
        Tax_Amount_Retail__c,
        AcctSeed__Date__c
      FROM AcctSeed__Account_Payable__c
    ];
  }
}
