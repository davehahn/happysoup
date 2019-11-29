@isTest(seeAllData=true)
private class RetailCounterSaleController_Test {

  static List<Account> accounts;
  static List<Product2> products;
  static List<Pricebook2> pbs;
  static LGND_Store testStore = new LGND_Store('Barrie');

  static {
    AcctSeed_Settings_Factory.getWarehouse('Whitefish');
  }

  @isTest static void storeLocation_Test()
  {
    User barrieAdmin = User_TestFactory.newSysAdmin('dave', 'hahn', 'Barrie');
    insert barrieAdmin;
    User whitefishAdmin = User_TestFactory.newSysAdmin('trent', 'rez', 'Whitefish');
    insert whitefishAdmin;
    User openAdmin = User_TestFactory.newSysAdmin('les', 'clay');
    insert openAdmin;

    System.runAs(barrieAdmin)
    {
      RetailCounterSaleController ext = new RetailCounterSaleController( new ApexPages.StandardController(new Opportunity() ) );
      LGND_Store store = new LGND_Store('Barrie');
      System.assertEquals(store.Province, ext.lgnd_store.Province);
      System.assertEquals(store.City, ext.lgnd_store.City);
      System.assertEquals(store.Street, ext.lgnd_store.Street);
      System.assertEquals(store.Phone, ext.lgnd_store.Phone);
      System.assertEquals(store.TollFree, ext.lgnd_store.TollFree);
    }
    System.runAs(whitefishAdmin)
    {
      RetailCounterSaleController ext = new RetailCounterSaleController( new ApexPages.StandardController(new Opportunity() ) );
      LGND_Store store = new LGND_Store('Whitefish');
      System.assertEquals(store.Province, ext.lgnd_store.Province);
      System.assertEquals(store.City, ext.lgnd_store.City);
      System.assertEquals(store.Street, ext.lgnd_store.Street);
      System.assertEquals(store.Phone, ext.lgnd_store.Phone);
      System.assertEquals(store.TollFree, ext.lgnd_store.TollFree);
    }
    System.runAs(openAdmin)
    {
      RetailCounterSaleController ext = new RetailCounterSaleController( new ApexPages.StandardController(new Opportunity() ) );
      LGND_Store store = new LGND_Store('Whitefish');
      System.assertEquals(store.Province, ext.lgnd_store.Province);
      System.assertEquals(store.City, ext.lgnd_store.City);
      System.assertEquals(store.Street, ext.lgnd_store.Street);
      System.assertEquals(store.Phone, ext.lgnd_store.Phone);
      System.assertEquals(store.TollFree, ext.lgnd_store.TollFree);
    }

  }

  private static void initAccountData()
  {
    accounts = new List<Account>();
    accounts.add( new Account(FirstName = 'Dave', LastName='Hahn'));
    accounts.add( new Account(FirstName = 'Doug', LastName='Xzvgtreb'));
    accounts.add( new Account(FirstName = 'Sean', LastName='McKenty'));
    accounts.add( new Account(FirstName = 'Julie', LastName='Hahn'));

    insert accounts;
  }

  private static void initProductData()
  {
    Id partRTId = LGND_Utilities.recordTypeIdFromName('Product2', 'Part');
    Id feeRTId = LGND_Utilities.recordTypeIdFromName('Product2', 'Fees');

    AcctSeed__GL_Account__c revenueAccount;
    AcctSeed__GL_Account__c expenseAccount;
    AcctSeed__GL_Account__c inventoryAccount;
    List<AcctSeed__GL_Account__c> glAccts = new List<AcctSeed__GL_Account__c>();
    revenueAccount = new AcctSeed__GL_Account__c(Name='Test Revenue Account',
                                                 AcctSeed__Active__c = true,
                                                 AcctSeed__Type__c = 'Revenue');
    expenseAccount = new AcctSeed__GL_Account__c(Name='Test Expense Account',
                                                 AcctSeed__Active__c = true,
                                                 AcctSeed__Type__c = 'Expense');
    inventoryAccount = new AcctSeed__GL_Account__c(Name='Test Inventory Account',
                                                 AcctSeed__Active__c = true,
                                                 AcctSeed__Sub_Type_1__c = 'Assets',
                                                 AcctSeed__Type__c = 'Balance Sheet');
    glAccts.add(revenueAccount);
    glAccts.add(expenseAccount);
    glAccts.add(inventoryAccount);

    insert glAccts;

    products = new List<Product2>();
    products.add( new Product2( Name='kfrtwy',
                                RecordTypeId = partRTId,
                                ProductCode='abc123',
                                IsActive=true,
                                 AcctSeed__Expense_GL_Account__c = expenseAccount.Id,
                                 AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id,
                                 AcctSeed__Revenue_GL_Account__c = revenueAccount.Id,
                                 AcctSeed__Unit_Cost__c = 100.00,
                                AcctSeed__Accounting_Type__c = 'Taxable Product') );
    products.add( new Product2( Name='dfewsd',
                                RecordTypeId = partRTId,
                                ProductCode='bcf564',
                                IsActive=true,
                                 AcctSeed__Expense_GL_Account__c = expenseAccount.Id,
                                 AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id,
                                 AcctSeed__Revenue_GL_Account__c = revenueAccount.Id,
                                 AcctSeed__Unit_Cost__c = 100.00,
                                AcctSeed__Accounting_Type__c = 'Taxable Product') );
    products.add( new Product2( Name='qwerty',
                                RecordTypeId = partRTId,
                                ProductCode='lkh678',
                                IsActive=true,
                                 AcctSeed__Expense_GL_Account__c = expenseAccount.Id,
                                 AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id,
                                 AcctSeed__Revenue_GL_Account__c = revenueAccount.Id,
                                 AcctSeed__Unit_Cost__c = 100.00,
                                AcctSeed__Accounting_Type__c = 'Taxable Product') );
    products.add( new Product2( Name='mhtrdcs',
                                RecordTypeId = partRTId,
                                ProductCode='cow398',
                                IsActive=true,
                                 AcctSeed__Expense_GL_Account__c = expenseAccount.Id,
                                 AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id,
                                 AcctSeed__Revenue_GL_Account__c = revenueAccount.Id,
                                 AcctSeed__Unit_Cost__c = 100.00,
                                AcctSeed__Accounting_Type__c = 'Taxable Product') );
    products.add( new Product2( Name='bhuvreq',
                                RecordTypeId = partRTId,
                                ProductCode='bfp945',
                                IsActive=true,
                                 AcctSeed__Expense_GL_Account__c = expenseAccount.Id,
                                 AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id,
                                 AcctSeed__Revenue_GL_Account__c = revenueAccount.Id,
                                 AcctSeed__Unit_Cost__c = 100.00,
                                AcctSeed__Accounting_Type__c = 'Taxable Product') );
    products.add( new Product2( Name='fee123',
                                RecordTypeId = feeRTId,
                                ProductCode='fee123',
                                IsActive=true,
                                AcctSeed__Accounting_Type__c = 'Taxable Product') );
    products.add( new Product2( Name='fee234',
                                RecordTypeId = feeRTId,
                                ProductCode='fee234',
                                IsActive=true,
                                AcctSeed__Accounting_Type__c = 'Taxable Product') );
    products.add( new Product2( Name='fee345',
                                RecordTypeId = feeRTId,
                                ProductCode='fee345',
                                IsActive=true,
                                AcctSeed__Accounting_Type__c = 'Taxable Product') );
    insert products;

    pbs = new List<Pricebook2>();
    pbs.add( new Pricebook2( Name = '2014', IsActive = true) );
    pbs.add( new Pricebook2( Name = '2015', IsActive = true) );
    insert pbs;

    Pricebook2 stdPb = [SELECT Id, Name from Pricebook2 WHERE IsStandard = true];
    List<PricebookEntry> pbEntries = new List<PricebookEntry>();
    List<Product_Fee_Amount__c> feeAmounts = new List<Product_Fee_Amount__c>();
    for(Product2 p : products)
    {
      pbEntries.add( new PricebookEntry(
        Product2Id = p.Id,
        Pricebook2Id = stdPb.Id,
        UnitPrice = 0,
        IsActive = true
        ));
    }
    insert pbEntries;
    pbEntries = new List<PricebookEntry>();
    for(Pricebook2 pb : pbs)
    {
        for(Product2 p : products)
        {
          pbEntries.add( new PricebookEntry(
            Product2Id = p.Id,
            Pricebook2Id = pb.Id,
            UnitPrice = 100.00,
            IsActive = true
            ));
          if( p.RecordTypeId == feeRTId )
          {
            feeAmounts.add( new Product_Fee_Amount__c(
              Price_Book__c = pb.Id,
              Fee_Product__c = p.Id,
              Province__c = 'Ontario',
              Amount__c = 100.00
              )
            );
          }
        }
    }
    insert pbEntries;
    insert feeAmounts;

    List<Product_Option__c> opts = new List<Product_Option__c>();
    opts.add( new Product_Option__c(
        To_Product__c = products[0].Id,
        From_Product__c = products[3].Id,
        Standard__c = 1,
        Maximum__c = 1
      )
    );
    opts.add( new Product_Option__c(
        To_Product__c = products[0].Id,
        From_Product__c = products[4].Id,
        Standard__c = 1,
        Maximum__c = 1
      )
    );
    insert opts;

  }

  private static void createInitialSale()
  {
    initAccountData();
    initProductData();
    List<RetailCounterSaleController.LineItemWrapper> lineItems = new List<RetailCounterSaleController.LineItemWrapper>();
    lineItems.add( RetailCounterSaleController.productSearch(products[0].Name, pbs[0].Id)[0] );
    lineItems.add( RetailCounterSaleController.productSearch(products[1].Name, pbs[0].Id)[0] );
     // build up the account data which simulates being sent from JS
    Map<String, String> accountData = new Map<String, String>();
    accountData.put('Id', accounts[0].Id);
    accountData.put('FirstName', accounts[0].FirstName);
    accountData.put('LastName', accounts[0].LastName);
    accountData.put('PersonEmail', 'dave@davehahn.me');
    accountData.put('PersonMobilePhone', '(705) 955-3333');

    // build up selectedItems data which simulates being sent from JS
    List<Map<String, String>> selectedItems = new List<Map<String, String>>();
    Map<String, String> li;
    for( RetailCounterSaleController.LineItemWrapper liw : lineItems )
    {
      li = new Map<String,String>();
      li.put('Quantity', '1');
      li.put('ListPrice', String.valueOf( liw.unitPrice ) );
      li.put('UnitPrice', String.valueOf( liw.unitPrice ) );
      li.put('PricebookEntryId', liw.pricebookEntryId );
      li.put('Description', liw.description);
      selectedItems.add(li);
    }
    Map<String, String> oppData = new Map<String, String>();
    oppData.put('Id', null);
    oppData.put('Pricebook2Id', pbs[0].Id);
    oppData.put('TaxationProvince__c', testStore.Province);
    oppData.put('TaxOverRide__c', ' false');
    oppData.put('Payment_Method__c', 'Pending');


    //Save the NEW Opportunity
    RetailCounterSaleController.createSale(JSON.serialize( accountData ), JSON.serialize(selectedItems), JSON.serialize(oppData) );
  }

  @isTest static void accountSearchTest()
  {
    initAccountData();
    List<Account> searchResults = RetailCounterSaleController.accountSearch('Xzvgtreb');

    System.assertEquals( 1, searchResults.size() );
  }

  @isTest static void productSearchTest()
  {
    initProductData();
    List<RetailCounterSaleController.LineItemWrapper> foundProducts = RetailCounterSaleController.productSearch('kfrtwy', pbs[0].Id);
    System.assertEquals(1, foundProducts.size() );
  }

  @isTest static void fetchFeesTest()
  {
    initProductData();
    Map<String, Map<String,RetailCounterSaleController.LineItemWrapper>> fees = RetailCounterSaleController.fetchFees(pbs[0].Id);

    System.assertEquals(3, fees.get('Ontario').size() );
  }

  @isTest static void createNewSale_Test()
  {
    Test.startTest();
    createInitialSale();

    List<Opportunity> opps = [SELECT Id, Amount, TaxableTotal_LineItems__c, StageName,  TotalTaxes__c, Total_Amount__c, Account.PersonEmail, Account.PersonMobilePhone, Pricebook2.Name,
                              (SELECT Id FROM OpportunityLineItems)
                              FROM Opportunity WHERE AccountId = :accounts[0].Id];

    //List<CommissionRecord__c> comRecords = [SELECT Id, Type__c, Stage__c,
    //                                        (SELECT Id, Quantity__c, Sale_Price__c, CommissionRate__c FROM CommissionLineItems__r)
    //                                       FROM CommissionRecord__c
    //                                       WHERE OpportunityId__c = :opps[0].Id];
    Test.stopTest();

    System.assertEquals( 1, opps.size() );
    System.assertEquals( 'Pending Pickup', opps[0].StageName );
    //System.assertEquals( 1, comRecords.size() );
    System.assertEquals('2014', opps[0].Pricebook2.Name);
    System.assertEquals( 'dave@davehahn.me', opps[0].Account.PersonEmail);
    System.assertEquals( '(705) 955-3333', opps[0].Account.PersonMobilePhone);
    System.assertEquals(2, opps[0].OpportunityLineItems.size() );
    //System.assertEquals( 2, comRecords[0].CommissionLineItems__r.size() );
    //for( CommissionLineItem__c cli : comRecords[0].CommissionLineItems__r )
    //{
    //  System.assertEquals(5, cli.CommissionRate__c);
    //  System.assertEquals(1, cli.Quantity__c);
    //}

  }

  @isTest static void addLineItem_Test()
  {
    Test.startTest();
    createInitialSale();
    Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :accounts[0].Id];
    ApexPages.StandardController std = new ApexPages.StandardController(opp);
    RetailCounterSaleController ext = new RetailCounterSaleController(std);
    Map<String, String> accountData = new Map<String, String>{'Id' => accounts[0].Id};
    List<Map<String, String>> selectedItems = new List<Map<String, String>>();
    Map<String, String> li;
    //recreate currently selected Items
    for( RetailCounterSaleController.LineItemWrapper liw : ext.lineItems )
    {
      li = new Map<String,String>();
      li.put('Quantity', '1');
      li.put('Id', liw.lineItemId);
      li.put('ListPrice', String.valueOf( liw.unitPrice ) );
      li.put('UnitPrice', String.valueOf( liw.unitPrice ) );
      li.put('PricebookEntryId', liw.pricebookEntryId );
      li.put('Description', liw.description);
      selectedItems.add(li);
    }
    //add a new Item
    RetailCounterSaleController.LineItemWrapper newItem = RetailCounterSaleController.productSearch(products[2].Name, pbs[0].Id)[0];
    li = new Map<String,String>();
    li.put('Quantity', '1');
    li.put('ListPrice', String.valueOf( newItem.unitPrice ) );
    li.put('UnitPrice', String.valueOf( newItem.unitPrice ) );
    li.put('PricebookEntryId', newItem.pricebookEntryId );
    li.put('Description', newItem.description);
    selectedItems.add(li);

    Map<String, String> oppData = new Map<String, String>();
    oppData.put('Id', opp.Id);
    oppData.put('Pricebook2Id', pbs[0].Id);
    oppData.put('TaxationProvince__c', testStore.Province);
    oppData.put('TaxOverRide__c', ' false');
    oppData.put('Payment_Method__c', 'Pending');

    RetailCounterSaleController.createSale(JSON.serialize( accountData ), JSON.serialize(selectedItems), JSON.serialize(oppData) );
    List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
    Test.stopTest();

    System.assertEquals( 3, olis.size() );
  }

  @isTest static void removeItem_Test()
  {
    Test.startTest();
    createInitialSale();
    Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :accounts[0].Id];
    ApexPages.StandardController std = new ApexPages.StandardController(opp);
    RetailCounterSaleController ext = new RetailCounterSaleController(std);
    Map<String, String> accountData = new Map<String, String>{'Id' => accounts[0].Id};
    List<Map<String, String>> selectedItems = new List<Map<String, String>>();
    Map<String, String> li;
    //recreate currently selected Items
    for( RetailCounterSaleController.LineItemWrapper liw : ext.lineItems )
    {
      li = new Map<String,String>();
      li.put('Quantity', '1');
      li.put('Id', liw.lineItemId);
      li.put('ListPrice', String.valueOf( liw.unitPrice ) );
      li.put('UnitPrice', String.valueOf( liw.unitPrice ) );
      li.put('PricebookEntryId', liw.pricebookEntryId );
      li.put('Description', liw.description);
      selectedItems.add(li);
    }
    selectedItems[0].put('Quantity', '0');
    Map<String, String> oppData = new Map<String, String>();
    oppData.put('Id', opp.Id);
    oppData.put('Pricebook2Id', pbs[0].Id);
    oppData.put('TaxationProvince__c', testStore.Province);
    oppData.put('TaxOverRide__c', ' false');
    oppData.put('Payment_Method__c', 'Pending');
    RetailCounterSaleController.createSale(JSON.serialize( accountData ), JSON.serialize(selectedItems), JSON.serialize(oppData));
    List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
    Test.stopTest();

    System.assertEquals( 1, olis.size() );
  }

  @isTest static void getter_Tests()
  {
    Test.startTest();
    createInitialSale();
    Opportunity opp = [SELECT Id, (SELECT Id FROM OpportunityLineItems) FROM Opportunity WHERE AccountId = :accounts[0].Id];
    ApexPages.StandardController std = new ApexPages.StandardController(opp);
    RetailCounterSaleController ext = new RetailCounterSaleController(std);
    ext.getCancelURL();
    Map<String, String> provTaxRates = (Map<String, String>)JSON.deserialize(ext.getProvincialTaxRates(), Map<String, String>.class);

    Test.stopTest();

    List<RetailCounterSaleController.LineItemWrapper> items = (List<RetailCounterSaleController.LineItemWrapper>)JSON.deserialize(ext.getLineItemsJSON(), List<RetailCounterSaleController.LineItemWrapper>.class);
    Opportunity opp2 = (Opportunity)JSON.deserialize( ext.getOpportunityJSON(), Opportunity.class);

    System.assert( ext.getPriceBooks().size() > 0 );
    System.assertEquals( TaxRate__c.getAll().keySet().size() + 1, ext.getProvinceOptions().size() );
    System.assertEquals( TaxRate__c.getAll().keySet().size(), provTaxRates.keySet().size() );
    System.assertEquals( opp.OpportunityLineItems.size(), items.size() );
    System.assertEquals( opp.Id, opp2.Id);
  }

  @isTest static void pricebookAndStageChangeTest()
  {
    Test.startTest();
    createInitialSale();
    Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :accounts[0].Id];
    ApexPages.StandardController std = new ApexPages.StandardController(opp);
    RetailCounterSaleController ext = new RetailCounterSaleController(std);
    Map<String, String> accountData = new Map<String, String>{'Id' => accounts[0].Id};
    List<Map<String, String>> selectedItems = new List<Map<String, String>>();
    Map<String, String> li;

    //add a new Item
    RetailCounterSaleController.LineItemWrapper newItem = RetailCounterSaleController.productSearch(products[0].Name, pbs[1].Id)[0];
    li = new Map<String,String>();
    li.put('Quantity', '1');
    li.put('ListPrice', String.valueOf( newItem.unitPrice ) );
    li.put('UnitPrice', String.valueOf( newItem.unitPrice ) );
    li.put('PricebookEntryId', newItem.pricebookEntryId );
    li.put('Description', newItem.description);
    selectedItems.add(li);
     //add a new Item
    newItem = RetailCounterSaleController.productSearch(products[1].Name, pbs[1].Id)[0];
    li = new Map<String,String>();
    li.put('Quantity', '1');
    li.put('ListPrice', String.valueOf( newItem.unitPrice ) );
    li.put('UnitPrice', String.valueOf( newItem.unitPrice ) );
    li.put('PricebookEntryId', newItem.pricebookEntryId );
    li.put('Description', newItem.description);
    selectedItems.add(li);

    Map<String, String> oppData = new Map<String, String>();
    oppData.put('Id', opp.Id);
    oppData.put('Pricebook2Id', pbs[1].Id);
    oppData.put('TaxationProvince__c', testStore.Province);
    oppData.put('TaxOverRide__c', ' false');
    oppData.put('Payment_Method__c', 'Cash');

    RetailCounterSaleController.createSale(JSON.serialize( accountData ), JSON.serialize(selectedItems), JSON.serialize(oppData));

    Opportunity afterOpp = [SELECT Id, Pricebook2Id, StageName, (SELECT Id FROM OpportunityLineItems) FROM Opportunity WHERE Id = :opp.Id];

    System.assertEquals(2, afterOpp.OpportunityLineItems.size() );
    System.assertEquals( pbs[1].Id, afterOpp.Pricebook2Id );
    System.assertEquals( 'Picked Up / Won', afterOpp.StageName );
  }

}