@isTest
private class CaseLexController_Test {

  static Account dealer;
  static User partner;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static void initForWarranty()
  {
    dealer = AccountFactory.buildDealerAccount('Testy McDealer');
    insert dealer;
    partner = User_TestFactory.createPartnerUser( dealer );
  }

  @isTest
  static void coverge_Test()
  {
    CaseLexController.coverage();
  }

	@isTest static void initData_Test() {
		User testUser = User_TestFactory.newUser('testFirst', 'testLast', 'Legend Standard User - New');
    insert testUser;
    System.runAs( testUser )
    {
      testUser = [SELECT Id, Name FROM User WHERE Id = :testUser.Id];
      String dataJSON = CaseLexController.initData();
      CaseLexController.DataWrapper data = (CaseLexController.DataWrapper)JSON.deserialize( dataJSON, CaseLexController.DataWrapper.class);
      System.assertEquals(testUser.Name, data.userName);
    }
	}

  //@isTest(seeAllData=true)
  @isTest
  static void saveTheCase_Test()
  {
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat',
                                                                               'Pontoon',
                                                                               '1234TEST6789');
    dealer = AccountFactory.buildDealerAccount('Testy McDealer');
    insert dealer;
    CaseLexController.SubmitDataWrapper wrapper = new CaseLexController.SubmitDataWrapper();
    wrapper.recordTypeName = 'Warranty';
    wrapper.accountId = dealer.Id;
    wrapper.serialId = serial.Id;
    wrapper.claimType = 'Other';
    wrapper.failureDate = Date.today();
    wrapper.subject = 'test subject';
    wrapper.description = 'test description';
    String result = CaseLexController.saveTheCase( JSON.serialize( wrapper ) );
    Case c = (Case)JSON.deserialize( result, Case.class );

    System.assertEquals( wrapper.subject, c.Subject );
    System.assertEquals( wrapper.claimType, c.Claim_Type__c );
    System.assertEquals( wrapper.accountId, c.AccountId );
    System.assertEquals( wrapper.serialId, c.Serial_number__c );
  }

  //@isTest(seeAllData=true)
  @isTest
  static void fetchWarrantyHistory_Test()
  {
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat',
                                                                               'Pontoon',
                                                                               '9876TEST6789');
    Account acct = AccountFactory.insertSupplierAccountWithContacts('TestSupplier', 4);
    AcctSeed__Project__c erp = Factory_ERPOrder.createWarrantyERP(acct, serial.Id, 3);
    Id erpId = erp.Id;
    Test.startTest();
    initForWarranty();
    List<Case> cases = new List<Case>();
    System.runAs( partner )
    {
      Case c = Factory_Case.createWarrantyCase( dealer );
      for( Integer i=0; i<5; i++ )
      {
        cases.add( Factory_Case.buildWarrantyCase( dealer, c.Serial_Number__c ) );
      }
      insert cases;
      Case[] result = CaseLexController.fetchWarrantyHistory( c.Id );
      Test.stopTest();

      System.assertEquals( 5, result.size() );
    }
  }

  //@isTest(seeAllData=true)
  @isTest
  static void fetchCase_Test()
  {
    initForWarranty();
    System.runAs( partner )
    {
      Case c = Factory_Case.createWarrantyCase( dealer );
      Case c2 = CaseLexController.fetchCase( c.Id );
      System.assertEquals( c.Id, c2.Id );
    }
  }

  //@isTest(seeAllData=true)
  @isTest
  static void fetchSerial_Test()
  {
    initForWarranty();
    System.runAs( partner )
    {
      Case c = Factory_Case.createWarrantyCase( dealer );
      GMBLASERP__Serial_Number__c serial = CaseLexController.fetchSerial( null );
      System.assertEquals(null, serial);
      serial = CaseLexController.fetchSerial( c.Id );
      System.assertEquals(null, serial);
      serial = CaseLexController.fetchSerial( c.Serial_Number__c );
      System.assertEquals( c.Serial_Number__c, serial.Id );
    }
  }

  @isTest
  static void fetchAllSuppliers_Test()
  {
    Account[] accts =new List<Account>();
    for( Integer i=0; i<5; i++)
    {
      accts.add( AccountFactory.buildSupplierAccount('Test Supplier-' + String.valueOf(i)));
    }
    insert accts;
    Account[] fetched = CaseLexController.fetchAllSuppliers();
    // this will 6 because we create 5 accounts above and the the Mercury
    // Account that get created for Custom Settings in Factory_CustomSettings
    System.assertEquals(6, fetched.size());
  }

  //@isTest(seeAllData=true)
  @isTest
  static void createWarrantyRecoverableERP_Test()
  {
    initForWarranty();
    System.runAs( partner )
    {
      Case c = Factory_Case.createWarrantyCaseWithErp( dealer );
      c.Sublet_Company__c = 'AngrySlothBrewing';
      c.Sublet_Price__c = 400;
      c.Shipping_Company__c = 'AngrySlothShipping';
      c.Shipping_Cost__c = 250;
      c.Partner_Reference__c = 'PartnerRef123';
      update c;
      Account supplier = AccountFactory.insertSupplierAccount( 'Angry Supplier' );
      String resultJSON = CaseLexController.createWarrantyRecoverableERP( supplier.Id, c.Id );
      CaseLexController.RecoverableWrapper result =
        (CaseLexController.RecoverableWrapper)JSON.deserialize( resultJSON, CaseLexController.RecoverableWrapper.class );
      c = [SELECT Id, Recoverable_ERP__c, Warranty_ERP__c, Warranty_ERP__r.Customer_Notes__c, Partner_Reference__c FROM Case WHERE Id = :c.Id];
      AcctSeed__Project__c erp = [SELECT Id, Warranty_Case__c, Customer_Notes__c
                                  FROM AcctSeed__Project__c
                                  WHERE Id = :result.erpId ];
      System.assertEquals( result.erpId, c.Recoverable_ERP__c );
      //Should have one material from the shipping info
      System.assertEquals( 1, result.materials.size() );
      System.assertEquals( c.Id, erp.Warranty_Case__c );
      System.assert( erp.Customer_Notes__c.contains( 'PartnerRef123' ) );
      System.assert( erp.Customer_Notes__c.contains( c.Warranty_ERP__r.Customer_Notes__c ) );
    }
  }

  @isTest
  static void deleteERP_Test()
  {
    initForWarranty();
    System.runAs( partner )
    {
      Case c = Factory_Case.createWarrantyCaseWithErp(dealer);
      c = [ SELECT Id, Warranty_ERP__c FROM Case WHERE Id = :c.Id ];
      System.assert( c.Warranty_ERP__c != null );
      CaseLexController.deleteERP( c.Warranty_ERP__c );
      c = [ SELECT Id, Warranty_ERP__c FROM Case WHERE Id = :c.Id ];
      System.assert( c.Warranty_ERP__c == null );
    }
  }

  @isTest
  static void createWarrantyRecoverableMaterials_Test()
  {
    initForWarranty();
    System.runAs( partner )
    {
      Case c = Factory_Case.createWarrantyCaseWithErp(dealer);
      c = [ SELECT Id, Warranty_ERP__c FROM Case WHERE Id = :c.Id ];
      AcctSeed__Project_Task__c task = new AcctSeed__Project_Task__c(
        AcctSeed__Project__c = c.Warranty_ERP__c,
        Name = 'Test Task'
      );
      insert task;
      List<Product2> parts = Factory_Product.buildNonSerializedProducts( 'Part', 'Electronics', 3 );
      insert parts;
      List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
      for( Product2 p : parts )
      {
        materials.add( new AcctSeedERP__Material__c(
          AcctSeedERP__Product__c = p.Id,
          AcctSeedERP__Project_Task__c = task.Id,
          AcctSeedERP__Project__c = c.Warranty_ERP__c,
          AcctSeedERP__Quantity_Per_Unit__c = 1,
          GMBLASERP__Unit_Price__c = 10,
          GMBLASERP__Price_Override__c = true
        ));
      }
      Test.startTest();
      String erpId = CaseLexController.createWarrantyRecoverableMaterials( JSON.serialize( materials ) );
      Test.stopTest();
      List<AcctSeedERP__Material__c> newMats = [SELECT Id FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :c.Warranty_ERP__c ];
      System.assertEquals( 3, newMats.size() );
      System.assertEquals( c.Warranty_ERP__c, erpId );
    }
  }

  @isTest
  static void fetchCaseParts_Test()
  {
    initForWarranty();
    System.runAs( partner )
    {
      Case c = Factory_Case.createWarrantyCaseWithErp( dealer );
      c.Sublet_Company__c = 'AngrySlothBrewing';
      c.Sublet_Price__c = 400;
      c.Shipping_Company__c = 'AngrySlothShipping';
      c.Shipping_Cost__c = 250;
      update c;
      c = [SELECT Id, Recoverable_ERP__c, Warranty_ERP__c FROM Case WHERE Id = :c.Id];
      Case_Part__c[] caseParts = CaseLexController.fetchCaseParts(c.Id);
      String permissions = CaseLexController.fetchCasePartsPermissions(c.Id);
    }
  }

}