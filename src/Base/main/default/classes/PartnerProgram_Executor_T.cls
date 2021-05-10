/**
 * Created by dave on 2020-09-21.
 */

@IsTest
public class PartnerProgram_Executor_T
{
  static Partner_Program_Settings__c programSettings = Partner_Program_Settings__c.getOrgDefaults();
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
  static void Coop_Apply_Test()
  {
    Decimal boatCost = 50000;
    PartnerProgram_Coop program = new PartnerProgram_Coop();
    init('Pontoon', boatCost, null);

    System.runAs(partnerUser)
    {
      createDealerOrder(1);
      Integer materialCountBefore = erps[0].AcctSeedERP__Project_Materials__r.size();
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      Test.startTest();
      new PartnerProgram_Executor().Test_Coop(orderWrapper);
      Test.stopTest();

      List<Partner_Program_Event__e> events = PartnerProgram_Executor.events;
      Map<String, Object> result =
        (Map<String, Object>) JSON.deserializeUntyped(
          events[0].Result__c);
      List<Object> appliedDiscounts = (List<Object>) result.get('appliedDiscounts');
      Map<String, Object> planResult = (Map<String, Object>) appliedDiscounts[0];
      Integer materialCountAfter = [ SELECT COUNT() FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :erps[0].Id ];

      System.debug(appliedDiscounts);
      System.assertEquals( (materialCountBefore + 1), materialCountAfter );
      System.assertEquals(1, events.size());
      System.assertEquals('success', events[0].Status__c);
      System.assertEquals(orderWrapper.dealerOrderId, events[0].DealerOrderId__c);
      System.assertEquals(1, appliedDiscounts.size());
      System.assertEquals(planResult.get('name'), program.getName());
      System.assertEquals((Decimal) planResult.get('percentage'), programSettings.Coop_Discount_Percent__c);
      System.assertEquals((Decimal) result.get('totalSavings'), boatCost * (programSettings.Coop_Discount_Percent__c / 100));
    }
  }

  @IsTest
  static void Coop_CheckOnly_Test()
  {
    Decimal boatCost = 50000;
    PartnerProgram_Coop program = new PartnerProgram_Coop();
    init('Pontoon', boatCost, null);

    System.runAs(partnerUser)
    {
      createDealerOrder(1);
      Integer materialCountBefore = erps[0].AcctSeedERP__Project_Materials__r.size();
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      orderWrapper.setCheckOnly();
      Test.startTest();
      new PartnerProgram_Executor().Test_Coop(orderWrapper);
      Test.stopTest();

      List<Partner_Program_Event__e> events = PartnerProgram_Executor.events;
      Map<String, Object> result =
        (Map<String, Object>) JSON.deserializeUntyped(
          events[0].Result__c);
      List<Object> appliedDiscounts = (List<Object>) result.get('appliedDiscounts');
      Map<String, Object> planResult = (Map<String, Object>) appliedDiscounts[0];
      Integer materialCountAfter = [ SELECT COUNT() FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :erps[0].Id ];

      System.debug(appliedDiscounts);
      System.assertEquals( materialCountBefore, materialCountAfter );
      System.assertEquals(1, events.size());
      System.assertEquals('success', events[0].Status__c);
      System.assertEquals(orderWrapper.dealerOrderId, events[0].DealerOrderId__c);
      System.assertEquals(1, appliedDiscounts.size());
      System.assertEquals(planResult.get('name'), program.getName());
      System.assertEquals((Decimal) planResult.get('percentage'), programSettings.Coop_Discount_Percent__c);
      System.assertEquals((Decimal) result.get('totalSavings'), boatCost * (programSettings.Coop_Discount_Percent__c / 100));
    }
  }

  @IsTest
  static void KickStart_Apply_Test()
  {
    Decimal boatCost = 50000;
    PartnerProgram_Kickstart_Booking program = new PartnerProgram_Kickstart_Booking();
    init('Pontoon', boatCost, null);

    System.runAs(partnerUser)
    {
      createDealerOrder(1);
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      Integer materialCountBefore = erps[0].AcctSeedERP__Project_Materials__r.size();

      Test.startTest();
      new PartnerProgram_Executor().Test_KickStart(orderWrapper);
      Test.stopTest();

      List<Partner_Program_Event__e> events = PartnerProgram_Executor.events;
      Map<String, Object> result =
        (Map<String, Object>) JSON.deserializeUntyped(
          events[0].Result__c);
      List<Object> appliedDiscounts = (List<Object>) result.get('appliedDiscounts');
      Map<String, Object> planResult = (Map<String, Object>) appliedDiscounts[0];
      Integer materialCountAfter = [ SELECT COUNT() FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :erps[0].Id ];

      System.debug(appliedDiscounts);
      System.assertEquals(1, events.size());
      System.assertEquals('success', events[0].Status__c);
      System.assertEquals( (materialCountBefore + 1), materialCountAfter );
      System.assertEquals(orderWrapper.dealerOrderId, events[0].DealerOrderId__c);
      System.assertEquals(1, appliedDiscounts.size());
      System.assertEquals(planResult.get('name'), program.getName());
      System.assertEquals((Decimal) planResult.get('percentage'), programSettings.Kickstart_Booking_Order_Discount_Percent__c);
      System.assertEquals((Decimal) result.get('totalSavings'), boatCost * (programSettings.Kickstart_Booking_Order_Discount_Percent__c / 100));
    }
  }

  @IsTest
  static void KickStart_CheckOnly_Test()
  {
    Decimal boatCost = 50000;
    PartnerProgram_Kickstart_Booking program = new PartnerProgram_Kickstart_Booking();
    init('Pontoon', boatCost, null);

    System.runAs(partnerUser)
    {
      createDealerOrder(1);
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      orderWrapper.setCheckOnly();
      Integer materialCountBefore = erps[0].AcctSeedERP__Project_Materials__r.size();

      Test.startTest();
      new PartnerProgram_Executor().Test_KickStart(orderWrapper);
      Test.stopTest();

      List<Partner_Program_Event__e> events = PartnerProgram_Executor.events;
      Map<String, Object> result =
        (Map<String, Object>) JSON.deserializeUntyped(
          events[0].Result__c);
      List<Object> appliedDiscounts = (List<Object>) result.get('appliedDiscounts');
      Map<String, Object> planResult = (Map<String, Object>) appliedDiscounts[0];
      Integer materialCountAfter = [ SELECT COUNT() FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :erps[0].Id ];

      System.debug(appliedDiscounts);
      System.assertEquals(1, events.size());
      System.assertEquals('success', events[0].Status__c);
      System.assertEquals( materialCountBefore, materialCountAfter );
      System.assertEquals(orderWrapper.dealerOrderId, events[0].DealerOrderId__c);
      System.assertEquals(1, appliedDiscounts.size());
      System.assertEquals(planResult.get('name'), program.getName());
      System.assertEquals((Decimal) planResult.get('percentage'), programSettings.Kickstart_Booking_Order_Discount_Percent__c);
      System.assertEquals((Decimal) result.get('totalSavings'), boatCost * (programSettings.Kickstart_Booking_Order_Discount_Percent__c / 100));
    }
  }

  @IsTest
  static void Cash_Apply_Test()
  {
    Decimal boatCost = 50000;
    PartnerProgram_Cash program = new PartnerProgram_Cash();
    init('Pontoon', boatCost, null);

    System.runAs( partnerUser )
    {
      createDealerOrder(1);
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
      new PartnerProgram_Service.DealerOrderWrapper(
      order, erps, null
      );
      Integer materialCountBefore = erps[0].AcctSeedERP__Project_Materials__r.size();

      Test.startTest();
      new PartnerProgram_Executor().Test_Cash( orderWrapper);
      Test.stopTest();

      List<Partner_Program_Event__e> events = PartnerProgram_Executor.events;
      Map<String, Object> result =
      (Map<String, Object>)JSON.deserializeUntyped(
      events[0].Result__c );
      List<Object> appliedDiscounts = (List<Object>)result.get('appliedDiscounts');
      Map<String, Object> planResult = (Map<String, Object>)appliedDiscounts[0];
      Integer materialCountAfter = [ SELECT COUNT() FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :erps[0].Id ];

      System.debug( appliedDiscounts );
      System.assertEquals( 1, events.size() );
      System.assertEquals('success', events[0].Status__c );
      System.assertEquals( (materialCountBefore + 1), materialCountAfter );
      System.assertEquals( orderWrapper.dealerOrderId, events[0].DealerOrderId__c );
      System.assertEquals( 1, appliedDiscounts.size() );
      System.assertEquals( planResult.get('name'), program.getName() );
      System.assertEquals( (Decimal)planResult.get('percentage'), determineCashDiscount() );
      System.assertEquals( (Decimal)result.get('totalSavings'), boatCost * ( determineCashDiscount() / 100 ) );
    }
  }

  @IsTest
  static void Cash_CheckOnly_Test()
  {
    Decimal boatCost = 50000;
    PartnerProgram_Cash program = new PartnerProgram_Cash();
    init('Pontoon', boatCost, null);

    System.runAs( partnerUser )
    {
      createDealerOrder(1);
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      orderWrapper.setCheckOnly();
      Integer materialCountBefore = erps[0].AcctSeedERP__Project_Materials__r.size();

      Test.startTest();
      new PartnerProgram_Executor().Test_Cash( orderWrapper);
      Test.stopTest();

      List<Partner_Program_Event__e> events = PartnerProgram_Executor.events;
      Map<String, Object> result =
        (Map<String, Object>)JSON.deserializeUntyped(
          events[0].Result__c );
      List<Object> appliedDiscounts = (List<Object>)result.get('appliedDiscounts');
      Map<String, Object> planResult = (Map<String, Object>)appliedDiscounts[0];
      Integer materialCountAfter = [ SELECT COUNT() FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :erps[0].Id ];

      System.debug( appliedDiscounts );
      System.assertEquals( 1, events.size() );
      System.assertEquals('success', events[0].Status__c );
      System.assertEquals( materialCountBefore, materialCountAfter );
      System.assertEquals( orderWrapper.dealerOrderId, events[0].DealerOrderId__c );
      System.assertEquals( 1, appliedDiscounts.size() );
      System.assertEquals( planResult.get('name'), program.getName() );
      System.assertEquals( (Decimal)planResult.get('percentage'), determineCashDiscount() );
      System.assertEquals( (Decimal)result.get('totalSavings'), boatCost * ( determineCashDiscount() / 100 ) );
    }
  }

  @IsTest
  static void Volume_Apply_Test()
  {
    Decimal boatCost = 50000;
    PartnerProgram_Volume program = new PartnerProgram_Volume();
    init('Full Windshield', boatCost, null);

    System.runAs( partnerUser )
    {
      createDealerOrder(4);
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      Integer materialCountBefore = erps[0].AcctSeedERP__Project_Materials__r.size();

      Test.startTest();
      new PartnerProgram_Executor().Test_Volume( orderWrapper);
      Test.stopTest();

      List<Partner_Program_Event__e> events = PartnerProgram_Executor.events;
      Map<String, Object> result =
        (Map<String, Object>)JSON.deserializeUntyped(
          events[0].Result__c );
      List<Object> appliedDiscounts = (List<Object>)result.get('appliedDiscounts');
      Map<String, Object> planResult = (Map<String, Object>)appliedDiscounts[0];
      Integer materialCountAfter = [ SELECT COUNT() FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :erps[0].Id ];

      System.debug( appliedDiscounts );
      System.assertEquals( 1, events.size() );
      System.assertEquals('success', events[0].Status__c );
      System.assertEquals( (materialCountBefore + 1), materialCountAfter );
      System.assertEquals( orderWrapper.dealerOrderId, events[0].DealerOrderId__c );
      System.assertEquals( appliedDiscounts.size(), 1 );
      System.assertEquals( program.getName(), planResult.get('name') );
      System.assertEquals( 1, (Decimal)planResult.get('percentage') );
      System.assertEquals( 4 * boatCost * 0.01, (Decimal)result.get('totalSavings')  );
    }
  }

  @IsTest
  static void Volume_CheckOnly_Test()
  {
    Decimal boatCost = 50000;
    PartnerProgram_Volume program = new PartnerProgram_Volume();
    init('Full Windshield', boatCost, null);

    System.runAs( partnerUser )
    {
      createDealerOrder(4);
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      orderWrapper.setCheckOnly();
      Integer materialCountBefore = erps[0].AcctSeedERP__Project_Materials__r.size();

      Test.startTest();
      new PartnerProgram_Executor().Test_Volume( orderWrapper);
      Test.stopTest();

      List<Partner_Program_Event__e> events = PartnerProgram_Executor.events;
      Map<String, Object> result =
        (Map<String, Object>)JSON.deserializeUntyped(
          events[0].Result__c );
      List<Object> appliedDiscounts = (List<Object>)result.get('appliedDiscounts');
      Map<String, Object> planResult = (Map<String, Object>)appliedDiscounts[0];
      Integer materialCountAfter = [ SELECT COUNT() FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :erps[0].Id ];

      System.debug( appliedDiscounts );
      System.assertEquals( 1, events.size() );
      System.assertEquals('success', events[0].Status__c );
      System.assertEquals( materialCountBefore, materialCountAfter );
      System.assertEquals( orderWrapper.dealerOrderId, events[0].DealerOrderId__c );
      System.assertEquals( appliedDiscounts.size(), 1 );
      System.assertEquals( program.getName(), planResult.get('name') );
      System.assertEquals( 1, (Decimal)planResult.get('percentage') );
      System.assertEquals( 4 * boatCost * 0.01, (Decimal)result.get('totalSavings')  );
    }
  }

  @IsTest
  static void PontoonVolume_Apply_Test()
  {
    Decimal boatCost = 50000;
    PartnerProgram_PontoonVol program = new PartnerProgram_PontoonVol();
    init('Pontoon', boatCost, null);

    System.runAs( partnerUser )
    {
      createDealerOrder(4);
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      Integer materialCountBefore = erps[0].AcctSeedERP__Project_Materials__r.size();

      Test.startTest();
      new PartnerProgram_Executor().Test_PontoonVolume( orderWrapper );
      Test.stopTest();

      List<Partner_Program_Event__e> events = PartnerProgram_Executor.events;
      Map<String, Object> result =
        (Map<String, Object>)JSON.deserializeUntyped(
          events[0].Result__c );
      List<Object> appliedDiscounts = (List<Object>)result.get('appliedDiscounts');
      Map<String, Object> planResult = (Map<String, Object>)appliedDiscounts[0];
      Integer materialCountAfter = [ SELECT COUNT() FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :erps[0].Id ];

      System.debug( appliedDiscounts );
      System.assertEquals( 1, events.size() );
      System.assertEquals('success', events[0].Status__c );
      System.assertEquals( (materialCountBefore + 1), materialCountAfter );
      System.assertEquals( orderWrapper.dealerOrderId, events[0].DealerOrderId__c );
      System.assertEquals( appliedDiscounts.size(), 1 );
      System.assertEquals( program.getName(), planResult.get('name') );
      System.assertEquals( 1, (Decimal)planResult.get('percentage') );
      System.assertEquals( 4 * boatCost * 0.01, (Decimal)result.get('totalSavings')  );
    }
  }

  @IsTest
  static void PontoonVolume_CheckOnly_Test()
  {
    Decimal boatCost = 50000;
    PartnerProgram_PontoonVol program = new PartnerProgram_PontoonVol();
    init('Pontoon', boatCost, null);

    System.runAs( partnerUser )
    {
      createDealerOrder(4);
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      orderWrapper.setCheckOnly();
      Integer materialCountBefore = erps[0].AcctSeedERP__Project_Materials__r.size();

      Test.startTest();
      new PartnerProgram_Executor().Test_PontoonVolume( orderWrapper );
      Test.stopTest();

      List<Partner_Program_Event__e> events = PartnerProgram_Executor.events;
      Map<String, Object> result =
        (Map<String, Object>)JSON.deserializeUntyped(
          events[0].Result__c );
      List<Object> appliedDiscounts = (List<Object>)result.get('appliedDiscounts');
      Map<String, Object> planResult = (Map<String, Object>)appliedDiscounts[0];
      Integer materialCountAfter = [ SELECT COUNT() FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :erps[0].Id ];

      System.debug( appliedDiscounts );
      System.assertEquals( 1, events.size() );
      System.assertEquals('success', events[0].Status__c );
      System.assertEquals( materialCountBefore, materialCountAfter );
      System.assertEquals( orderWrapper.dealerOrderId, events[0].DealerOrderId__c );
      System.assertEquals( appliedDiscounts.size(), 1 );
      System.assertEquals( program.getName(), planResult.get('name') );
      System.assertEquals( 1, (Decimal)planResult.get('percentage') );
      System.assertEquals( 4 * boatCost * 0.01, (Decimal)result.get('totalSavings')  );
    }
  }

  @IsTest
  static void Seven4Seven_Apply_Test()
  {
    Decimal boatCost = 10000;
    PartnerProgram_7for7 program = new PartnerProgram_7for7();
    init('Utility', boatCost, 3);

    System.runAs( partnerUser )
    {
      createDealerOrder(9);
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      Integer materialCountBefore = erps[0].AcctSeedERP__Project_Materials__r.size();

      Test.startTest();
      new PartnerProgram_Executor().Test_7for7( orderWrapper );
      Test.stopTest();

      List<Partner_Program_Event__e> events = PartnerProgram_Executor.events;
      Map<String, Object> result =
        (Map<String, Object>)JSON.deserializeUntyped(
          events[0].Result__c );
      List<Object> appliedDiscounts = (List<Object>)result.get('appliedDiscounts');
      Map<String, Object> planResult = (Map<String, Object>)appliedDiscounts[0];
      Integer materialCountAfter = [ SELECT COUNT() FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :erps[0].Id ];

      System.debug( appliedDiscounts );
      System.assertEquals( 1, events.size() );
      System.assertEquals('success', events[0].Status__c );
      System.assertEquals( (materialCountBefore + 1), materialCountAfter );
      System.assertEquals( orderWrapper.dealerOrderId, events[0].DealerOrderId__c );
      System.assertEquals( appliedDiscounts.size(), 1 );
      System.assertEquals( program.getName(), planResult.get('name') );
      System.assertEquals( 7, (Decimal)planResult.get('percentage') );
      System.assertEquals( 9 * boatCost * 0.07, (Decimal)result.get('totalSavings')  );
    }
  }

  @IsTest
  static void Seven4Seven_CheckOnly_Test()
  {
    Decimal boatCost = 10000;
    PartnerProgram_7for7 program = new PartnerProgram_7for7();
    init('Utility', boatCost, 3);

    System.runAs( partnerUser )
    {
      createDealerOrder(9);
      PartnerProgram_Service.DealerOrderWrapper orderWrapper =
        new PartnerProgram_Service.DealerOrderWrapper(
          order, erps, null
        );
      orderWrapper.setCheckOnly();
      Integer materialCountBefore = erps[0].AcctSeedERP__Project_Materials__r.size();

      Test.startTest();
      new PartnerProgram_Executor().Test_7for7( orderWrapper );
      Test.stopTest();

      List<Partner_Program_Event__e> events = PartnerProgram_Executor.events;
      Map<String, Object> result =
        (Map<String, Object>)JSON.deserializeUntyped(
          events[0].Result__c );
      List<Object> appliedDiscounts = (List<Object>)result.get('appliedDiscounts');
      Map<String, Object> planResult = (Map<String, Object>)appliedDiscounts[0];
      Integer materialCountAfter = [ SELECT COUNT() FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :erps[0].Id ];

      System.debug( appliedDiscounts );
      System.assertEquals( 1, events.size() );
      System.assertEquals('success', events[0].Status__c );
      System.assertEquals( materialCountBefore, materialCountAfter );
      System.assertEquals( orderWrapper.dealerOrderId, events[0].DealerOrderId__c );
      System.assertEquals( appliedDiscounts.size(), 1 );
      System.assertEquals( program.getName(), planResult.get('name') );
      System.assertEquals( 7, (Decimal)planResult.get('percentage') );
      System.assertEquals( 9 * boatCost * 0.07, (Decimal)result.get('totalSavings')  );
    }
  }

}