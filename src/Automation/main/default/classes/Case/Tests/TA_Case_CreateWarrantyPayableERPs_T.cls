/**
 * Created by dave on 2022-01-04.
 */

@IsTest
private class TA_Case_CreateWarrantyPayableERPs_T {
  public static Case c;
  public static User partner;
  public static Account dealer;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    dealer = AccountFactory.buildDealerAccount('Testy McDealer');
    insert dealer;
    c = Factory_Case.buildWarrantyCase(dealer);
    c.Partner_Reference__c = 'Test Ref';
    partner = Factory_User.createPartnerUser(dealer);
  }

  @IsTest
  static void TA_BeforeInsert() {
    init();
    System.runAs(partner) {
      List<Case> newList = new List<Case>{ c };
      Test.startTest();
      new TA_Case_CreateWarrantyPayableERPs().beforeInsert(newList);
      Test.stopTest();

      System.assertNotEquals(null, newList[0].Warranty_ERP__c);
    }
  }

  @IsTest
  static void Trigger_BeforeInsert() {
    init();
    System.runAs(partner) {
      Test.startTest();
      insert c;
      Test.stopTest();

      c = [SELECT Id, Warranty_ERP__c FROM Case WHERE Id = :c.Id];

      System.assertNotEquals(null, c.Warranty_ERP__c);
    }
  }
}
