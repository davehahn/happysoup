/**
 * Created by dave on 2022-01-05.
 */

@IsTest
private class TA_Case_CommentOnWarrantyERP_T {
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
    TriggerBase.clearBypass('AcctSeed__Project__c');
  }

  @IsTest
  static void TA_afterInsert() {
    init();
    Case c = Factory_Case.buildWarrantyCase(dealer);
    c.Warranty_ERP__c = erp.Id;
    c.Partner_Reference__c = 'Test Ref';
    List<Case> newList = new List<Case>{ c };

    Test.startTest();
    new TA_Case_CommentOnWarrantyERP().afterInsert(newList);
    Test.stopTest();

    AcctSeed__Project__c erp = [SELECT Id, Customer_Notes__c FROM AcctSeed__Project__c WHERE Id = :c.Warranty_ERP__c];
    String comment = 'Warranty Case # ' + null;
    comment += '<br> Partner Reference # ' + c.Partner_Reference__c;

    System.assertEquals(comment, erp.Customer_Notes__c);
  }
}
