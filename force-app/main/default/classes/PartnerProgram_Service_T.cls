/**
 * Created by dave on 2020-08-11.
 */

@IsTest
private class PartnerProgram_Service_T
{
  static String partnerAccountName = 'TestPartner';
  static PartnerProgram_7for7 pp_747 = new PartnerProgram_7for7();
  static PartnerProgram_Cash pp_cash = new PartnerProgram_Cash();
  static PartnerProgram_Coop pp_coop = new PartnerProgram_Coop();
  static PartnerProgram_Volume pp_vol = new PartnerProgram_Volume();
  static PartnerProgram_PontoonVol pp_pvol = new PartnerProgram_PontoonVol();

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account partner = Factory_Account.buildDealerAccounts(1)[0];
    partner.Name = partnerAccountName;
    partner.BillingState = 'Ontario';
    insert partner;
    Factory_User.createPartnerUser( partner );
    createBoats();
  }

  private static Account findPartner()
  {
    Id rtId = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer');
    return [SELECT Id, Name, BillingState FROM Account WHERE Name = :partnerAccountName AND RecordTypeId = :rtId];
  }

  private static Map<String, Product2> createBoats()
  {
    Id fpbId = LGND_Constants.factoryPricebookId;
    Map<String, Product2> boats = new Map<String, Product2>();
    boats.put( 'Pontoon', Factory_Product.buildSerializedProduct('Boat', 'Pontoon' ) );
    boats.put( 'FullWindshield', Factory_Product.buildSerializedProduct('Boat', 'Full WindShield' ) );
    Product2 utility = Factory_Product.buildSerializedProduct('Boat', 'utility' );
    utility.Stack_Size__c = 3;
    boats.put( 'Utility', utility );
    insert boats.values();
    Factory_PricebookEntry.insertStandardEntries( boats.values(), 1000 );
    List<PricebookEntry> pbes = new List<PricebookEntry>();
    pbes.add( Factory_PricebookEntry.buildEntry( boats.get('Utility').Id, fpbId, 10000 ) );
    pbes.add( Factory_PricebookEntry.buildEntry( boats.get('FullWindshield').Id, fpbId, 50000 ) );
    pbes.add( Factory_PricebookEntry.buildEntry( boats.get('Pontoon').Id, fpbId, 30000 ) );
    insert pbes;
    return boats;
  }

  @IsTest
  static void UtilityOnly_Test()
  {
    Account partner = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
    Id boatRtId = LGND_Constants.productRtId_Boat;
    List<Product2> boats = [SELECT Id FROM Product2 WHERE Family = 'Utility' AND RecordTypeId = :boatRtId LIMIT 1];

    System.runAs(partnerUser)
    {
      Dealer_Order__c order = Factory_DealerOrder.createDealerOrder(partner);
      List<AcctSeed__Project__c> erps =
        Factory_ERPOrder.createPartnerBoatSales(partner, boats, 9);
      List<Dealer_Order_Line__c> orderLines = new List<Dealer_Order_Line__c>();
      Factory_DealerOrder.createDealerOrderLines(erps, order, boats[0]);

      Test.startTest();
      PartnerProgram_Service service = new PartnerProgram_Service(new Set<Id>
      {
        order.Id
      });
      Map<Id, PartnerProgram_Service.Result> result = service.checkAndApply();
      Test.stopTest();

      Id savingsProdId = LGND_Constants.savingsProductId;
      Set<String> appliedDiscountNames = new Set<String>();
      List<AcctSeedERP__Material__c> mats = [
        SELECT Id, AcctSeedERP__Comment__c
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Product__c = :savingsProdId
        AND AcctSeedERP__Project__c = :erps[0].Id
      ];
      for( AcctSeedERP__Material__c m : mats )
      {
        appliedDiscountNames.add( m.AcctSeedERP__Comment__c );
      }

      System.assert( appliedDiscountNames.contains( pp_coop.getName() ) );
      System.assert( appliedDiscountNames.contains( pp_cash.getName() ) );
      System.assert( appliedDiscountNames.contains( pp_747.getName() ) );
      System.assertEquals(3, result.get(order.Id).appliedDiscountNames.size());
      System.assertEquals(3, mats.size());

    }
  }

  @IsTest
  static void Pontoon4_Test()
  {
    Account partner = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
    Id boatRtId = LGND_Constants.productRtId_Boat;
    List<Product2> boats = [ SELECT Id FROM Product2 WHERE Family = 'Pontoon' AND RecordTypeId = :boatRtId LIMIT 1];

    System.runAs( partnerUser )
    {
      Dealer_Order__c order = Factory_DealerOrder.createDealerOrder(partner);
      order.Is_Booking_Order__c = true;
      update order;
      List<AcctSeed__Project__c> erps =
      Factory_ERPOrder.createPartnerBoatSales(partner, boats, 4);
      List<Dealer_Order_Line__c> orderLines = new List<Dealer_Order_Line__c>();
      Factory_DealerOrder.createDealerOrderLines(erps, order, boats[0]);

      Test.startTest();
      PartnerProgram_Service service = new PartnerProgram_Service( new Set<Id>{order.Id} );
      Map<Id, PartnerProgram_Service.Result> result = service.checkAndApply();
      Test.stopTest();

      Id savingsProdId = LGND_Constants.savingsProductId;
      Map<String, Decimal> appliedDiscounts = new Map<String, Decimal>();
      List<AcctSeedERP__Material__c> mats = [
        SELECT Id, AcctSeedERP__Comment__c
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Product__c = :savingsProdId
        AND AcctSeedERP__Project__c = : erps[0].Id
      ];
      for( Map<String, Object> disc : result.get(order.Id).appliedDiscounts )
      {
        appliedDiscounts.put( (String)disc.get('name'), (Decimal)disc.get('percentage') );
      }

      System.assert( appliedDiscounts.keySet().contains( pp_coop.getName() ) );
      System.assert( appliedDiscounts.keySet().contains( pp_cash.getName() ) );
      System.assert( appliedDiscounts.keySet().contains( pp_pvol.getName() ) );
      System.assertEquals( 1, appliedDiscounts.get( pp_pvol.getName() ) );
      System.assertEquals( 3, result.get(order.Id).appliedDiscountNames.size() );
      System.assertEquals( 3, mats.size() );


    }
  }

  @IsTest
  static void Pontoon12_Test()
  {
    Account partner = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
    Id boatRtId = LGND_Constants.productRtId_Boat;
    List<Product2> boats = [ SELECT Id FROM Product2 WHERE Family = 'Pontoon' AND RecordTypeId = :boatRtId LIMIT 1];

    System.runAs( partnerUser )
    {
      Dealer_Order__c order = Factory_DealerOrder.createDealerOrder(partner);
      order.Is_Booking_Order__c = true;
      update order;
      List<AcctSeed__Project__c> erps =
        Factory_ERPOrder.createPartnerBoatSales(partner, boats, 12);
      List<Dealer_Order_Line__c> orderLines = new List<Dealer_Order_Line__c>();
      Factory_DealerOrder.createDealerOrderLines(erps, order, boats[0]);

      Test.startTest();
      PartnerProgram_Service service = new PartnerProgram_Service( new Set<Id>{order.Id} );
      Map<Id, PartnerProgram_Service.Result> result = service.checkAndApply();
      Test.stopTest();

      Id savingsProdId = LGND_Constants.savingsProductId;
      Map<String, Decimal> appliedDiscounts = new Map<String, Decimal>();
      List<AcctSeedERP__Material__c> mats = [
        SELECT Id, AcctSeedERP__Comment__c
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Product__c = :savingsProdId
        AND AcctSeedERP__Project__c = : erps[0].Id
      ];
      for( Map<String, Object> disc : result.get(order.Id).appliedDiscounts )
      {
        appliedDiscounts.put( (String)disc.get('name'), (Decimal)disc.get('percentage') );
      }

      System.assert( appliedDiscounts.keySet().contains( pp_coop.getName() ) );
      System.assert( appliedDiscounts.keySet().contains( pp_cash.getName() ) );
      System.assert( appliedDiscounts.keySet().contains( pp_pvol.getName() ) );
      System.assertEquals( 4, appliedDiscounts.get( pp_pvol.getName() ) );
      System.assertEquals( 3, result.get(order.Id).appliedDiscountNames.size() );
      System.assertEquals( 3, mats.size() );


    }
  }

  @IsTest
  static void Vhull_Test()
  {
    Account partner = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
    Id boatRtId = LGND_Constants.productRtId_Boat;
    Product2 boat = [ SELECT Id FROM Product2 WHERE Family = 'Full Windshield' AND RecordTypeId = :boatRtId LIMIT 1];
    List<PricebookEntry> pbes = [
      SELECT
        Id,
        Product2Id,
        UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :boat.Id
      AND Pricebook2Id = :LGND_Constants.factoryPricebookId ];
    System.runAs( partnerUser )
    {
      Dealer_Order__c order = Factory_DealerOrder.createDealerOrder(partner);
      order.Is_Booking_Order__c = true;
      update order;
      List<AcctSeed__Project__c> erps =
        Factory_ERPOrder.createPartnerBoatSales(partner, pbes, 4);
      //List<Dealer_Order_Line__c> orderLines = new List<Dealer_Order_Line__c>();
      Factory_DealerOrder.createDealerOrderLines(erps, order, boat);

      Test.startTest();
      PartnerProgram_Service service = new PartnerProgram_Service( new Set<Id>{order.Id} );
      Map<Id, PartnerProgram_Service.Result> result = service.checkAndApply();
      Test.stopTest();

      Id savingsProdId = LGND_Constants.savingsProductId;
      Map<String, Decimal> appliedDiscounts = new Map<String, Decimal>();
      List<AcctSeedERP__Material__c> mats = [
        SELECT Id, AcctSeedERP__Comment__c
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Product__c = :savingsProdId
        AND AcctSeedERP__Project__c = : erps[0].Id
      ];
      for( Map<String, Object> disc : result.get(order.Id).appliedDiscounts )
      {
        appliedDiscounts.put( (String)disc.get('name'), (Decimal)disc.get('percentage') );
      }

      System.assert( appliedDiscounts.keySet().contains( pp_coop.getName() ) );
      System.assert( appliedDiscounts.keySet().contains( pp_cash.getName() ) );
      System.assert( appliedDiscounts.keySet().contains( pp_vol.getName() ) );
      System.assertEquals( 1, appliedDiscounts.get( pp_vol.getName() ) );
      System.assertEquals( 3, result.get(order.Id).appliedDiscountNames.size() );
      System.assertEquals( 3, mats.size() );


    }
  }

  @IsTest
  static void Vhull_withPreviousBookingOrder_Test()
  {
    Account partner = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
    Id boatRtId = LGND_Constants.productRtId_Boat;
    Product2 boat = [ SELECT Id FROM Product2 WHERE Family = 'Full Windshield' AND RecordTypeId = :boatRtId LIMIT 1];
    List<PricebookEntry> pbes = [
      SELECT
        Id,
        Product2Id,
        UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :boat.Id
      AND Pricebook2Id = :LGND_Constants.factoryPricebookId ];
    System.runAs( partnerUser )
    {
      Dealer_Order__c bookingOrder = Factory_DealerOrder.createDealerOrder(partner);
      bookingOrder.Is_Booking_Order__c = true;
      update bookingOrder;
      Partner_Booking_Order__c booking = new Partner_Booking_Order__c(
        Account__c = partner.Id,
        Dealer_Order__c = bookingOrder.Id,
        V_Hull_Discount_Percent__c = 8,
        Name = bookingOrder.Program_Year__c
      );
      insert booking;
      Dealer_Order__c order = Factory_DealerOrder.createDealerOrder(partner);
      List<AcctSeed__Project__c> erps =
        Factory_ERPOrder.createPartnerBoatSales(partner, pbes, 4);
      //List<Dealer_Order_Line__c> orderLines = new List<Dealer_Order_Line__c>();
      Factory_DealerOrder.createDealerOrderLines(erps, order, boat);

      Test.startTest();
      PartnerProgram_Service service = new PartnerProgram_Service( new Set<Id>{order.Id} );
      Map<Id, PartnerProgram_Service.Result> result = service.checkAndApply();
      Test.stopTest();

      Id savingsProdId = LGND_Constants.savingsProductId;
      Map<String, Decimal> appliedDiscounts = new Map<String, Decimal>();
      List<AcctSeedERP__Material__c> mats = [
        SELECT Id, AcctSeedERP__Comment__c
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Product__c = :savingsProdId
        AND AcctSeedERP__Project__c = : erps[0].Id
      ];
      for( Map<String, Object> disc : result.get(order.Id).appliedDiscounts )
      {
        appliedDiscounts.put( (String)disc.get('name'), (Decimal)disc.get('percentage') );
      }

      System.assert( appliedDiscounts.keySet().contains( pp_coop.getName() ) );
      System.assert( appliedDiscounts.keySet().contains( pp_cash.getName() ) );
      System.assert( appliedDiscounts.keySet().contains( pp_vol.getName() ) );
      System.assertEquals( 8, appliedDiscounts.get( pp_vol.getName() ) );
      System.assertEquals( 3, result.get(order.Id).appliedDiscountNames.size() );
      System.assertEquals( 3, mats.size() );


    }
  }

  @IsTest
  static void multiple_Test()
  {
    Account partner = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
    Id boatRtId = LGND_Constants.productRtId_Boat;
    Product2 pontoon = [ SELECT Id FROM Product2 WHERE Family = 'Pontoon' AND RecordTypeId = :boatRtId LIMIT 1];
    List<PricebookEntry> pontoon_pbes = [
      SELECT
        Id,
        Product2Id,
        UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :pontoon.Id
      AND Pricebook2Id = :LGND_Constants.factoryPricebookId ];
    Product2 vHull = [ SELECT Id FROM Product2 WHERE Family = 'Full Windshield' AND RecordTypeId = :boatRtId LIMIT 1];
    List<PricebookEntry> vhull_pbes = [
      SELECT
        Id,
        Product2Id,
        UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :vHull.Id
      AND Pricebook2Id = :LGND_Constants.factoryPricebookId ];
    System.runAs( partnerUser )
    {
      Dealer_Order__c order = Factory_DealerOrder.createDealerOrder(partner);
      order.Is_Booking_Order__c = true;
      update order;
      List<AcctSeed__Project__c> pontoon_erps =
        Factory_ERPOrder.createPartnerBoatSales(partner, pontoon_pbes, 4);
      List<Dealer_Order_Line__c> pontoon_dols =
        Factory_DealerOrder.createDealerOrderLines(pontoon_erps, order, pontoon);
      List<AcctSeed__Project__c> vhull_erps =
        Factory_ERPOrder.createPartnerBoatSales(partner, vhull_pbes, 1);
      List<Dealer_Order_Line__c> vhull_dols =
        Factory_DealerOrder.createDealerOrderLines(vhull_erps, order, vHull);

      Test.startTest();
      PartnerProgram_Service service = new PartnerProgram_Service( new Set<Id>{order.Id} );
      Map<Id, PartnerProgram_Service.Result> result = service.checkAndApply();
      Test.stopTest();

      Id savingsProdId = LGND_Constants.savingsProductId;
      Map<String, Decimal> appliedDiscounts = new Map<String, Decimal>();
      List<AcctSeedERP__Material__c> pontoon_mats = [
        SELECT Id, AcctSeedERP__Comment__c
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Product__c = :savingsProdId
        AND AcctSeedERP__Project__c = : pontoon_erps[0].Id
      ];
      List<AcctSeedERP__Material__c> vhull_mats = [
        SELECT Id, AcctSeedERP__Comment__c
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Product__c = :savingsProdId
        AND AcctSeedERP__Project__c = :vhull_erps[0].Id
      ];
      for( Map<String, Object> disc : result.get(order.Id).appliedDiscounts )
      {
        appliedDiscounts.put( (String)disc.get('name'), (Decimal)disc.get('percentage') );
      }

      System.assert( appliedDiscounts.keySet().contains( pp_coop.getName() ) );
      System.assert( appliedDiscounts.keySet().contains( pp_cash.getName() ) );
      System.assert( appliedDiscounts.keySet().contains( pp_vol.getName() ) );
      System.assert( appliedDiscounts.keySet().contains( pp_pvol.getName() ) );
      System.assertEquals( 1, appliedDiscounts.get( pp_vol.getName() ) );
      System.assertEquals( 1, appliedDiscounts.get( pp_pvol.getName() ) );
      System.assertEquals( 4, result.get(order.Id).appliedDiscountNames.size() );
      System.assertEquals( 3, pontoon_mats.size() );
      System.assertEquals( 3, vhull_mats.size() );

    }
  }


}