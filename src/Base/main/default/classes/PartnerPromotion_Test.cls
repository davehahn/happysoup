/**
 * Created by dave on 2019-09-12.
 */

@IsTest
private class PartnerPromotion_Test {

  static Account partner;
  static User partnerUser;
  static Dealer_Order__c dealerOrder;
  static List<AcctSeed__Project__c> erps;
  static List<AcctSeed__Project__c> all_erps;
  static Product2 boat;

  @testSetup static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Product2 b = Factory_Product.buildSerializedProduct('Boat', 'Utility');
    b.Stack_Size__c = 3;
    insert b;
    Factory_PricebookEntry.createAllDefaultEntriesEntries( b.Id, 10000 );
    Account p = Factory_Account.insertDealerAccounts(1)[0];
    Factory_ERPOrder.createPartnerBoatSales( p, new List<Product2>{b}, 12, 10000 );
  }

  private static void setup()
  {
    partner = [SELECT Id, Name FROM Account WHERE RecordType.Name = 'Dealer' AND Name LIKE '%Dealer%' LIMIT 1];
    partnerUser = Factory_User.createPartnerUser( partner );
    all_erps =  [SELECT Id FROM AcctSeed__Project__c WHERE AcctSeed__Account__c = :partner.Id ];
    for( AcctSeed__Project__c erp : all_erps )
    {
      erp.OwnerId = partnerUser.Id;
    }
    Boolean o = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    update all_erps;
    gcProject.disableTrigger = o;
  }

  private static void init( Integer erpCount )
  {
    dealerOrder = Factory_DealerOrder.createDealerOrder( partner );
    boat = [ SELECT Id FROM Product2 WHERE RecordType.Name = 'Boat' AND Family = 'Utility' LIMIT 1];
    erps = new List<AcctSeed__Project__c>();
    for( Integer i=0; i<erpCount; i++ )
    {
      erps.add( all_erps[i] );
    }
    Factory_DealerOrder.createDealerOrderLines( erps, dealerOrder, boat );
  }

  @IsTest
  static void SevenForSevenInit_Even_Test()
  {
    setup();
    System.runAs( partnerUser )
    {
      init(12 );
      Test.startTest();
      PartnerPromotion.Seven4Seven_Promo promo = new PartnerPromotion.Seven4Seven_Promo( dealerOrder.Id );
      Test.stopTest();
      System.assertEquals( true, promo.isApplicable );
      System.assertEquals( 1, promo.stacks.size() );
      System.assertEquals( 4, promo.stacks.get( boat.Id ).completeStacks );
      System.assertEquals( 0, promo.stacks.get( boat.Id ).incompleteCount );
      System.assert( promo.stacks.get( boat.Id ).toGetPromotionMessage == null );
      System.assertEquals( erps.size(), promo.stacks.get( boat.Id ).erpWrappers.size() );
      System.assert( promo.resultMessage.success == null );
    }
  }

  @IsTest
  static void SevenForSevenInit_Odd_Test()
  {
    setup();
    System.runAs( partnerUser )
    {
      init(11);
      Test.startTest();
      PartnerPromotion.Seven4Seven_Promo promo = new PartnerPromotion.Seven4Seven_Promo( dealerOrder.Id );
      Test.stopTest();
      System.assertEquals( true, promo.isApplicable );
      System.assertEquals( 1, promo.stacks.size() );
      System.assertEquals( 3, promo.stacks.get( boat.Id ).completeStacks );
      System.assertEquals( 2, promo.stacks.get( boat.Id ).incompleteCount );
      System.assert( promo.stacks.get( boat.Id ).toGetPromotionMessage != null );
      System.assertEquals( erps.size(), promo.stacks.get( boat.Id ).erpWrappers.size() );
      System.assert( promo.resultMessage.success == null );
    }
  }

  @IsTest
  static void SevenForSevenApply_Test()
  {
    setup();
    System.runAs( partnerUser )
    {
      init(12);
      Test.startTest();
      PartnerPromotion.Seven4Seven_Promo promo = new PartnerPromotion.Seven4Seven_Promo( dealerOrder.Id );
      promo.apply();
      Test.stopTest();
      List<AcctSeedERP__Material__c> mats = [SELECT Id,
                                                    AcctSeedERP__Comment__c,
                                                    GMBLASERP__Unit_Price__c
                                              FROM AcctSeedERP__Material__c
                                              WHERE AcctSeedERP__Project__c = :erps[0].Id
                                              AND AcctSeedERP__Product__c <> :boat.Id ];
      System.assert( promo.resultMessage.success != null );
      System.assertEquals( 1, mats.size() );
      System.assert( promo.stacks.get( boat.Id ).toGetPromotionMessage == null );
      System.assertEquals( PartnerPromotion.sevenForSevenDiscountName, mats[0].AcctSeedERP__Comment__c );
      System.assertEquals( -1*((10000 - (10000*0.02)) * 0.07), mats[0].GMBLASERP__Unit_Price__c );
    }
  }
}