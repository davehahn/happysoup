@isTest
public class TA_JournalEntryLine_Legacy_T {
    static List<AcctSeed__Journal_Entry_Line__c> journalEntryLine;
    private static List<AcctSeed__Journal_Entry_Line__c> getData(){
        return [select
                id,
                AcctSeed__Journal_Entry__c,
                AcctSeed__GL_Account__c,
                AcctSeed__Credit__c,
                AcctSeed__Project__c,
                Journal_Entry_Name__c,
                AcctSeed__Project_Task__c,
                AcctSeed__GL_Account_Variable_1__c,
                AcctSeed__GL_Account_Variable_2__c
        From
                AcctSeed__Journal_Entry_Line__c
        ];
    }
    @testSetup
    static void dataSetup()
    {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        AcctSeed__Accounting_Period__c period = [SELECT Id FROM AcctSeed__Accounting_Period__c LIMIT 1];
        AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
        AcctSeed__GL_Account__c glAccount = [SELECT Id FROM AcctSeed__GL_Account__c LIMIT 1];
        AcctSeed__Journal_Entry__c je = new AcctSeed__Journal_Entry__c (
                AcctSeed__Accounting_Period__c = period.Id,
                AcctSeed__Ledger__c = ledger.Id
        );
        insert je;
        AcctSeed__Journal_Entry_Line__c jel = new AcctSeed__Journal_Entry_Line__c (
                AcctSeed__Journal_Entry__c = je.Id,
                AcctSeed__GL_Account__c = glAccount.Id,
                AcctSeed__Credit__c = 100
        );
        insert jel;

    }

    @IsTest
    static void beforeInsertTest() {
        Test.startTest();
        journalEntryLine = getData();
        new TA_JournalEntryLine_Legacy().beforeInsert(journalEntryLine);
        Test.stopTest();
    }
    @IsTest
    static void afterInsertTest() {
        Test.startTest();
        new TA_JournalEntryLine_Legacy().afterInsert(getData());
        Test.stopTest();
    }
    @IsTest
    static void afterUpdateTest() {
        Test.startTest();
        journalEntryLine = getData();
        AcctSeed__Journal_Entry_Line__c geClone =journalEntryLine[0].clone(true, true, true, true);
        new TA_JournalEntryLine_Legacy().afterUpdate(new List<AcctSeed__Journal_Entry_Line__c>{journalEntryLine[0]},new List<AcctSeed__Journal_Entry_Line__c>{geClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeUpdateTest() {
        Test.startTest();
        journalEntryLine = getData();
        AcctSeed__Journal_Entry_Line__c geClone =journalEntryLine[0].clone(true, true, true, true);
        new TA_JournalEntryLine_Legacy().beforeUpdate(new List<AcctSeed__Journal_Entry_Line__c>{journalEntryLine[0]},new List<AcctSeed__Journal_Entry_Line__c>{geClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeDeleteTest() {
        Test.startTest();
        new TA_JournalEntryLine_Legacy().beforeDelete(getData());
        Test.stopTest();
    }
    @IsTest
    static void afterDeleteTest() {
        Test.startTest();
        new TA_JournalEntryLine_Legacy().afterDelete(getData());
        Test.stopTest();
    }

}