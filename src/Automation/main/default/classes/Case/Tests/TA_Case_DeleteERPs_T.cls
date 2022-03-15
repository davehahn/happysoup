/**
 * Created by dave on 2022-01-04.
 */

@IsTest
private class TA_Case_DeleteERPs_T {
  private static List<Case> cases;
  private static AcctSeed__Project__c erp;
  private static Account dealer;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    dealer = AccountFactory.buildDealerAccount('Testy McDealer');
    insert dealer;
    cases = new List<Case>();
    buildERP();
  }

  private static void buildERP() {
    Id erpRtId = new Application_RecordType().getERPOrderRecordTypes().getWarrantyId();
    erp = new AcctSeed__Project__c(
      RecordTypeId = erpRtId,
      Name = dealer.Name.trim(),
      AcctSeed__Status__c = 'Active',
      AcctSeed__Account__c = dealer.Id
    );
    TriggerBase.bypass('AcctSeed__Project__c');
    insert erp;
    buildCases();
  }

  private static void buildCases() {
    Case c = Factory_Case.buildWarrantyCase(dealer);
    c.Warranty_ERP__c = erp.Id;
    cases.add(c);

    TriggerBase.bypass('Case');
    insert cases;
    TriggerBase.clearAllBypasses();
  }

  @IsTest
  static void TA_BeforeDelete() {
    init();

    Integer erpCount = [SELECT COUNT() FROM AcctSeed__Project__c];
    System.assertEquals(1, erpCount);

    Test.startTest();
    new TA_Case_DeleteERPs().beforeDelete(cases);
    Test.stopTest();

    erpCount = [SELECT COUNT() FROM AcctSeed__Project__c];
    System.assertEquals(0, erpCount);
  }
}
