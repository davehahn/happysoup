/**
 * Created by dave on 2022-01-07.
 */

@IsTest
private class TA_Case_CreatePartnerPartsOrder_T
{

  private static Case c;
  private static Account dealer;
  private static User partner;
  private static Id testUserId;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    dealer = AccountFactory.buildDealerAccount('Testy McDealer');
    insert dealer;
    c = Factory_Case.buildWarrantyCase(dealer);
    partner = Factory_User.createPartnerUser(dealer);
    User testUser = Factory_User.createUser('TestDave', 'TestHahn', 'System Administrator');
    testUserId = testUser.Id;
  }

  @IsTest
  static void TA_AfterUpdate() {
    init();
    System.runAs(partner) {
      TriggerBase.bypass('Case');
      TriggerBase.bypass('Case_Part__c');
      insert c;
      c.OwnerId = partner.Id;
      update c;
      Case oldC = c.clone(true, true, true, true);
      List<Case> oldList = new List<Case>{oldC};
      List<Case_Part__c> cParts = Factory_CasePart.create(c, 3);
      TriggerBase.clearBypass('Case');
      TriggerBase.clearBypass('Case_Part__c');
      c.Partner_Reference__c = 'Unit Test';
      c.Status = 'Approved';
      List<Case> newList = new List<Case>{c};
      Test.startTest();
      new TA_Case_CreatePartnerPartsOrder().afterUpdate(newList, oldList);
      Test.stopTest();

      c = [SELECT Id, Parts_Order_ERP__c, Partner_Reference__c FROM Case WHERE Id = :c.Id];
      AcctSeed__Project__c erp = [
        SELECT Id, Partner_External_PO_Number__c, (SELECT Id FROM AcctSeedERP__Project_Materials__r)
        FROM AcctSeed__Project__c
        WHERE Id = :c.Parts_Order_ERP__c
      ];

      System.assert(c.Parts_Order_ERP__c != null, 'Case Parts Order lookup should be populated');
      System.assertEquals(c.Parts_Order_ERP__c, erp.Id);
      System.assertEquals(erp.Partner_External_PO_Number__c, c.Partner_Reference__c);
      System.assertEquals(cParts.size(), erp.AcctSeedERP__Project_Materials__r.size());
    }
  }

  @IsTest
  static void Trigger_AfterUpdate() {
    init();
    System.runAs(partner) {
      TriggerBase.bypass('Case');
      TriggerBase.bypass('Case_Part__c');
      insert c;
      c.OwnerId = partner.Id;
      update c;
      List<Case_Part__c> cParts = Factory_CasePart.create(c, 3);
      TriggerBase.clearBypass('Case');
      TriggerBase.clearBypass('Case_Part__c');
      c.Partner_Reference__c = 'Unit Test';
      c.Status = 'Approved';

      Test.startTest();
      update c;
      Test.stopTest();

      c = [SELECT Id, Parts_Order_ERP__c, Partner_Reference__c FROM Case WHERE Id = :c.Id];
      AcctSeed__Project__c erp = [
        SELECT Id, Partner_External_PO_Number__c, (SELECT Id FROM AcctSeedERP__Project_Materials__r)
        FROM AcctSeed__Project__c
        WHERE Id = :c.Parts_Order_ERP__c
      ];

      System.assert(c.Parts_Order_ERP__c != null, 'Case Parts Order lookup should be populated');
      System.assertEquals(c.Parts_Order_ERP__c, erp.Id);
      System.assertEquals(erp.Partner_External_PO_Number__c, c.Partner_Reference__c);
      System.assertEquals(cParts.size(), erp.AcctSeedERP__Project_Materials__r.size());
    }
  }

}