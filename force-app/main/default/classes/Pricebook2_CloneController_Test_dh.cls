@isTest
private class Pricebook2_CloneController_Test_dh {

  static Pricebook2 pb;
  static User testUser;

  static {
    Id rtId = LGND_Utilities.recordTypeIdFromName('Pricebook2', 'Sales');
    pb = new Pricebook2( Name = 'Test Pb',
                          isActive = true,
                          RecordTypeId = rtId );
    insert pb;
  }

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void buildTestUser()
  {
    AcctSeedERP__Warehouse__c wh;
    for( AcctSeedERP__Warehouse__c warehouse : [ SELECT Id, Name, GL_Account_Variable_3__c FROM AcctSeedERP__Warehouse__c ] )
    {
      if( warehouse.Name == 'Whitefish' )
        wh = warehouse;
    }
    testUser =  Factory_User.newUser('whitefish', 'mcTesterson', 'Standard User', wh );
  }

	@isTest static void fetchPricebook_Test()
  {
    Pricebook2 pbReturned = Pricebook2_CloneController_dh.fetchPricebook( pb.Id );
    System.assertEquals( pb.Name, pbReturned.Name );
	}

  @isTest static void fetchPricebook_invalid_Test()
  {
    Account a = Factory_Account.insertDealerAccounts(1)[0];
    String errMsg;
    try {
      Pricebook2_CloneController_dh.fetchPricebook( a.Id );
    }
    catch( Exception e )
    {
      errMsg = e.getMessage();
    }
    System.assertEquals('Pricebook not found! Id supplied was for Account object', errMsg );
  }

  @isTest static void fetchPricebook_noAccess_Test()
  {
    String errMsg;
    buildTestUser();
    System.runAs( testUser )
    {
      try {
        Pricebook2 pbReturned = Pricebook2_CloneController_dh.fetchPricebook( pb.Id );
      }
      catch( Exception e )
      {
        errMsg = e.getMessage();
      }
      System.assertEquals( errMsg, 'You do not have permission to create Pricebooks' );
    }
  }



  @isTest
  static void clonePricebookTest()
  {
    Pricebook2 npb = new Pricebook2( Name = 'ClonePb',
                                     Description = 'Clone of Test Pb',
                                     isActive = true );
    Pricebook2 pb2 = Pricebook2_CloneController_dh.clonePricebook( pb.Id, npb, false, false, false);
    System.assertEquals( pb.RecordTypeId, pb2.RecordTypeId );
    System.assertEquals( npb.Name, pb2.Name );
    System.assertEquals( npb.Description, pb2.Description );
    System.assertEquals( npb.isActive, pb2.isActive );
  }

  @isTest
  static void clonePricebook_withEntries_Test()
  {
    Product2[] parts = Factory_Product.buildNonSerializedProducts( 'Part', 'Electronics', 20 );
    insert parts;
    Factory_PricebookEntry.createStandardEntries( parts, 10.00 );
    Factory_PricebookEntry.createEntries( parts, pb.Id, 10.00 );
    Test.startTest();
    Pricebook2 npb = new Pricebook2( Name = 'ClonePb',
                                     Description = 'Clone of Test Pb',
                                     isActive = true );
    Pricebook2 pb2 = Pricebook2_CloneController_dh.clonePricebook( pb.Id, npb, true, false, false );
    Test.stopTest();
    PricebookEntry[] entries = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pb2.Id ];
    System.assertEquals( parts.size(), entries.size() );
  }

   @isTest
  static void clonePricebook_withFees_Test()
  {
    Product2[] fees = Factory_Product.buildNonSerializedProducts( 'Fees', '', 20 );
    insert fees;
    Product_Fee_Amount__c[] pfas = new List<Product_Fee_Amount__c>();
    for( Product2 p : fees )
    {
      pfas.add( new Product_Fee_Amount__c(
        Amount__c = 10,
        Province__c = 'Ontario',
        Fee_Product__c = p.Id,
        Price_Book__c = pb.Id
      ));
    }
    insert pfas;
    Test.startTest();
    Pricebook2 npb = new Pricebook2( Name = 'ClonePb',
                                     Description = 'Clone of Test Pb',
                                     isActive = true );
    Pricebook2 pb2 = Pricebook2_CloneController_dh.clonePricebook( pb.Id, npb, false, true, false );
    Test.stopTest();
    Product_Fee_Amount__c[] pfas2 = [SELECT Id FROM Product_Fee_Amount__c WHERE Price_Book__c = :pb2.Id];
    System.assertEquals( fees.size(), pfas2.size() );
  }

  @isTest
  static void clonePricebook_withUpgrades_Test()
  {
    //Product2[] prods = new List<Product2>();
    Product2 motor = Factory_Product.createSerializedProduct('Motor', 'Remote');
    Product2[] uMotors = Factory_Product.createSerializedProducts( 'Motor', 'Remote', 10 );
    Product_Upgrade__c[] pus = new List<Product_Upgrade__c>();
    for( Product2 um : uMotors )
    {
      pus.add( new Product_Upgrade__c(
        From_Product__c = motor.Id,
        To_Product__c = um.Id
      ));
    }
    insert pus;
    Product_Upgrade_Cost__c[] pucs = new List<Product_Upgrade_Cost__c>();
    for( Product_Upgrade__c pu : pus )
    {
      pucs.add( new Product_Upgrade_Cost__c(
        Price_Book__c = pb.Id,
        Product_Upgrade__c = pu.Id,
        Cost__c = 10.00
      ));
    }
    insert pucs;
    Test.startTest();
    Pricebook2 npb = new Pricebook2( Name = 'ClonePb',
                                     Description = 'Clone of Test Pb',
                                     isActive = true );
    Pricebook2 pb2 = Pricebook2_CloneController_dh.clonePricebook( pb.Id, npb, false, false, true );
    Test.stopTest();
    Product_Upgrade_Cost__c[] result = [SELECT Id
                                        FROM Product_Upgrade_Cost__c
                                        WHERE Price_Book__c = :pb2.Id];
    System.assertEquals( pucs.size(), result.size() );
  }


}