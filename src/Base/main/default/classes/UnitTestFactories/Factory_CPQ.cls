@isTest
public with sharing class Factory_CPQ {

  public User partnerUser;
  public Product2 boat;
  public Account dealerAccount;
  public Opportunity opp;
  public Quote quot;
  public CPQ theCPQ;
  public static Map<String, Id> defaultPricebooks {
    get {
      if( defaultPricebooks == null )
      {
        Legend_Settings__c lSettings = Legend_Settings__c.getOrgDefaults();
        defaultPricebooks = new Map<String, Id>{
          'partner' => lSettings.Default_Partner_Pricebook__c,
          'retail' => lSettings.Default_Retail_Pricebook__c,
          'factory' => lSettings.Default_Factory_Pricebook__c
        };
      }
      return defaultPricebooks;
    }
    set;
  }

  public Factory_CPQ()
  {
    createDealerAccountAndUser( null );
    setupBoatData();
  }

  public CPQ buildCPQ( String saleType )
  {
    initCPQ( saleType );
    createOpportunity();
    theCPQ.saveToRecordId = opp.Id;
    return theCPQ;
  }

  public CPQ buildCPQ_ForQuote( String saleType )
  {
    initCPQ( saleType );
    createOpportunity();
    createQuote();
    theCPQ.saveToRecordId = quot.Id;
    return theCPQ;
  }

  public static List<CPQ_Lib_dh.CustomProduct> createCustomProducts( Integer count )
  {
    Id custProdId = Utility_Products__c.getOrgDefaults().Partner_Custom_Product__c;
    Factory_PricebookEntry.createAllDefaultEntriesEntries( custProdId, 0 );
    List<CPQ_Lib_dh.CustomProduct> custProds = new List<CPQ_Lib_dh.CustomProduct>();
    for( Integer i=0; i<count; i++ )
    {
      CPQ_Lib_dh.CustomProduct cp = new CPQ_Lib_dh.CustomProduct();
      cp.amount = 100;
      cp.quantity = 5;
      custProds.add( cp );
    }
    return custProds;
  }

  public static List<CPQ_Lib_dh.SavingsLine> createSavingsLines( Integer count )
  {
    Id savingsId = Utility_Products__c.getOrgDefaults().Savings__c;
    Factory_PricebookEntry.createAllDefaultEntriesEntries( savingsId, 0 );
    List<CPQ_Lib_dh.SavingsLine> savings = new List<CPQ_Lib_dh.SavingsLine>();
    for( Integer i=0; i<count; i++ )
    {
      CPQ_Lib_dh.SavingsLine sl = new CPQ_Lib_dh.SavingsLine();
      sl.amount = 100;
      savings.add( sl );
    }
    return savings;
  }

  public static void setupMajorProducts( Integer count )
  {
    Product2[] prods = Factory_Product.createSerializedProducts( 'Motor',
                                                                 'Remote',
                                                                 count );
    // we have to do this since we are running as a partner
    for( Product2 p : prods )
    {
      p.Available_For_Package_And_Save__c = true;
    }
    update prods;
    Factory_PricebookEntry.createAllDefaultEntriesEntries( prods, 100 );
  }

  private void createDealerAccountAndUser( String prov )
  {
    dealerAccount = Factory_Account.insertDealerAccounts(1)[0];
    dealerAccount.BillingCountry = 'Canada';
    dealerAccount.BillingState = 'Ontario';
    update dealerAccount;
    Contact c = Factory_Contact.buildContact( dealerAccount.Id, 'CPQ_fname', 'CPQ_lname', 'testCPQ@partner.com');
    partnerUser = [SELECT Id FROM User WHERE ContactId = :c.Id];
    if( prov != null )
    {
      dealerAccount.BillingState = prov;
      update dealerAccount;
    }
  }

  private void setupBoatData()
  {
    Pricebook2[] pbs = [SELECT Id FROM Pricebook2 WHERE Id IN :defaultPricebooks.values() ];
    BoatTestFactory factory = new BoatTestFactory();
    boat = factory.insertFullTestBoats(1, pbs, 'Pontoon')[0];
  }

  private void initCPQ( String saleType )
  {
    Id pbId = defaultPricebooks.get(saleType);
    theCPQ = new CPQ( saleType );
    theCPQ.boatId = boat.Id;
    theCPQ.selectBoat();
    theCPQ.theMotor = new CPQ_Lib_dh.UpgradeProduct( boat.Standard_Motor__c ,
                                                     boat.Standard_Motor__c,
                                                     pbId,
                                                     'Ontario' );
    theCPQ.theTrailer = new CPQ_Lib_dh.UpgradeProduct( boat.Standard_Trailer__c ,
                                                       boat.Standard_Trailer__c,
                                                       pbId,
                                                       'Ontario' );
    theCPQ.theTrollingMotor = new CPQ_Lib_dh.UpgradeProduct( boat.Standard_Trolling_Motor__c ,
                                                             boat.Standard_Trolling_Motor__c,
                                                             pbId,
                                                             'Ontario' );
  }

  public void createOpportunity()
  {
    Account person = Factory_Account.insertFullPersonAccount('fName', 'lName');
    Id pbId = CPQ_Lib_dh.defaultPricebooks.get('retail');
    opp = Factory_Opportunity.insertOpportunity( person, pbId );
  }

  public void createQuote()
  {
    quot = Factory_Quote.insertQuote( opp );
  }
}