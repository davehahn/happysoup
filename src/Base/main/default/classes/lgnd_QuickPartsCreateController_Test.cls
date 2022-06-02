@isTest
private class lgnd_QuickPartsCreateController_Test {

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

	@isTest
  static void fetchInitOptions_withoutExternalProduct_Test()
  {
		Account[] suppliers = Factory_Account.insertSupplierAccounts(10);
    String jsonResult = lgnd_QuickPartsCreateController.fetchInitOptions( null );
    lgnd_QuickPartsCreateController.OptionsWrapper result =
      (lgnd_QuickPartsCreateController.OptionsWrapper)JSON.deserialize( jsonResult,
                                                                        lgnd_QuickPartsCreateController.OptionsWrapper.class);
    /* we have to add 1 to account for the Mercury
       Account which gets created in Factory_CustomSettings
    */
    System.assertEquals( ( suppliers.size() + 1 ), result.suppliers.size() );
	}

  @isTest
  static void fetchInitOptions_withMercuryProduct_Test()
  {
    Account[] suppliers = Factory_Account.insertSupplierAccounts(10);
    insert new Utility_Account__c( Mercury__c = suppliers[0].Id );
    Mercury_Product__c mp = new Mercury_Product__c(
      Description__c = 'Test Merc Part',
      Code__c = '1000001-test',
      UPC__c = '1234567890-test',
      MSRP__c = 10.00,
      List_Price__c = 9.50
    );
    insert mp;
    Test.startTest();
    String jsonResult = lgnd_QuickPartsCreateController.fetchInitOptions( mp.Id );
    lgnd_QuickPartsCreateController.OptionsWrapper result =
      (lgnd_QuickPartsCreateController.OptionsWrapper)JSON.deserialize( jsonResult,
                                                                        lgnd_QuickPartsCreateController.OptionsWrapper.class);
    Test.stopTest();
    /* we have to add 1 to account for the Mercury
       Account which gets created in Factory_CustomSettings
     */
    System.assertEquals( ( suppliers.size() + 1 ), result.suppliers.size() );
    System.assertEquals( mp.Id, result.dataWrapper.externalReferenceId );
    System.assert( result.dataWrapper.part != null );
    System.assertEquals( mp.MSRP__c, result.dataWrapper.retailPrice );
    System.assertEquals( mp.Description__c, result.dataWrapper.part.Name );
    System.assertEquals( suppliers[0].Id, result.dataWrapper.part.AcctSeedERP__Default_Vendor__c);
    System.assertEquals( mp.List_Price__c, result.dataWrapper.part.AcctSeed__Unit_Cost__c);
  }

  @isTest
  static void fetchInitOptions_withInvalidExternalProduct_Test()
  {
    Account[] suppliers = Factory_Account.insertSupplierAccounts(10);
    try {
      String jsonResult = lgnd_QuickPartsCreateController.fetchInitOptions( suppliers[0].Id );
    }
    catch( Exception e )
    {
      System.assertEquals('Invalid External Product Id Supplied', e.getMessage() );
    }
  }

  @isTest
  static void fetchInitOptions_withLinkedMercuryProduct_Test()
  {
    Product2 p = Factory_Product.createNonSerializedProduct( 'Part', 'Hardware' );
    Mercury_Product__c mp = new Mercury_Product__c(
      Description__c = 'Test Merc Part',
      Code__c = '1000001-test',
      UPC__c = '1234567890-test',
      MSRP__c = 10.00,
      List_Price__c = 9.50,
      Salesforce_Product__c = p.Id
    );
    insert mp;
    try {
      String jsonResult = lgnd_QuickPartsCreateController.fetchInitOptions( mp.Id );
    }
    catch( Exception e )
    {
      System.assertEquals('Mercury Product already linked to a Salesforce Product', e.getMessage() );
    }
  }

  @isTest
  static void createPart_Test()
  {
    Account[] suppliers = Factory_Account.insertSupplierAccounts(10);
    lgnd_QuickPartsCreateController.DataWrapper dw = new lgnd_QuickPartsCreateController.DataWrapper();
    dw.retailPrice = 20.00;
    dw.partnerPrice = 15.00;
    dw.part = new Product2(
      Name = 'testPart',
      Description = 'This is just a part from a test class',
      ProductCode = 'test123test567',
      Taxable__c = true,
      AcctSeed__Inventory_Product__c = true,
      AcctSeedERP__Default_Vendor__c = suppliers[0].Id
    );
    Test.startTest();
    Product2 result = lgnd_QuickPartsCreateController.createPart( JSON.serialize( dw ) );
    PricebookEntry[] pbes = [SELECT Id FROM PricebookEntry WHERE Product2Id = : result.Id ];
    Test.stopTest();
    System.assertEquals( 3, pbes.size() );
    System.assertEquals( dw.part.Name, result.Name );
    System.assertEquals( dw.part.Name, result.Name_FR__c );
    System.assertEquals( dw.part.Description, result.Description );
    System.assertEquals( dw.part.Description, result.Description_FR__c );
  }

   @isTest
  static void createPart_withMercuryProduct_Test()
  {
    Account[] suppliers = Factory_Account.insertSupplierAccounts(10);
    insert new Utility_Account__c( Mercury__c = suppliers[0].Id );
    Mercury_Product__c mp = new Mercury_Product__c(
      Description__c = 'Test Merc Part',
      Code__c = '1000001-test',
      UPC__c = '1234567890-test',
      MSRP__c = 10.00,
      List_Price__c = 9.50
    );
    insert mp;
    lgnd_QuickPartsCreateController.DataWrapper dw = new lgnd_QuickPartsCreateController.DataWrapper();
    dw.externalReferenceId = mp.Id;
    dw.retailPrice = mp.MSRP__c;
    dw.part = new Product2(
      Name = mp.Description__c,
      Description = 'This is just a part from a test class',
      ProductCode = mp.Code__c,
      Taxable__c = true,
      AcctSeed__Inventory_Product__c = true
    );
    Test.startTest();
    Product2 result = lgnd_QuickPartsCreateController.createPart( JSON.serialize( dw ) );
    PricebookEntry[] pbes = [SELECT Id FROM PricebookEntry WHERE Product2Id = : result.Id ];
    Mercury_Product__c mercProd = [SELECT Id, Salesforce_Product__c
                                   FROM Mercury_Product__c
                                   WHERE Id = :mp.Id];
    Test.stopTest();
    System.assertEquals( 2, pbes.size() );
    System.assertEquals( dw.part.Name, result.Name );
    System.assertEquals( dw.part.Name, result.Name_FR__c );
    System.assertEquals( dw.part.Description, result.Description );
    System.assertEquals( dw.part.Description, result.Description_FR__c );
    System.assertEquals( result.Id, mercProd.Salesforce_Product__c );
  }
}