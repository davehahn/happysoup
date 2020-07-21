@isTest
public with sharing class Factory_Product {

  static AcctSeed__GL_Account__c revenueAccount;
  static AcctSeed__GL_Account__c expenseAccount;
  static AcctSeed__GL_Account__c inventoryAccount;

  private static void buildGlAccounts()
  {
    List<AcctSeed__GL_Account__c> glAccts = new List<AcctSeed__GL_Account__c>();
    if( revenueAccount == null )
    {
      revenueAccount = new AcctSeed__GL_Account__c(Name='Test Revenue Account',
                                                   AcctSeed__Active__c = true,
                                                   AcctSeed__Type__c = 'Revenue');
      glAccts.add(revenueAccount);
    }
    if( expenseAccount == null )
    {
      expenseAccount = new AcctSeed__GL_Account__c(Name='Test Expense Account',
                                                   AcctSeed__Active__c = true,
                                                   AcctSeed__Type__c = 'Expense');
      glAccts.add(expenseAccount);
    }
    if( inventoryAccount == null )
    {
      inventoryAccount = new AcctSeed__GL_Account__c(Name='Test Inventory Account',
                                                   AcctSeed__Active__c = true,
                                                   AcctSeed__Sub_Type_1__c = 'Assets',
                                                   AcctSeed__Type__c = 'Balance Sheet');
      glAccts.add(inventoryAccount);
    }
    if( glAccts.size() > 0 )
      insert glAccts;
  }

  public static Product2 createSerializedProduct( String recordTypeName,
                                                  String family )
  {
    Product2 p = buildSerializedProduct( recordTypeName, family );
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert p;
    gcProduct.disableTrigger = orig;
    return p;
  }

  public static Product2[] buildSerializedProducts(
    String recordTypeName,
    String family,
    Integer count )
  {
    Product2[] prods = new List<Product2>();
    for( Integer i=0; i<count; i++ )
    {
      prods.add( buildSerializedProduct( recordTypeName, family ) );
    }
    return prods;
  }

  public static Product2[] createSerializedProducts( String recordTypeName,
                                                     String family,
                                                     Integer count )
  {
    Product2[] prods = buildSerializedProducts(
      recordTypeName,
      family,
      count
    );
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert prods;
    gcProduct.disableTrigger = orig;
    return prods;
  }

  public static Product2[] buildSerializedProducts_AvailableOnline(
    String recordTypeName,
    String family,
    Integer count )
  {
    Product2[] prods = new List<Product2>();
    for( Integer i=0; i<count; i++ )
    {
      Product2 p =  buildSerializedProduct( recordTypeName, family );
      p.Available_Online__c = true;
      prods.add( p );
    }
    return prods;
  }

  public static Product2[] createSerializedProducts_AvailableOnline( String recordTypeName,
                                                                     String family,
                                                                     Integer count )
  {
    Product2[] prods = buildSerializedProducts_AvailableOnline(
      recordTypeName,
      family,
      count
    );
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert prods;
    gcProduct.disableTrigger = orig;
    return prods;
  }

  public static Product2 createNonSerializedProduct( String recordTypeName,
                                                     String family )
  {
    Product2 p = buildNonSerializedProduct( recordTypeName, family );
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert p;
    gcProduct.disableTrigger = orig;
    return p;
  }

  public static Product2 buildSerializedProduct( String recordTypeName,
                                                 String family )
  {
    buildGlAccounts();
    Id rt = LGND_Utilities.recordTypeIdFromName('Product2', recordTypeName );
    String fam = recordTypeName == 'Motor' ? 'Mercury' : 'Legend';
    return new Product2(
      name = 'InventoryTest' + recordTypeName + Crypto.getRandomLong(),
      Family = family,
      recordTypeId = rt,
      AcctSeedERP__Serialized__c = true,
      GMBLASERP__Lot_Tracked__c = true,
      Can_be_Nest__c = recordTypeName == 'Boat',
      Can_be_Nested__c = recordTypeName != 'Boat',
      Make__c = fam,
      AcctSeed__Inventory_Product__c = true,
      AcctSeed__Inventory_Type__c = 'Purchased',
      AcctSeed__Accounting_Type__c = 'Taxable_Product',
      AcctSeed__Expense_GL_Account__c = expenseAccount.Id,
      AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id,
      AcctSeed__Revenue_GL_Account__c = revenueAccount.Id,
      AcctSeed__Unit_Cost__c = 100.00,
      Unique_Product_Code__c = 'pcode-' + LGND_Utilities.generateRandomString(6),
      isActive = true
    );
  }

  public static Product2 buildNonSerializedProduct(String recordTypeName,
                                                   String family )
  {
    buildGlAccounts();
    Id rt = LGND_Utilities.recordTypeIdFromName('Product2', recordTypeName );
    return new Product2(
      name = 'InventoryTest' + recordTypeName + Crypto.getRandomLong(),
      recordTypeId = rt,
      Family = family,
      AcctSeedERP__Serialized__c = false,
      GMBLASERP__Lot_Tracked__c = false,
      Can_be_Nest__c = false,
      Can_be_Nested__c = true,
      AcctSeed__Inventory_Product__c = true,
      AcctSeed__Inventory_Type__c = 'Purchased',
      AcctSeed__Accounting_Type__c = 'Taxable_Product',
      AcctSeed__Expense_GL_Account__c = expenseAccount.Id,
      AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id,
      AcctSeed__Revenue_GL_Account__c = revenueAccount.Id,
      AcctSeed__Unit_Cost__c = 100.00,
      Unique_Product_Code__c = 'pcode-' + LGND_Utilities.generateRandomString(6),
      isActive = true
    );
  }

  public static Product2[] createNonSerializedProducts( String recordTypeName,
                                                        String family,
                                                        Integer count )
  {
    Product2[] prods = buildNonSerializedProducts( recordTypeName, family, count);
    insert prods;
    return prods;
  }

  public static Product2[] buildNonSerializedProducts( String recordTypeName,
                                                       String family,
                                                       Integer count )
  {
    Product2[] products = new List<Product2>();
    for( Integer i=0; i<count; i++ )
    {
      products.add( buildNonSerializedProduct( recordTypeName, family ) );
    }
    return products;
  }

  public static Product2 createSavingsProduct()
  {
    buildGlAccounts();
    Id rt = LGND_Utilities.recordTypeIdFromName('Product2', 'Part' );
    Product2 savings = new Product2(
      Name = 'Savings',
      Unique_Product_Code__c = 'Savings',
      Family = 'Discount',
      RecordTypeId = rt,
      AcctSeed__Inventory_Product__c = false,
      AcctSeed__Expense_GL_Account__c = expenseAccount.Id,
      AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id,
      AcctSeed__Revenue_GL_Account__c = revenueAccount.Id,
      AcctSeed__Inventory_Type__c = null,
      AcctSeedERP__Serialized__c = false,
      GMBLASERP__Lot_Tracked__c = false
    );
    insert savings;
    return savings;
  }

  public static Product2 createPPSA( Id pbId )
  {
    buildGlAccounts();
    Product2 ppsa;
    try {
      ppsa = [
        SELECT Id, Name, Family, RecordTypeId, RecordType.Name
        FROM Product2
        WHERE Id = :LGND_Constants.ppsaProductId ];
    }
    catch( Exception e )
    {
      ppsa = new Product2(
        RecordTypeId = LGND_Utilities.recordTypeIdFromName('Product2', 'Fees'),
        Name = 'PPSA Fee',
        Family = 'Bank Registration PPSA Fee',
        IsActive = true
      );
    }
    ppsa.AcctSeed__Revenue_GL_Account__c = revenueAccount.Id;
    ppsa.AcctSeed__Expense_GL_Account__c = expenseAccount.Id;
    ppsa.AcctSeed__Inventory_Product__c = false;
    ppsa.AcctSeed__Inventory_Type__c = null;
    ppsa.Unique_Product_Code__c = 'ppsa-' + LGND_Utilities.generateRandomString(6);
    ppsa.AcctSeed__Unit_Cost__c = 0;
    ppsa.AcctSeedERP__Serialized__c = false;
    ppsa.GMBLASERP__Lot_Tracked__c = false;
    //Boolean orig = gcProduct.disableTrigger;
    //gcProduct.disableTrigger = true;
    upsert ppsa;
    //gcProduct.disableTrigger = orig;
    Factory_PricebookEntry.createStandardEntries( new Set<Id>{ppsa.Id}, 0 );
    insert Factory_PricebookEntry.buildEntry( ppsa.Id, pbId, 0 );
    return ppsa;
  }

  public static Product2 buildInsuranceProduct( String family,
                                                String name,
                                                Id insurancePlanId,
                                                Boolean isResidual )
  {
    return new Product2(
      RecordTypeId = LGND_Utilities.recordTypeIdFromName('Product2', 'Insurance'),
      Name = name,
      Family = family,
      IsActive = true,
      InsurancePlan__c = insurancePlanId,
      Is_Residual_Insurance__c = isResidual,
      AcctSeed__Revenue_GL_Account__c = null,
      AcctSeed__Expense_GL_Account__c = null,
      AcctSeed__Inventory_Product__c = false,
      AcctSeed__Inventory_Type__c = null,
      Unique_Product_Code__c = 'name-' + LGND_Utilities.generateRandomString(6),
      AcctSeed__Unit_Cost__c = 0,
      AcctSeedERP__Serialized__c = false,
      GMBLASERP__Lot_Tracked__c = false
    );
  }

  public static Product2 createInsuranceProduct( String family,
                                                 String name,
                                                 Id insurancePlanId,
                                                 Boolean isResidual,
                                                 Id pbId )
  {
    Product2 p = buildInsuranceProduct( family, name, insurancePlanId, isResidual );
    //Boolean orig = gcProduct.disableTrigger;
    //gcProduct.disableTrigger = true;
    insert p;
    //gcProduct.disableTrigger = orig;
    Factory_PricebookEntry.createStandardEntries( new Set<Id>{p.Id}, 0 );
    insert Factory_PricebookEntry.buildEntry( p.Id, pbId, 0 );
    return p;
  }

}