@isTest
private class CPQ_Controller_dh_Test {

  static Quote quot;
  static Opportunity opp;
  static AcctSeed__Accounting_Variable__c ontarioTaxZone;
  static Account dealer;
  static User partner;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Id retailPbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    Account cust = Factory_Account.insertCustomerAccounts(1)[0];
    Opportunity opp = Factory_Opportunity.insertOpportunity( cust, retailPbId );
    Account dealer = Factory_Account.insertDealerAccounts( 1 )[0];
    Factory_User.createPartnerUser( dealer );
  }

  public static void initDealerAndPartnerUser()
  {
    dealer = [SELECT Id, Name, RecordTypeId, Type
              FROM Account
              WHERE RecordType.Name = 'Dealer'
              AND Is_Internal__c = false
              LIMIT 1];
    partner = [SELECT Id, Name
               FROM User
               WHERE AccountId = :dealer.Id
               LIMIT 1];
  }

  private static void init( Boolean createQuote )
  {
    opp = [ SELECT Id,
                   Name,
                   AccountId,
                   Pricebook2Id,
                   StageName,
                   CloseDate
            FROM Opportunity
            LIMIT 1];
    if( createQuote )
    {
      quot = Factory_Quote.insertQuoteForBoat( opp );
    }
    ontarioTaxZone = [ SELECT Id,
                              Name,
                              Tax_is_Harmonized__c,
                              Tax_Rate_Provincial_Statutory__c,
                              Tax_Rate_Retail__c
                       FROM AcctSeed__Accounting_Variable__c
                       WHERE AcctSeed__Type__c = 'GL Account Variable 3'
                       AND Name = 'Ontario'
                       LIMIT 1];
  }

  @isTest
  static void initCPQ_default_Test()
  {
    String cpqJSON = CPQ_Controller_dh.initCPQ( null, null );
    CPQ cpq = (CPQ)Json.deserialize( cpqJSON, CPQ.class );
    System.assertEquals( 0, cpq.deposit );
    System.assertEquals( 120, cpq.amort );
    System.assertEquals( 60, cpq.term );
    System.assertEquals( 6.99, cpq.interestRate );
    System.assertEquals( 'retail', cpq.saleType );
    System.assertEquals( 'Ontario', cpq.saleProvince );
  }

  @isTest
  static void initCPQ_partnerUser_Test()
  {
    initDealerAndPartnerUser();
    dealer.BillingCountry = 'Canada';
    dealer.billingState = 'Alberta';
    update dealer;
    System.runAs( partner )
    {
      String cpqJSON = CPQ_Controller_dh.initCPQ( null, null );
      CPQ cpq = (CPQ)Json.deserialize( cpqJSON, CPQ.class );
      System.assertEquals( 'Alberta', cpq.saleProvince );
    }
  }

  @isTest
  static void initCPQ_partnerUser_Fail_Test()
  {
    initDealerAndPartnerUser();
    System.runAs( partner )
    {
      try {
        String cpqJSON = CPQ_Controller_dh.initCPQ( null, null );
      }
      catch( Exception ex )
      {
        System.assertEquals( ex.getMessage(),
                             'Current user\'s Account does not have the address set correctly. \b\r Please Add all address information' );
      }
    }
  }

  @isTest
  static void initCPQ_withQuote_Test()
  {
    init(true);
    quot.Finance_Ammortization__c = 180;
    quot.Finance_Term__c = 180;
    quot.Finance_Annual_Interest__c = 2;
    quot.Deposit__c = 1000;
    update quot;
    String cpqJSON = CPQ_Controller_dh.initCPQ( String.valueOf(quot.Id), String.valueOf(opp.Id) );
    CPQ cpq = (CPQ)Json.deserialize( cpqJSON, CPQ.class );

    System.assertEquals( 180, cpq.term );
    System.assertEquals( 180, cpq.amort );
    System.assertEquals( 1000, cpq.deposit );
    System.assertEquals( 2, cpq.interestRate );
    System.assertNotEquals( null, cpq.boatId );
    System.assertNotEquals( null, cpq.motorId );
    System.assertNotEquals( null, cpq.trailerId );
    System.assertNotEquals( null, cpq.trollingMotorId );
    System.assertEquals( 5, cpq.saleItems.size() );
  }

  @isTest
  static void upsertQuote_FromQuote_Test()
  {
    init( true );
    Date today = Date.today();
    DateTime dt = DateTime.newInstance( today.year(),
                                        today.month(),
                                        today.day() );
    CPQ_Lib_dh.TaxZone taxZone = new CPQ_Lib_dh.TaxZone( ontarioTaxZone );
    String resultId = CPQ_Controller_dh.upsertQuote( quot.Id,
                                                     'ThisName',
                                                     dt.format( 'yyyy-MM-dd'),
                                                     JSON.serialize(taxZone) );
    Quote result = [SELECT Id, ExpirationDate, Name FROM Quote WHERE Id = :resultId];
    System.assertEquals( 'ThisName', result.Name );
    System.assertEquals( today, result.expirationDate );
  }

  @isTest
  static void upsertQuote_FromOpp_Test()
  {
    init( false );
    Date today = Date.today();
    DateTime dt = DateTime.newInstance( today.year(),
                                        today.month(),
                                        today.day() );
    CPQ_Lib_dh.TaxZone taxZone = new CPQ_Lib_dh.TaxZone( ontarioTaxZone );
    String resultId = CPQ_Controller_dh.upsertQuote( opp.Id,
                                                    'ThisName',
                                                    dt.format( 'yyyy-MM-dd'),
                                                    JSON.serialize(taxZone) );
    Quote result = [SELECT Id, ExpirationDate, Name, IsSyncing FROM Quote WHERE Id = :resultId];
    System.assertEquals( 'ThisName', result.Name );
    System.assertEquals( today, result.expirationDate );
    System.assertEquals( true, result.IsSyncing );
  }

  @isTest
  static void upsertQuote_Fail_Test()
  {
    Account cust = Factory_Account.insertCustomerAccounts(1)[0];
    init( false );
    try
    {
      Date today = Date.today();
      DateTime dt = DateTime.newInstance( today.year(),
                                        today.month(),
                                        today.day() );
      CPQ_Lib_dh.TaxZone taxZone = new CPQ_Lib_dh.TaxZone( ontarioTaxZone );
      String resultId = CPQ_Controller_dh.upsertQuote( cust.Id,
                                                       'ThisName',
                                                       dt.format( 'yyyy-MM-dd'),
                                                       JSON.serialize(taxZone) );
    }
    catch( Exception ex )
    {
      System.assertEquals( ex.getMessage(), 'Unsupported record Id provided' );
    }
  }

  @isTest
  static void saveCPQ_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    System.runAs( cpqFact.partnerUser )
    {
      CPQ theCpq = cpqFact.buildCPQ('retail');
      String oppId = CPQ_Controller_dh.saveCPQ( JSON.serialize( theCPQ ) );
      OpportunityLineItem[] olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :oppId];
      System.assert( olis.size() > 0 );
    }
  }

  @isTest
  static void saveCPQ_failInvalidId_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    System.runAs( cpqFact.partnerUser )
    {
      CPQ theCpq = cpqFact.buildCPQ('retail');
      theCpq.saveToRecordId = cpqFact.partnerUser.Id;
      try{
        CPQ_Controller_dh.saveCPQ( JSON.serialize( theCPQ ) );
      }
      catch( Exception e )
      {
        System.assertEquals( 'Invalid Id Supplied! CPQ can only be saved to an Opportunity OR Quote',
                             e.getMessage() );
      }
    }
  }

  @isTest
  static void saveCPQ_failNoId_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    System.runAs( cpqFact.partnerUser )
    {
      CPQ theCpq = cpqFact.buildCPQ('retail');
      theCpq.saveToRecordId = null;
      try{
        CPQ_Controller_dh.saveCPQ( JSON.serialize( theCPQ ) );
      }
      catch( Exception e )
      {
        System.assertEquals( 'Save RecordId did not resolve to an actual sObject Type',
                             e.getMessage() );
      }
    }
  }

  @isTest
  static void fetchMajorProductSelectOption_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    Factory_CPQ.setupMajorProducts( 10 );
    Id pbId = Factory_CPQ.defaultPricebooks.get('retail');
    System.runAs( cpqFact.partnerUser )
    {
      Test.startTest();
      String resultJSON = CPQ_Controller_dh.fetchMajorProductOptions( 'Motor',
                                                                      'Remote',
                                                                      pbId );
      List<Map<String, String>> result = (List<Map<String, String>>)JSON.deserialize( resultJSON, List<Map<String, String>>.class );
      Test.stopTest();
      System.assertEquals( 10, result.size() );
    }
  }

  @isTest
  static void fetchBoatDetails_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    System.runAs( cpqFact.partnerUser )
    {
      CPQ theCPQ = new CPQ('retail');
      theCPQ.boatId = cpqFact.boat.Id;
      String cpqJSON = CPQ_Controller_dh.fetchBoatDetails( JSON.serialize( theCPQ ) );
      theCPQ = (CPQ)JSON.deserialize( cpqJSON, CPQ.class );
      System.assertEquals( theCPQ.theBoat.name, cpqFact.boat.Name );
      System.assert( theCPQ.baseProductOptions.size() > 0 );
    }
  }

  @isTest
  static void fetchNewSavings_Test()
  {
    String savingsJSON = CPQ_Controller_dh.fetchNewSavings();
    CPQ_Lib_dh.SavingsLine saving = (CPQ_Lib_dh.SavingsLine)JSON.deserialize( savingsJSON, CPQ_Lib_dh.SavingsLine.class );
    System.assertEquals( 18, saving.id.length() );
    System.assertEquals( Utility_Products__c.getOrgDefaults().Savings__c, saving.productId );
  }

  @isTest
  static void fetchNewCustomProduct_Test()
  {
    String cpJSON = CPQ_Controller_dh.fetchNewCustomProduct();
    CPQ_Lib_dh.CustomProduct cp = (CPQ_Lib_dh.CustomProduct)JSON.deserialize( cpJSON, CPQ_Lib_dh.CustomProduct.class );
    System.assertEquals( 18, cp.id.length() );
    System.assertEquals( Utility_Products__c.getOrgDefaults().Partner_Custom_Product__c, cp.productId );
  }

  @isTest
  static void initUpgradeSelector_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    System.runAs( cpqFact.partnerUser )
    {
      CPQ theCpq = cpqFact.buildCPQ('retail');
      String upgradesJSON = CPQ_Controller_dh.initUpgradeSelector( JSON.serialize( theCpq ), 'Motor' );
      List<CPQ_Lib_dh.UpgradeProduct> upgrades =
        (List<CPQ_Lib_dh.UpgradeProduct>)JSON.deserialize( upgradesJSON,
                                                           List<CPQ_Lib_dh.UpgradeProduct>.class );
      System.assertEquals( 10, upgrades.size() );
    }
  }

  @isTest
  static void setSelectedUpgrade_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    Id pbId = Factory_CPQ.defaultPricebooks.get('retail');
    System.runAs( cpqFact.partnerUser )
    {
      CPQ theCpq = cpqFact.buildCPQ('retail');
      String resultJSON = CPQ_Controller_dh.setSelectedUpgrade(
        String.valueOf( cpqFact.boat.Standard_Motor__c ),
        String.valueOf( cpqFact.boat.Standard_Motor__c ),
        String.valueOf( pbId ),
        'Ontario'
      );
      CPQ_Lib_dh.UpgradeProduct result =
        (CPQ_Lib_dh.UpgradeProduct)JSON.deserialize( resultJSON, CPQ_Lib_dh.UpgradeProduct.class );
    }
  }

  @isTest
  static void fetchOptions_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    Id pbId = Factory_CPQ.defaultPricebooks.get('retail');
    System.runAs( cpqFact.partnerUser )
    {
      String resultJSON = CPQ_Controller_dh.fetchOptions( cpqFact.boat.Id, pbId );
      List<CPQ_Lib_dh.OptionsWrapper> result =
        (List<CPQ_Lib_dh.OptionsWrapper>)JSON.deserialize( resultJSON,
                                                           List<CPQ_Lib_dh.OptionsWrapper>.class );
      //values from BoatTestFactory
      System.assertEquals( 5, result.size() );
      System.assertEquals( 3, result[0].items.size() );
    }
  }

  @isTest
  static void fetchSubOptions1_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    Id pbId = Factory_CPQ.defaultPricebooks.get('retail');
    System.runAs( cpqFact.partnerUser )
    {
      Product_Option__c po = [SELECT Id, To_Product__c, From_Product__c
                              FROM Product_Option__c
                              WHERE To_Product__c = :cpqFact.boat.Id
                              LIMIT 1];
      Product_Option__c[] subOptions = [SELECT Id
                                       FROM Product_Option__c
                                       WHERE To_Product__c = :po.From_Product__c
                                       AND From_Product__r.RecordType.Name = 'Part' ];
      String resultJSON = CPQ_Controller_dh.fetchSubOptions1( po.From_Product__c, pbId );
      List<CPQ_Lib_dh.SubOptionProduct> result =
        (List<CPQ_Lib_dh.SubOptionProduct>)JSON.deserialize( resultJSON,
                                                             List<CPQ_Lib_dh.SubOptionProduct>.class );
      // values from BoatTestFactory
      System.debug( result );
      System.assertEquals( subOptions.size() , result.size() );
    }
  }

	@isTest
  static void fetchSubOptions_Test()
  {
    Test.startTest();
    Product2 parent = Factory_Product.buildNonSerializedProduct('Part', 'Electronics');
    Product2[] children = Factory_Product.buildNonSerializedProducts('Part', 'Electronics', 5);
    Product2[] allPs = new List<Product2>();
    allPs.add( parent );
    allPs.addAll( children );
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert allPs;
    gcProduct.disableTrigger = orig;
    Factory_ProductOption.createProductOptions( parent.Id, children, 0, 1 );
    Factory_PricebookEntry.createStandardEntries( allPs, 100 );
    String jsonResult = CPQ_Controller_dh.fetchSubOptions( parent.Id,
                                                           Test.getStandardPricebookId() );
    List<CPQ_Lib_dh.OptionWrapper> result =
      (List<CPQ_Lib_dh.OptionWrapper>)JSON.deserialize( jsonResult, List<CPQ_Lib_dh.OptionWrapper>.class );
    Test.stopTest();

    System.assertEquals( 5, result.size() );
  }
}