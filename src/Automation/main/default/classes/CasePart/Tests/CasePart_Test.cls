@isTest
private class CasePart_Test {
  public static User partner;
  public static Account dealer;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static void init() {
    dealer = AccountFactory.buildDealerAccount('Testy McDealer');
    insert dealer;
    partner = User_TestFactory.createPartnerUser(dealer);
  }

  static Case_Part__c[] buildCaseParts(Case c, Integer count) {
    InventoryTestFactory factory = new InventoryTestFactory();
    Product2[] parts = factory.buildTestProducts(count, 'Part', 'Hardware');
    insert parts;
    Case_Part__c[] cParts = new List<Case_Part__c>();
    for (Product2 p : parts) {
      cParts.add(new Case_Part__c(Case__c = c.Id, Product__c = p.Id, Quantity__c = 1, Unit_Price__c = 10.00));
    }
    insert cParts;
    return cParts;
  }

  /* should have a material associated with it after create */
  @isTest
  static void TA_CasePart_CreateMaterial_Test() {
    init();
    System.runAs(partner) {
      Case c = Factory_Case.createWarrantyCase(dealer);
      Account supplier = AccountFactory.buildSupplierAccount('Test supplier');
      insert supplier;
      CaseLexController.createWarrantyRecoverableERP(supplier.Id, c.Id);
      Test.startTest();
      buildCaseParts(c, 2);
      Test.stopTest();
      c = [SELECT Id, Warranty_ERP__c, Recoverable_Erp__c FROM Case WHERE Id = :c.Id];
      AcctSeedERP__Material__c[] mats = [
        SELECT Id
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Project__c = :c.Warranty_ERP__c
      ];
      AcctSeedERP__Material__c[] mats_r = [
        SELECT Id
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Project__c = :c.Recoverable_ERP__c
      ];
      System.assertEquals(2, mats.size());
      System.assertEquals(2, mats_r.size());
    }
  }

  @isTest
  static void TA_CasePart_DeleteMaterial_Test() {
    init();
    System.runAs(partner) {
      TriggerBase.bypass('Case_Part__c');
      Case c = Factory_Case.createWarrantyCase(dealer);
      Account supplier = AccountFactory.buildSupplierAccount('Test supplier');
      insert supplier;
      CaseLexController.createWarrantyRecoverableERP(supplier.Id, c.Id);
      Case_Part__c[] cParts = buildCaseParts(c, 2);
      c = [SELECT Id, Warranty_ERP__c, Recoverable_ERP__c FROM Case WHERE Id = :c.Id];
      AcctSeed__Project__c wERP = [
        SELECT Id, (SELECT Id FROM AcctSeed__Project_Tasks__r)
        FROM AcctSeed__Project__c
        WHERE Id = :c.Warranty_ERP__c
      ];
      AcctSeed__Project__c rERP = [
        SELECT Id, (SELECT Id FROM AcctSeed__Project_Tasks__r)
        FROM AcctSeed__Project__c
        WHERE Id = :c.Recoverable_ERP__c
      ];

      AcctSeedERP__Material__c[] mats = new List<AcctSeedERP__Material__c>();

      for (Case_Part__c cp : cParts) {
        mats.add(
          new AcctSeedERP__Material__c(
            AcctSeedERP__Product__c = cp.Product__c,
            AcctSeedERP__Quantity_Per_Unit__c = cp.Quantity__c,
            AcctSeedERP__Project__c = wERP.Id,
            AcctSeedERP__Project_Task__c = wERP.AcctSeed__Project_Tasks__r[0].Id,
            GMBLASERP__Unit_Price__c = cp.Unit_Price__c,
            Case_Part__c = cp.Id
          )
        );
        mats.add(
          new AcctSeedERP__Material__c(
            AcctSeedERP__Product__c = cp.Product__c,
            AcctSeedERP__Quantity_Per_Unit__c = cp.Quantity__c,
            AcctSeedERP__Project__c = rERP.Id,
            AcctSeedERP__Project_Task__c = rERP.AcctSeed__Project_Tasks__r[0].Id,
            GMBLASERP__Unit_Price__c = cp.Unit_Price__c,
            Case_Part__c = cp.Id
          )
        );
      }

      insert mats;
      TriggerBase.clearBypass('Case_Part__c');

      Test.startTest();
      delete cParts[0];
      Test.stopTest();

      AcctSeedERP__Material__c[] mats_after = [
        SELECT Id
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Project__c = :c.Warranty_ERP__c
      ];
      AcctSeedERP__Material__c[] mats_r_after = [
        SELECT Id
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Project__c = :c.Recoverable_ERP__c
      ];
      System.assertEquals(4, mats.size());
      System.assertEquals(1, mats_after.size());
      System.assertEquals(1, mats_r_after.size());
    }
  }
}
