@isTest
private class CasePart_Test {

  public static User partner;
  public static Account dealer;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static void init()
  {
    dealer = AccountFactory.buildDealerAccount('Testy McDealer');
    insert dealer;
    partner = User_TestFactory.createPartnerUser( dealer );
  }

  static Case_Part__c[] buildCaseParts( Case c, Integer count )
  {
    InventoryTestFactory factory = new InventoryTestFactory();
    Product2[] parts = factory.buildTestProducts( count, 'Part', 'Electronics' );
    insert parts;
    Case_Part__c[] cParts = new List<Case_Part__c>();
    for( Product2 p : parts )
    {
      cParts.add( new Case_Part__c (
        Case__c = c.Id,
        Product__c = p.Id,
        Quantity__c = 1,
        Unit_Price__c = 10.00
      ));
    }
    insert cParts;
    return cParts;
  }

  /* should have a material associated with it after create */
  //@isTest( seeAllData=true )
  @isTest
  static void createTest()
  {
    init();
    System.runAs( partner )
    {
      Test.startTest();
      Case c = Factory_Case.createWarrantyCase( dealer );
      Account supplier = AccountFactory.buildSupplierAccount('Test supplier');
      insert supplier;
      CaseLexController.createWarrantyRecoverableERP( supplier.Id, c.Id );
      Case_Part__c[] cParts = buildCaseParts( c, 2 );
      c = [SELECT Id, Warranty_ERP__c, Recoverable_Erp__c FROM Case WHERE Id = :c.Id];
      AcctSeedERP__Material__c[] mats = [SELECT Id
                                         FROM AcctSeedERP__Material__c
                                         WHERE AcctSeedERP__Project__c = :c.Warranty_ERP__c ];
      AcctSeedERP__Material__c[] mats_r = [SELECT Id
                                         FROM AcctSeedERP__Material__c
                                         WHERE AcctSeedERP__Project__c = :c.Recoverable_ERP__c ];
      Test.stopTest();
      System.assertEquals( 2, mats.size() );
      System.assertEquals( 2, mats_r.size() );
    }
  }

  //@isTest( seeAllData=true )
  @isTest
  static void deleteTest()
  {
    init();
    System.runAs( partner )
    {
      Test.startTest();
      Case c = Factory_Case.createWarrantyCase( dealer );
      Account supplier = AccountFactory.buildSupplierAccount('Test supplier');
      insert supplier;
      CaseLexController.createWarrantyRecoverableERP( supplier.Id, c.Id );
      Case_Part__c[] cParts = buildCaseParts( c, 2 );
      c = [SELECT Id, Warranty_ERP__c, Recoverable_ERP__c FROM Case WHERE Id = :c.Id];
      AcctSeedERP__Material__c[] mats_before = [SELECT Id
                                                FROM AcctSeedERP__Material__c
                                                WHERE AcctSeedERP__Project__c = :c.Warranty_ERP__c ];
      AcctSeedERP__Material__c[] mats_r_before = [SELECT Id
                                                FROM AcctSeedERP__Material__c
                                                WHERE AcctSeedERP__Project__c = :c.Recoverable_ERP__c ];
      delete cParts[0];
      AcctSeedERP__Material__c[] mats_after = [SELECT Id
                                               FROM AcctSeedERP__Material__c
                                               WHERE AcctSeedERP__Project__c = :c.Warranty_ERP__c ];
      AcctSeedERP__Material__c[] mats_r_after = [SELECT Id
                                                FROM AcctSeedERP__Material__c
                                                WHERE AcctSeedERP__Project__c = :c.Recoverable_ERP__c ];
      Test.stopTest();
      System.assertEquals(2, mats_before.size());
      System.assertEquals(2, mats_r_before.size());
      System.assertEquals(1, mats_after.size());
      System.assertEquals(1, mats_r_after.size());
    }
  }



}