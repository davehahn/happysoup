@isTest
public with sharing class Factory_PricebookEntry {

  public static PricebookEntry createStandardEntry( Id productId, Decimal unitPrice )
  {
    PricebookEntry pbe = buildEntry( productId,
                                     Test.getStandardPricebookId(),
                                     unitPrice );
    insert pbe;
    return pbe;
  }

  public static PricebookEntry createStandardEntryInPricebook( Id productId, Id pricebookId, Decimal unitPrice )
  {
    PricebookEntry pbe = buildEntry( productId,
                                     pricebookId,
                                     unitPrice );
    insert pbe;
    return pbe;
  }

  public static void insertStandardEntries( Product2[] prods, Decimal unitPrice )
  {
    PricebookEntry[] pbes = new List<PricebookEntry>();
    for( Product2 p : prods )
    {
      pbes.add( buildEntry( p.Id,
                            Test.getStandardPricebookId(),
                            unitPrice ) );
    }
    insert pbes;
  }


  /* this creates a standard pricebook entry and
     entries for default pricebooks
  */

  public static void createAllDefaultEntriesEntries( Id prodId, Decimal cost )
  {
    createAllDefaultEntriesEntries( new List<Id>{ prodId }, cost );
  }

  public static void createAllDefaultEntriesEntries( List<Product2> prods, Decimal cost )
  {
    List<Id> prodIds = new List<Id>();
    for( Product2 p : prods )
    {
      prodIds.add( p.Id );
    }
    createAllDefaultEntriesEntries( prodIds, cost );
  }

  public static void createAllDefaultEntriesEntries( List<Id> prodIds, Decimal cost )
  {
    PricebookEntry[] std_pbes = new List<PricebookEntry>();
    PricebookEntry[] pbes = new List<PricebookEntry>();
    Set<String> default_pbIds = new Set<String>();
    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
    default_pbIds.add( settings.Default_Retail_Pricebook__c );
    default_pbIds.add( settings.Default_Partner_Pricebook__c );
    default_pbIds.add( settings.Default_Factory_Pricebook__c );
    for( Id pId : prodIds )
    {
      std_pbes.add( buildEntry( pId, Test.getStandardPricebookId(), cost ) );
      for( String pbId : default_pbIds )
      {
        pbes.add( buildEntry( pId, pbId, cost) );
      }
    }
    insert std_pbes;
    insert pbes;
  }

  public static void createStandardEntries( List<Product2> products, Decimal unitPrice )
  {
    Set<Id> pIds = LGND_Utilities.getIdSetFromList( (sObject[])products );
    createStandardEntries( pIds, unitPrice );
  }

	public static void createStandardEntries( Set<Id> productIds, Decimal unitPrice )
  {
    Id stdPb = Test.getStandardPricebookId();
    PricebookEntry[] pbes = new List<PricebookEntry>();
    for( Id pId : productIds )
    {
      pbes.add( buildEntry( pId, stdPb, unitPrice ) );
    }
    insert pbes;
  }

  public static PricebookEntry[] createEntries( Product2[] prods, Id pbId, Decimal price )
  {
    PricebookEntry[] pbes = buildEntries( prods, pbId, price );
    insert pbes;
    return pbes;
  }

  public static PricebookEntry[] buildEntries( Product2[] prods, Id pbId, Decimal price )
  {
    PricebookEntry[] pbes = new List<PricebookEntry>();
    for( Product2 p : prods )
    {
      pbes.add( buildEntry( p.Id, pbId, price) );
    }
    return pbes;
  }

  public static PricebookEntry buildEntry(Id productId, Id pricebookId, Decimal unitPrice )
  {
    return new PricebookEntry(
      Product2Id = productId,
      Pricebook2Id = pricebookId,
      UnitPrice = unitPrice,
      IsActive = true
    );
  }
}