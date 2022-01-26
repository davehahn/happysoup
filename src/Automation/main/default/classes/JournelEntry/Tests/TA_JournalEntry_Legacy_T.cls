/**
 * Created by dave on 2022-01-26.
 */

@IsTest
private class TA_JournalEntry_Legacy_T
{
  @TestSetup
  static void dataSetup(){
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static List<AcctSeed__Journal_Entry__c> newList;
  private static List<AcctSeed__Journal_Entry__c> oldList;

  private static void buildTriggerVariables( Boolean isUpdate ){
    newList = new List<AcctSeed__Journal_Entry__c>();
    oldList = new List<AcctSeed__Journal_Entry__c>();
//
//    AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(
//      Name = 'Test Loc',
//      AcctSeedERP__Warehouse__c = Test_Constants.idWarehouse
//    );
//    insert loc;
    AcctSeed__Journal_Entry__c je = new AcctSeed__Journal_Entry__c(
      Name = 'Test Journal',
      AcctSeed__Accounting_Period__c = Test_Constants.idPeriod,
      AcctSeed__Ledger__c =Test_Constants.idLedger
    );
    if( isUpdate ){
      je.Id = TestUtility.getFakeId(AcctSeed__Journal_Entry__c.SObjectType);
    }
    AcctSeed__Journal_Entry__c orig_je = je.clone(true, true, true,true);
    je.Name = 'Test Journal Two';
    oldList.add( orig_je );
    newLIst.add( je );
  }

  @IsTest
  static void beforeInsertTest() {
    buildTriggerVariables(false);
    Test.startTest();
    new TA_JournalEntry_Legacy().beforeInsert(newList);
    Test.stopTest();
  }

  @IsTest
  static void afterInsertTest() {
    buildTriggerVariables(true);
    Test.startTest();
    new TA_JournalEntry_Legacy().afterInsert(newList);
    Test.stopTest();
  }

  @IsTest
  static void beforeUpdateTest() {
    buildTriggerVariables(true);
    Test.startTest();
    new TA_JournalEntry_Legacy().beforeUpdate(newList, oldList);
    Test.stopTest();
  }

  @IsTest
  static void afterUpdateTest() {
    buildTriggerVariables(true);
    Test.startTest();
    new TA_JournalEntry_Legacy().afterUpdate(newList, oldList);
    Test.stopTest();
  }

  @IsTest
  static void beforeDeleteTest() {
    buildTriggerVariables(true);
    Test.startTest();
    new TA_JournalEntry_Legacy().beforeDelete(oldList);
    Test.stopTest();
  }

  @IsTest
  static void afterDeleteTest() {
    buildTriggerVariables(true);
    Test.startTest();
    new TA_JournalEntry_Legacy().afterDelete(oldList);
    Test.stopTest();
  }
}