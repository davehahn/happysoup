/**
 * Created by dave on 2022-01-04.
 */

@IsTest
private class TA_Case_PartnerWarrantyDefaults_T {
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
    c.Sublet_Company__c = 'AngrySlothBrewing';
    c.Sublet_Price__c = 400;
    partner = Factory_User.createPartnerUser(dealer);
  }

  @IsTest
  static void TA_beforeInsert() {
    init();
    System.runAs(partner) {
      List<Case> newList = new List<Case>{ c };

      Test.startTest();
      new TA_Case_PartnerWarrantyDefaults().beforeInsert(newList);
      Test.stopTest();

      System.assertNotEquals(null, newList[0].Price_Book__c);
      System.assertEquals(Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c, newList[0].Price_Book__c);
      System.assertEquals(partner.ContactId, newList[0].ContactId);
    }
  }

  @IsTest
  static void Trigger_beforeInsert() {
    init();
    System.runAs(partner) {
      Test.startTest();
      insert c;
      Test.stopTest();

      c = [SELECT Id, Price_Book__c, ContactId FROM Case WHERE Id = :c.Id];

      System.assertNotEquals(null, c.Price_Book__c);
      System.assertEquals(Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c, c.Price_Book__c);
      System.assertEquals(partner.ContactId, c.ContactId);
    }
  }

  @IsTest
  static void automatedUser_beforeInsert() {
    init();
    User auto = [SELECT Id, Name, Alias FROM User WHERE Name = 'Automated Process'];
    System.runAs(auto){
      List<Case> newList = new List<Case>{ c };

      Test.startTest();
      new TA_Case_PartnerWarrantyDefaults().beforeInsert(newList);
      Test.stopTest();

      System.assertNotEquals(null, newList[0].Price_Book__c);
      System.assertEquals(Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c, newList[0].Price_Book__c);
      System.assertEquals(null, newList[0].ContactId);
    }
  }
}
