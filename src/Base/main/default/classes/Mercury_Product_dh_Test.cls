@isTest
private class Mercury_Product_dh_Test {
  static Product2[] prods;
  static Product2[] merc_prods;
  static Id retailPbId;
  static Id factoryPbId;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init(Integer productCount, Boolean createPbEntries) {
    Id mercAccount = Utility_Account__c.getOrgDefaults().Mercury__c;
    prods = Factory_Product.buildNonSerializedProducts('Part', 'Hardware', productCount);
    merc_prods = Factory_Product.buildNonSerializedProducts('Part', 'Hardware', productCount);
    for (Product2 p : merc_prods) {
      p.AcctSeedERP__Default_Vendor__c = mercAccount;
    }
    insert prods;
    insert merc_prods;
    //gcProduct.disableTrigger = ot;
    retailPbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    factoryPbId = Legend_Settings__c.getOrgDefaults().Default_Factory_Pricebook__c;
    if (createPbEntries)
      insertPBEntries();
  }

  private static void insertPBEntries() {
    List<Product2> allProds = new List<Product2>();
    allProds.addAll(prods);
    allProds.addAll(merc_prods);
    Factory_PricebookEntry.createStandardEntries(allProds, 0.00);
    PricebookEntry[] pbes = new List<PricebookEntry>();
    pbes.addAll(Factory_PricebookEntry.buildEntries(allProds, retailPbId, 1));
    pbes.addAll(Factory_PricebookEntry.buildEntries(allProds, factoryPbId, 1));
    insert pbes;
  }

  @isTest
  static void insertMercuryProductsWithPBEs_Test() {
    init(1, true);
    Test.startTest();
    Mercury_Product__c[] mps = new List<Mercury_Product__c>();
    for (Product2 p : merc_prods) {
      mps.add(new Mercury_Product__c(MSRP__c = 100, List_Price__c = 50, Code__c = p.ProductCode, Item_Class__c = '1'));
    }
    System.debug('Should hit trigger here');
    insert mps;
    Test.stopTest();
    Mercury_Product__c[] mps2 = [
      SELECT Id, Item_Class__c, Salesforce_Product__c
      FROM Mercury_Product__c
      WHERE Salesforce_Product__c != NULL
    ];
    PricebookEntry pbe_r = [
      SELECT Id, UnitPrice, Product2.AcctSeed__Unit_Cost__c
      FROM PricebookEntry
      WHERE Product2Id = :merc_prods[0].Id AND Pricebook2Id = :retailPbId
    ];
    PricebookEntry pbe_f = [
      SELECT Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :merc_prods[0].Id AND Pricebook2Id = :factoryPbId
    ];
    System.assertEquals(1, mps2.size());
    System.assertEquals(100, pbe_r.UnitPrice);
    System.assertEquals(50, pbe_f.UnitPrice);
    System.assertEquals(50, pbe_r.Product2.AcctSeed__Unit_Cost__c);
    //System.assertEquals( 4, mp.Item_Class__c.length() );
  }

  @isTest
  static void insertMercuryProductsWithoutPBEs_Test() {
    init(1, false);
    Test.startTest();
    Mercury_Product__c[] mps = new List<Mercury_Product__c>();
    for (Product2 p : merc_prods) {
      mps.add(new Mercury_Product__c(MSRP__c = 100, List_Price__c = 50, Code__c = p.ProductCode));
    }
    System.debug('Should hit trigger here');
    insert mps;
    Test.stopTest();
    Mercury_Product__c[] mps2 = [
      SELECT Id, Salesforce_Product__c
      FROM Mercury_Product__c
      WHERE Salesforce_Product__c != NULL
    ];
    PricebookEntry pbe_r = [
      SELECT Id, UnitPrice, Product2.AcctSeed__Unit_Cost__c
      FROM PricebookEntry
      WHERE Product2Id = :merc_prods[0].Id AND Pricebook2Id = :retailPbId
    ];
    PricebookEntry pbe_f = [
      SELECT Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :merc_prods[0].Id AND Pricebook2Id = :factoryPbId
    ];
    System.assertEquals(1, mps2.size());
    System.assertEquals(100, pbe_r.UnitPrice);
    System.assertEquals(50, pbe_f.UnitPrice);
    System.assertEquals(50, pbe_r.Product2.AcctSeed__Unit_Cost__c);
  }

  @isTest
  static void updateMercuryProduct_Bulk_Test() {
    Test.startTest();
    init(100, false);
    Mercury_Product__c[] mps = new List<Mercury_Product__c>();
    for (Product2 p : merc_prods) {
      mps.add(new Mercury_Product__c(MSRP__c = 1, List_Price__c = 1, Code__c = p.ProductCode));
    }
    System.debug('Product 0 code');
    System.debug(merc_prods[0].ProductCode);
    System.debug('mps 0 code');
    System.debug(mps[0].Code__c);
    System.debug('Should NOT hit trigger here');
    insert mps;
    //Mercury_Product_dh.disableTrigger = origTriggerState;

    for (Mercury_Product__c mp : mps) {
      mp.MSRP__c = 200;
      mp.List_Price__c = 400;
      mp.Item_Class__c = '1';
    }
    System.debug('Should hit trigger here');
    update mps;
    Test.stopTest();

    Mercury_Product__c[] mps2 = [
      SELECT Id, Salesforce_Product__c, Item_Class__c
      FROM Mercury_Product__c
      WHERE Salesforce_Product__c != NULL
    ];
    PricebookEntry pbe_r = [
      SELECT Id, UnitPrice, Product2.AcctSeed__Unit_Cost__c
      FROM PricebookEntry
      WHERE Product2Id = :merc_prods[0].Id AND Pricebook2Id = :retailPbId
    ];
    PricebookEntry pbe_f = [
      SELECT Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :merc_prods[0].Id AND Pricebook2Id = :factoryPbId
    ];
    System.assertEquals(100, mps2.size());
    System.assertEquals(4, mps2[0].Item_Class__c.length());
    System.assertEquals(200, pbe_r.UnitPrice);
    System.assertEquals(400, pbe_f.UnitPrice);
    System.assertEquals(400, pbe_r.Product2.AcctSeed__Unit_Cost__c);
  }
}
