@isTest( seeAllData=true )
public with sharing class OpportunityFactory {
  static AcctSeed__GL_Account__c revenueAccount;
  static AcctSeed__GL_Account__c expenseAccount;
  static AcctSeed__GL_Account__c inventoryAccount;
  static AcctSeedERP__Warehouse__c warehouse;
  static AcctSeed__Accounting_Variable__c ontarioTaxZone;

  static Id stdPB2Id = Test.getStandardPricebookId();

  static {
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
    warehouse = AcctSeed_Settings_Factory.getWarehouse('Whitefish');
    ontarioTaxZone = AcctSeed_Settings_Factory.getTaxZone('Ontario');
    //OpportunityTriggerHandler.disableAutoPricebookSet = true;
    Opportunity_Service.disableAutoPricebookSet = true;
  }

  public static Opportunity buildBasicRetail(Id acctId)
  {
    //opportunityTriggerHandler.disableAutoPricebookSet = false;
    Opportunity_Service.disableAutoPricebookSet = false;
    Id retailRT = LGND_Utilities.recordTypeIdFromName('Opportunity', 'Retail');
    return new Opportunity(
      AccountId = acctId,
      RecordTypeId = retailRT,
      Name = 'Test Retail Opp',
      CloseDate = Date.today(),
      StageName = 'Quoting'
    );
  }

  public static Opportunity insertBasic()
  {
    Opportunity opp = createBareBones('Basic opportunity');
    insert opp;
    //CommissionRecord.recreateCommissionRecords(opp);
    return opp;
  }

  public static Opportunity insertRetailCounterSale()
  {
    Opportunity opp = createBareBones('Test Retail Counter Sale');
    opp.RecordTypeId = LGND_Utilities.recordTypeIdFromName('Opportunity', 'Retail Counter Sale');
    opp.StageName = 'Picked Up / Won';
    insert opp;
    List<Product2> prods = InventoryTestFactory.insertTestProductsWithStandardPricebookEntries(3, 'Part');
    Set<id> prodIds = new Set<Id>();
    for( Product2 p : prods )
    {
      prodIds.add(p.Id);
    }
    List<PricebookEntry> pbes = [SELECT Id, Pricebook2Id, Product2.Description, UnitPrice
                                 FROM PricebookEntry
                                 WHERE Pricebook2Id = :opp.Pricebook2Id
                                 AND Product2Id IN :prodIds];

    List<OpportunityLineItem> olItems = new List<OpportunityLineItem>();
    for( PricebookEntry pbe : pbes )
    {
      olItems.add( new OpportunityLineItem(
        OpportunityId = opp.Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = pbe.UnitPrice,
        Description = pbe.Product2.Description
        )
      );
    }
    insert olItems;
    return opp;
  }

  public static Opportunity insertRetailBoatSale()
  {
    Opportunity opp = createBareBones('Test Retail Boat Sale');
    opp.RecordTypeId = LGND_Utilities.recordTypeIdFromName('Opportunity', 'Retail');
    insert opp;
    //CommissionRecord.recreateCommissionRecords(opp);
    List<Product2> products = new List<Product2>();
    List<PricebookEntry> pbEntries = new List<PricebookEntry>();
    Map<String, Decimal> priceMap = new Map<String, Decimal>{'Test Boat' => 12000.00,
                                                             'Test Motor' => 4000,
                                                             'Test Trailer' => 3000,
                                                             'Test Hardware Part' => 200,
                                                             'Test Seating Part' => 200,
                                                             'Test Safety Part' => 200,
                                                             'Test Warranty Coverage' => 200 };

    Product2 boat = new Product2(
      RecordTypeId = recordTypeIdFromString('Boat'),
      Family = 'Pontoon',
      Name = 'Test Boat',
      isActive = true
    );
    products.add(boat);

    Product2 motor = new Product2(
      RecordTypeId = recordTypeIdFromString('Motor'),
      Name = 'Test Motor',
      isActive = true
    );
    products.add(motor);

    Product2 trailer = new Product2(
      RecordTypeId = recordTypeIdFromString('Trailer'),
      Name = 'Test Trailer',
      isActive = true
    );
    products.add(trailer);

    Product2 part1 = new Product2(
      RecordTypeId = recordTypeIdFromString('Part'),
      Name = 'Test Hardware Part',
      Family = 'Hardware',
      isActive = true
    );
    products.add(part1);

    Product2 part2 = new Product2(
      RecordTypeId = recordTypeIdFromString('Part'),
      Name = 'Test Seating Part',
      Family = 'Seating',
      isActive = true
    );
    products.add(part2);

    Product2 part3 = new Product2(
      RecordTypeId = recordTypeIdFromString('Part'),
      Name = 'Test Safety Part',
      Family = 'Saftey',
      isActive = true
    );
    products.add(part3);

    Product2 protection = new Product2(
      RecordTypeId = recordTypeIdFromString('Protection and Services'),
      Name = 'Test Warranty Coverage',
      isActive = true
    );
    products.add(protection);
    for( Product2 p : products )
    {
      p.AcctSeed__Accounting_Type__c = 'Taxable_Product';
      p.AcctSeed__Expense_GL_Account__c = expenseAccount.Id;
      p.AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id;
      p.AcctSeed__Revenue_GL_Account__c = revenueAccount.Id;
      p.AcctSeed__Unit_Cost__c = 100.00;
    }
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert products;
    gcProduct.disableTrigger = orig;

    Map<Id, Product2> productMap = new Map<Id, Product2>(products);

    for(Product2 p : products){
      pbEntries.add( new PricebookEntry(
          Product2Id = p.Id,
          Pricebook2Id = stdPB2Id,
          isActive = true,
          UnitPrice = priceMap.get(p.Name)
        )
      );
    }
    insert pbEntries;

    List<OpportunityLineItem> olItems = new List<OpportunityLineItem>();

    for(PricebookEntry pbe : pbEntries)
    {
      Product2 p = productMap.get(pbe.Product2Id);

      OpportunityLineItem oli = new OpportunityLineItem(
        OpportunityId = opp.Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1
        );

      if( p.Name == 'Test Boat')
      {
        boat = p;
        oli.BoatBuilderItem__c = true;
        oli.UnitPrice = pbe.UnitPrice;
        oli.Description = 'Boat Package';
      }
      else if( p.Name == 'Test Motor')
      {
        oli.BoatBuilderItem__c = true;
        oli.UnitPrice = 600;
        oli.Description = 'Motor Upgrade';
      }
      else if( p.Name == 'Test Trailer')
      {
        oli.BoatBuilderItem__c = true;
        oli.UnitPrice = 0;
        oli.Description = 'Included With Boat';
      }
      else if( p.Name == 'Test Hardware Part')
      {
        oli.BoatBuilderItem__c = false;
        oli.UnitPrice = 0;
        oli.Description = p.Name;
      }
      else if( p.Name == 'Test Seating Part')
      {
        oli.BoatBuilderItem__c = true;
        oli.UnitPrice = pbe.UnitPrice;
      }
      else if( p.Name == 'Test Safety Part')
      {
        oli.BoatBuilderItem__c = true;
        oli.UnitPrice = 0;
        oli.Description = 'Included with Boat';
      }
      else if( p.Name == 'Test Warranty Coverage' )
      {
        oli.BoatBuilderItem__c = true;
        oli.UnitPrice = pbe.UnitPrice;
      }
      olItems.add(oli);
    }
    insert olItems;
     // going to create a Service Contract on the boat here along with Product_Option_c entry
    Product2 boatServiceContract = new Product2(
      RecordTypeId = recordTypeIdFromString('Protection and Services'),
      Name = 'Test Boat Service Contract',
      isActive = true
    );
    insert boatServiceContract;
    PricebookEntry pbe = new PricebookEntry(
      Product2Id = boatServiceContract.Id,
      Pricebook2Id = stdPB2Id,
      isActive = true,
      UnitPrice = 200
    ) ;
    insert pbe;
    Product_Option__c po = new Product_Option__c(
      From_Product__c = boatServiceContract.Id,
      To_Product__c = boat.Id,
      Standard__c = 1,
      Maximum__c = 1
    );
    insert po;

    return opp;
  }

  private static Opportunity createBareBones(String oppName)
  {
    Account acct = AccountFactory.insertPersonAccount();
    return new Opportunity(
      Name= oppName,
      AccountId = acct.Id,
      CloseDate=Date.today(),
      Pricebook2Id = stdPB2Id,
      StageName = 'Quoting'
      );
  }

  private static Id recordTypeIdFromString(String rtName)
  {
    Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Product2;
    Map<String,Schema.RecordTypeInfo> Product2RecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
    return Product2RecordTypeInfo.get(rtName).getRecordTypeId();
  }

}