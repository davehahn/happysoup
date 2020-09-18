/**
 * Created by dave on 2020-08-12.
 */
@IsTest
private class PartnerProgramItem_T
{

  static String partnerAccountName = 'TestPartner';
  static Account partner;
  static User partnerUser;
  static Product2 boat;
  static PricebookEntry pbe;
  static Dealer_Order__c order;
  static List<AcctSeed__Project__c> erps;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    insert new Partner_Program_Settings__c(
      Coop_Discount_Percent__c = 2,
      Kickstart_Booking_Order_Discount_Percent__c = 2,
      Available_Model_Years__c = '2020,2021',
      Available_Program_Years__c = '2021'
    );
    Account partner = Factory_Account.buildDealerAccounts(1)[0];
    partner.Name = partnerAccountName;
    partner.BillingState = 'Ontario';
    insert partner;
    Factory_User.createPartnerUser( partner );
  }

  private static void findPartner()
  {
    Id rtId = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer');
    partner = [SELECT Id, Name, BillingState FROM Account WHERE Name = :partnerAccountName AND RecordTypeId = :rtId];
  }

  private static void buildBoat( String family, Decimal cost, Integer stackSize )
  {
    Id fpbId = LGND_Constants.factoryPricebookId;
    boat = Factory_Product.buildSerializedProduct('Boat', family );
    boat.Stack_Size__c = stackSize;
    insert boat;
    Factory_PricebookEntry.insertStandardEntries( new List<Product2>{boat}, cost );
    pbe = Factory_PricebookEntry.buildEntry( boat.Id, fpbId, cost );
    insert pbe;
  }

  private static void init( String family, Decimal cost, Integer stackSize )
  {
    findPartner();
    partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
    buildBoat(family, cost, stackSize);
  }

  private static void createDealerOrder( Integer quantity )
  {
    order = Factory_DealerOrder.createDealerOrder(partner);
    order.Is_Booking_Order__c = true;
    update order;
    order = [
      SELECT
        Id,
        CreatedDate,
        Is_Booking_Order__c,
        Program_Year__c,
        Account__c,
        Account__r.Is_Internal__c,
        Payment_Method__c,
        Applied_Partner_Program_Discounts__c
      FROM Dealer_Order__c
      WHERE Id = :order.Id ];
    erps = Factory_ERPOrder.createPartnerBoatSales(partner, new List<PricebookEntry>{ pbe }, quantity);
    Factory_DealerOrder.createDealerOrderLines(erps, order, boat);
    Set<Id> erpIds = LGND_Utilities.getIdSetFromList( (List<sObject>)erps );
    erps = [
      SELECT
        Id,
        Name,
      ( SELECT Id
        FROM AcctSeed__Project_Tasks__r ),
      ( SELECT Id,
        AcctSeedERP__Project__c,
        AcctSeedERP__Project_Task__c,
        GMBLASERP__Unit_Price__c,
        AcctSeedERP__Comment__c,
        Applied_Partner_Program_Discount__c,
        AcctSeedERP__Product__c,
        AcctSeedERP__Product__r.Id,
        AcctSeedERP__Product__r.Stack_Size__c,
        AcctSeedERP__Product__r.Name,
        AcctSeedERP__Product__r.RecordTypeId,
        AcctSeedERP__Product__r.Family,
        AcctSeedERP__Product__r.AcctSeedERP__Serialized__c
      FROM AcctSeedERP__Project_Materials__r )
      FROM AcctSeed__Project__c
      WHERE Id IN :erpIds
    ];
  }

  private static Decimal determineCashDiscount()
  {
    if( order.createdDate.month() >= 8 )
    {
      if( order.createdDate.month() == 12 &&
          order.createdDate.day() > 18 )
      {
        return 1;
      }
      return 3;
    }
    return 1;
  }

  @IsTest
  static void PartnerProgram_Volume_NotApplicable_Test()
  {
    init('Full Windshield', 50000, null);

    System.runAs( partnerUser )
    {
      createDealerOrder( 2 );
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      PartnerProgram_Volume program = new PartnerProgram_Volume();
      program.init( orderWrapper );

      System.assert( !program.isApplicable(), 'PartnerProgram_Volume should NOT be applicable');

    }
  }

  @IsTest
  static void PartnerProgram_Volume_Applicable_Test()
  {
    init('Full Windshield', 50000, null);

    System.runAs( partnerUser )
    {
      createDealerOrder( 4 );
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      PartnerProgram_Volume program = new PartnerProgram_Volume();
      program.init( orderWrapper );

      System.assert( program.isApplicable(), 'PartnerProgram_Volume should be applicable');
      System.assert( !program.wasAppliedPreviously(), 'PartnerProgram_Volume should Not have been applied previously');
      System.assertEquals( 1, program.getDiscountPercent(), 'Volume discount should be 1%' );

      Decimal totalSavings = 4 * ( 50000 * 0.01 );
      List<AcctSeedERP__Material__c> discounts = program.apply();
      PartnerProgram_Service.ResultMessage result = program.getResult();

      System.assertEquals( 4, discounts.size() );
      System.assertEquals( totalSavings, result.totalSaving );
    }
  }

  @IsTest
  static void PartnerProgram_PontoonVolume_Applicable_Test()
  {
    init('Pontoon', 50000, null);

    System.runAs( partnerUser )
    {
      createDealerOrder( 4 );
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      PartnerProgram_PontoonVol program = new PartnerProgram_PontoonVol();
      program.init( orderWrapper );

      System.assert( program.isApplicable(), 'PartnerProgram_PontoonVol should be applicable');
      System.assert( !program.wasAppliedPreviously(), 'PartnerProgram_PontoonVol should Not have been applied previously');
      System.assertEquals( 1, program.getDiscountPercent(), 'Pontoon Volume discount should be 1%' );

      Decimal totalSavings = 4 * ( 50000 * 0.01 );
      List<AcctSeedERP__Material__c> discounts = program.apply();
      PartnerProgram_Service.ResultMessage result = program.getResult();

      System.assertEquals( 4, discounts.size() );
      System.assertEquals( totalSavings, result.totalSaving );
    }
  }

  @IsTest
  static void PartnerProgram_Coop_Test()
  {
    init('Pontoon', 50000, null);

    System.runAs( partnerUser )
    {
      createDealerOrder( 1 );
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      PartnerProgram_Coop program = new PartnerProgram_Coop();
      program.init( orderWrapper );

      System.assert( program.isApplicable(), 'PartnerProgram_Coop should be applicable');
      System.assert( !program.wasAppliedPreviously(), 'PartnerProgram_Coop should Not have been applied previously');
      System.assertEquals( 2, program.getDiscountPercent(), 'Coop discount should be 2%' );

      Decimal totalSavings = 1 * ( 50000 * 0.02 );
      List<AcctSeedERP__Material__c> discounts = program.apply();
      PartnerProgram_Service.ResultMessage result = program.getResult();

      System.assertEquals( 1, discounts.size() );
      System.assertEquals( totalSavings, result.totalSaving );
    }
  }

  @IsTest
  static void PartnerProgram_KickStartBooking_Test()
  {
    init('Pontoon', 50000, null);

    System.runAs( partnerUser )
    {
      createDealerOrder( 1 );
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      PartnerProgram_Kickstart_Booking program = new PartnerProgram_Kickstart_Booking();
      program.init( orderWrapper );

      System.assert( program.isApplicable(), 'PartnerProgram_KickStart_Booking should be applicable');
      System.assert( !program.wasAppliedPreviously(), 'PartnerProgram_KickStart_Booking should Not have been applied previously');
      System.assertEquals( 2, program.getDiscountPercent(), 'KickStart Booking discount should be 2%' );

      Decimal totalSavings = 1 * ( 50000 * 0.02 );
      List<AcctSeedERP__Material__c> discounts = program.apply();
      PartnerProgram_Service.ResultMessage result = program.getResult();

      System.assertEquals( 1, discounts.size() );
      System.assertEquals( totalSavings, result.totalSaving );
    }
  }

  @IsTest
  static void PartnerProgram_Cash_Test()
  {
    init('Pontoon', 50000, null);

    System.runAs( partnerUser )
    {
      createDealerOrder( 1 );
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      PartnerProgram_Cash program = new PartnerProgram_Cash();
      program.init( orderWrapper );
      Decimal cashPercent = determineCashDiscount();

      System.assert( program.isApplicable(), 'PartnerProgram_Cash should be applicable');
      System.assert( !program.wasAppliedPreviously(), 'PartnerProgram_Cash should Not have been applied previously');
      System.assertEquals( cashPercent, program.getDiscountPercent(), 'Cash discount should be ' + cashPercent + '%' );

      Decimal totalSavings = 1 * ( 50000 * ( cashPercent / 100 ) );
      List<AcctSeedERP__Material__c> discounts = program.apply();
      PartnerProgram_Service.ResultMessage result = program.getResult();

      System.assertEquals( 1, discounts.size() );
      System.assertEquals( totalSavings, result.totalSaving );
      System.assertEquals( cashPercent, program.getDiscountPercent() );
    }
  }

  @IsTest
  static void PartnerProgram_SevenForSeven_Test()
  {
    init('Utility', 10000, 3);

    System.runAs( partnerUser )
    {
      createDealerOrder( 9 );
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      PartnerProgram_7for7 program = new PartnerProgram_7for7();
      program.init( orderWrapper );

      System.assert( program.isApplicable(), 'PartnerProgram_Cash should be applicable');
      System.assert( !program.wasAppliedPreviously(), 'PartnerProgram_Cash should Not have been applied previously');
      System.assertEquals( 7, program.getDiscountPercent(), 'Cash discount should be 7%' );

      Decimal totalSavings = 9 * ( 10000 * 0.07 );
      List<AcctSeedERP__Material__c> discounts = program.apply();
      PartnerProgram_Service.ResultMessage result = program.getResult();
      System.assertEquals( 9, discounts.size() );
      System.assertEquals( totalSavings, result.totalSaving );
      System.assertEquals( 7, program.getDiscountPercent() );
    }
  }


}