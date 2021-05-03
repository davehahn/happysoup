@isTest
private class CPQ_Test {

  static User partnerUser;
  static Product2 boat;
  static Account customer;
  static Id retailPbId;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    dataSetup_AccountContactUser();
    dataSetup_insertBoat();
  }

  private static void dataSetup_AccountContactUser()
  {
    Account a = Factory_Account.insertDealerAccounts(1)[0];
    Contact c = Factory_Contact.buildContact( a.Id, 'Pfname', 'Plname', 'test@partner.com');
  }

  private static Product2 dataSetup_insertBoat()
  {
    Pricebook2[] pbs = [SELECT Id FROM Pricebook2 WHERE Id IN :CPQ_Lib_dh.defaultPricebooks.values() ];
    BoatTestFactory factory = new BoatTestFactory();
    return factory.insertFullTestBoats(1, pbs, 'Pontoon')[0];
  }

  private static void init( String prov )
  {
    retailPbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    Account dealer = [SELECT Id
                      FROM Account
                      WHERE RecordType.Name = 'Dealer'
                      AND Is_Internal__c = false
                      LIMIT 1];
    partnerUser = [SELECT Id FROM User WHERE AccountId = :dealer.Id];
    if( prov != null )
    {
      dealer.BillingCountry = 'Canada';
      dealer.BillingState = prov;
      update dealer;
    }
  }

  private static void setupBoatData()
  {
    boat = [SELECT Id,
                   Name,
                   RecordType.Name,
                   Family,
                   Make__c,
                   Standard_Motor__c,
                   Standard_Trailer__c,
                   Standard_Trolling_Motor__c,
                   Default_Image_Thumb__c,
                   Taxable__c,
             ( SELECT Id, UnitPrice, Pricebook2Id
               FROM PricebookEntries
               WHERE Pricebook2Id IN :CPQ_Lib_dh.defaultPricebooks.values() )
            FROM Product2
            WHERE RecordType.Name = 'Boat'
            AND Family = 'Pontoon'
            LIMIT 1];
  }

  private static void createCustomer()
  {
    customer = Factory_Account.insertFullPersonAccount('fName', 'lName');
  }

  private static Opportunity createOpportunity()
  {
    createCustomer();
    return Factory_Opportunity.insertOpportunity( customer, retailPbId );
  }

	@isTest
  static void constructor_nonPartnerUser_Test()
  {
    init(null);
    CPQ c = new CPQ('retail');
    System.assertEquals( 'Ontario',  c.saleProvince );
    System.assertEquals( retailPbId, c.activePricebookId );
  }

  @isTest
  static void constructor_PartnerUser_NoAddress_Test()
  {
    init(null);
    System.runAs( partnerUser )
    {
      try {
        CPQ c = new CPQ('retail');
      }
      catch( CPQ.CPQ_Exception ex )
      {
        System.assertEquals( 'Current user\'s Account does not have the address set correctly. \b\r Please Add all address information',
                             ex.getMessage() );
      }
    }
  }

  @isTest
  static void constructor_PartnerUser_Address_Test()
  {
    init( 'Ontario' );
    System.runAs( partnerUser )
    {
      CPQ c = new CPQ('retail');
      System.assertEquals( 'Ontario',  c.saleProvince );
    }
  }

  @isTest
  static void constructor_FromOpp_Test()
  {
    init('Ontario');
    System.runAs( partnerUser )
    {
      createCustomer();
      Opportunity opp = Factory_Opportunity.insertOpportunityForBoatSale( retailPbId, customer );
      opp.Finance_Ammortization__c = 180;
      opp.Finance_Term__c = 180;
      opp.Finance_Annual_Interest__c = 2;
      opp.Deposit__c = 1000;
      update opp;
      CPQ cpq = new CPQ('retail', opp.Id);
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
  }

  @isTest
  static void constructor_FromQuote_Test()
  {
    init('Ontario');
    System.runAs( partnerUser )
    {
      Opportunity opp = createOpportunity();
      Quote q = Factory_Quote.insertQuoteForBoat( opp );
      q.Finance_Ammortization__c = 180;
      q.Finance_Term__c = 180;
      q.Finance_Annual_Interest__c = 2;
      q.Deposit__c = 1000;
      update q;
      CPQ cpq = new CPQ('retail', q.Id);
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
  }

  @isTest
  static void selectBoat_Test()
  {
    init('Ontario');
    setupBoatData();
    System.runAs( partnerUser ) {
      CPQ c = new CPQ('retail');
      c.boatId = boat.Id;
      c.selectBoat();

      System.assertEquals( c.theBoat.name, boat.Name );
      System.assert( c.baseProductOptions.size() > 0 );
    }
  }

  @isTest
  static void buildUpgrades_Motor_Test()
  {
    init('Ontario');
    setupBoatData();
    System.runAs( partnerUser ) {
      CPQ c = new CPQ('retail');
      c.boatId = boat.Id;
      c.selectBoat();
      List<CPQ_Lib_dh.UpgradeProduct> upgrades = c.buildUpgrades( 'Motor' );

      System.assertEquals( 10, upgrades.size() );
    }
  }

  @isTest
  static void buildUpgrades_Trailer_Test()
  {
    init('Ontario');
    setupBoatData();
    System.runAs( partnerUser ) {
      CPQ c = new CPQ('retail');
      c.boatId = boat.Id;
      c.selectBoat();
      List<CPQ_Lib_dh.UpgradeProduct> upgrades = c.buildUpgrades( 'Trailer' );

      System.assertEquals( 10, upgrades.size() );
    }
  }

  @isTest
  static void buildUpgrades_TrollingMotor_Test()
  {
    init('Ontario');
    setupBoatData();
    System.runAs( partnerUser ) {
      CPQ c = new CPQ('retail');
      c.boatId = boat.Id;
      c.selectBoat();
      List<CPQ_Lib_dh.UpgradeProduct> upgrades = c.buildUpgrades( 'TrollingMotor' );

      System.assertEquals( 10, upgrades.size() );
    }
  }

  @isTest
  static void save_fullBoat_ToOpp_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    System.runAs( cpqFact.partnerUser )
    {
      CPQ c = cpqFact.buildCPQ('retail');
      String oppId = c.save();
      OpportunityLineItem[] olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :oppId ];
      System.assert( olis.size() > 0 );
    }
  }

   @isTest
  static void save_fullBoat_ToQuote_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    System.runAs( cpqFact.partnerUser )
    {
      CPQ c = cpqFact.buildCPQ_ForQuote('retail');
      String qId = c.save();
      QuoteLineItem[] qlis = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :qId ];
      System.assert( qlis.size() > 0 );
    }
  }

  @isTest
  static void save_with_CustomProduct_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    System.runAs( cpqfact.partnerUser )
    {
      CPQ c = cpqFact.buildCPQ('retail');
      c.customProducts = Factory_CPQ.createCustomProducts( 5 );
      String oppId = c.save();
      OpportunityLineItem[] olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :oppId ];
      System.assert( olis.size() > 0 );
    }
  }

  @isTest
  static void save_with_Savings_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    System.runAs( cpqfact.partnerUser )
    {
      CPQ c = cpqFact.buildCPQ('retail');
      c.savings = Factory_CPQ.createSavingsLines( 5 );
      String oppId = c.save();
      OpportunityLineItem[] olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :oppId ];
      System.assert( olis.size() > 0 );
    }
  }

  @isTest
  static void saveFail_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    System.runAs( cpqFact.partnerUser )
    {
      CPQ c = cpqFact.buildCPQ('retail');
      c.saveToRecordId = cpqFact.partnerUser.Id;
      try {
        c.save();
      }
      catch( CPQ.CPQ_Exception ex ) {
        System.assertEquals( 'Invalid Id Supplied! CPQ can only be saved to an Opportunity OR Quote',
                              ex.getMessage() );
      }
    }
  }

  /* ***** STATIC METHODS ***** */

  @isTest
  static void fetchMajorProductSelectOptions_Test()
  {
    Factory_CPQ cpqFact = new Factory_CPQ();
    Factory_CPQ.setupMajorProducts( 10 );
    Id pbId = Factory_CPQ.defaultPricebooks.get('retail');
    System.runAs( cpqFact.partnerUser )
    {
      Test.startTest();
      List<Map<String, String>> result = CPQ.fetchMajorProductSelectOptions( 'Motor',
                                                                             'Remote',
                                                                             pbId,
                                                                             false );
      Test.stopTest();
      System.assertEquals( 10, result.size() );
    }
  }

  @isTest
  static void findAllFees_Test()
  {
    init( null );
    System.runAs( partnerUser )
    {
      setupBoatData();
      List<CPQ_Lib_dh.Fee> fees = CPQ.findAllFees( boat.Id, 'Ontario' );

      System.assertEquals( 12, fees.size() ); // build in Boat_Test_Factory
    }
  }

  @isTest
  static void setUpgrade_Test()
  {
    init( null );
    Id pbId = CPQ_Lib_dh.defaultPricebooks.get('retail');
    System.runAs( partnerUser )
    {
      setupBoatData();
      CPQ_Lib_dh.UpgradeProduct up = CPQ.setUpgrade( String.valueOf( boat.Standard_Motor__c ),
                                                     String.valueOf( boat.Standard_Motor__c ),
                                                     String.valueOf( pbId ),
                                                     'Ontario' );
      System.assertEquals( 0, up.retailUpgradeCost );
      System.assertEquals( 0, up.partnerUpgradeCost );
    }
  }

  @isTest
  static void fetchAllOptions_Test()
  {
    init( null );
    Id pbId = CPQ_Lib_dh.defaultPricebooks.get('retail');
    System.runAs( partnerUser )
    {
      setupBoatData();
      CPQ_Lib_dh.OptionProduct[] options = CPQ.fetchAllOptions( boat.Id, pbId );

      System.assertEquals( 15, options.size() );
    }
  }

  @isTest
  static void groupOptions_Test()
  {

  }

}