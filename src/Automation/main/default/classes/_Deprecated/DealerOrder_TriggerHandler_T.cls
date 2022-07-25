/**
 * Created by dave on 2020-09-21.
 */
/* TODO: DELETE ME */
@IsTest
private class DealerOrder_TriggerHandler_T {
  //  static String partnerAccountName = 'TestPartner';
  //  static Account partner;
  //  static User partnerUser;
  //  static Product2 boat;
  //  static Product2 motor;
  //  static PricebookEntry pbe;
  //  static Dealer_Order__c order;
  //  static List<AcctSeed__Project__c> erps;
  //  static Set<Id> erpIds;
  //
  //  @testSetup static void dataSetup()
  //  {
  //    new Factory_TestData();
  //    Factory_CustomSettings.setupInventorySettings();
  //    insert new Partner_Program_Settings__c(
  //      Coop_Discount_Percent__c = 2,
  //      Kickstart_Booking_Order_Discount_Percent__c = 2,
  //      Available_Model_Years__c = '2020,2021',
  //      Available_Program_Years__c = '2021'
  //    );
  //    Account partner = Factory_Account.buildDealerAccounts(1)[0];
  //    partner.Name = partnerAccountName;
  //    partner.BillingState = 'Ontario';
  //    insert partner;
  //    Factory_User.createPartnerUser(partner);
  //  }
  //
  //  private static void findPartner()
  //  {
  //    Id rtId = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer');
  //    partner = [SELECT Id, Name, BillingState FROM Account WHERE Name = :partnerAccountName AND RecordTypeId = :rtId];
  //  }
  //
  //  private static void buildBoat(String family, Decimal cost, Integer stackSize)
  //  {
  //    Id fpbId = LGND_Constants.factoryPricebookId;
  //    boat = Factory_Product.buildSerializedProduct('Boat', family);
  //    boat.Stack_Size__c = stackSize;
  //    insert boat;
  //    Factory_PricebookEntry.insertStandardEntries(new List<Product2>
  //    {
  //      boat
  //    }, cost);
  //    pbe = Factory_PricebookEntry.buildEntry(boat.Id, fpbId, cost);
  //    insert pbe;
  //  }
  //
  //  private static void buildMotor( Decimal cost )
  //  {
  //    Id fpbId = LGND_Constants.factoryPricebookId;
  //    motor = Factory_Product.buildSerializedProduct('Motor', 'Remote');
  //    insert motor;
  //    Factory_PricebookEntry.insertStandardEntries(new List<Product2>
  //    {
  //      motor
  //    }, cost);
  //    pbe = Factory_PricebookEntry.buildEntry(motor.Id, fpbId, cost);
  //    insert pbe;
  //  }
  //
  //  private static void init()
  //  {
  //    findPartner();
  //    partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
  //  }
  //
  //  private static void buildDealerOrder(Boolean isBooking, String stage)
  //  {
  //    order = Factory_DealerOrder.buildDealerOrder(partner);
  //    order.Is_Booking_Order__c = isBooking;
  //    order.Stage__c = stage;
  //  }
  //
  //  private static void createDealerOrderLines(Dealer_Order__c dealerOrder, Integer quantity)
  //  {
  //    erps = Factory_ERPOrder.createPartnerBoatSales(partner, new List<PricebookEntry>
  //    {
  //      pbe
  //    }, quantity);
  //    Factory_DealerOrder.createDealerOrderLines(erps, order, boat);
  //    erpIds = LGND_Utilities.getIdSetFromList((List<sObject>) erps);
  //  }
  //
  //  @IsTest
  //  static void beforeInsert_Test()
  //  {
  //    init();
  //    System.runAs(partnerUser)
  //    {
  //      buildDealerOrder(true, 'Pending Review');
  //      DateTime tNow = DateTime.now();
  //      Test.startTest();
  //      insert order;
  //      Test.stopTest();
  //
  //      order = [SELECT Id, Date_Submitted__c FROM Dealer_Order__c WHERE Id = :order.Id];
  //      System.assertEquals(tNow.year(), order.Date_Submitted__c.year());
  //      System.assertEquals(tNow.month(), order.Date_Submitted__c.month());
  //      System.assertEquals(tNow.day(), order.Date_Submitted__c.day());
  //    }
  //  }
  //
  //  @IsTest
  //  static void beforeUpdate_Test()
  //  {
  //    init();
  //    System.runAs(partnerUser)
  //    {
  //      buildDealerOrder(true, 'Draft');
  //      insert order;
  //
  //      order = [SELECT Id, Date_Submitted__c FROM Dealer_Order__c WHERE Id = :order.Id];
  //      System.assert(order.Date_Submitted__c == null);
  //
  //      order.Stage__c = 'Pending Review';
  //      update order;
  //      order = [SELECT Id, Date_Submitted__c FROM Dealer_Order__c WHERE Id = :order.Id];
  //      System.assert(order.Date_Submitted__c != null);
  //
  //      order.Stage__c = 'Draft';
  //      update order;
  //      order = [SELECT Id, Date_Submitted__c FROM Dealer_Order__c WHERE Id = :order.Id];
  //      System.assert(order.Date_Submitted__c == null);
  //
  //    }
  //  }
  //
  //  @IsTest
  //  static void afterInsert_Test()
  //  {
  //    init();
  //    System.runAs(partnerUser)
  //    {
  //      buildDealerOrder(true, 'Draft');
  //      Test.startTest();
  //      insert order;
  //      Test.stopTest();
  //
  //      Partner_Booking_Order__c[] bookingOrders = [
  //        SELECT Id
  //        FROM Partner_Booking_Order__c
  //        WHERE Dealer_Order__c = :order.Id
  //      ];
  //
  //      System.assertEquals(1, bookingOrders.size());
  //
  //    }
  //  }
  //
  //  @IsTest
  //  static void beforeDelete_Fail_Test()
  //  {
  //    init();
  //    System.runAs(partnerUser)
  //    {
  //      buildDealerOrder(true, 'Pending Review');
  //      insert order;
  //      Test.startTest();
  //      try
  //      {
  //        delete order;
  //      }
  //      catch (Exception e)
  //      {
  //        System.assert(
  //          e.getMessage()
  //            .contains('You can not delete a Dealer Order with stage "Pending Review"')
  //        );
  //      }
  //    }
  //  }
  //
  //  @IsTest
  //  static void beforeDelete_Test()
  //  {
  //    init();
  //    buildBoat('Pontoon', 50000, null);
  //    System.runAs(partnerUser)
  //    {
  //      buildDealerOrder(true, 'Draft');
  //      insert order;
  //      createDealerOrderLines(order, 3);
  //      Test.startTest();
  //      delete order;
  //      Test.stopTest();
  //
  //      List<AcctSeed__Project__c> erps = [
  //        SELECT Id
  //        FROM AcctSeed__Project__c
  //        WHERE Id IN :erpIds
  //      ];
  //
  //      System.assert(erps.isEmpty());
  //    }
  //  }
  //
  //  @IsTest
  //  static void afterUpdate_DraftReview_Test()
  //  {
  //    init();
  //    buildBoat('Pontoon', 50000, null);
  //    System.runAs(partnerUser)
  //    {
  //      buildDealerOrder(true, 'Pending Review');
  //      insert order;
  //      createDealerOrderLines(order, 1);
  //      Test.startTest();
  //      order.Stage__c = 'Draft';
  //      update order;
  //      Test.stopTest();
  //
  //      AcctSeed__Project__c erp = [SELECT Id, Stage__c FROM AcctSeed__Project__c WHERE Id = :erps[0].Id];
  //      System.assertEquals('Draft', erp.Stage__c);
  //    }
  //  }
  //
  //  @IsTest
  //  static void afterUpdate_PendingReview_Test()
  //  {
  //    init();
  //    buildBoat('Pontoon', 50000, null);
  //    System.runAs(partnerUser)
  //    {
  //      buildDealerOrder(true, 'Draft');
  //      insert order;
  //      createDealerOrderLines(order, 1);
  //      Test.startTest();
  //      order.Stage__c = 'Pending Review';
  //      update order;
  //      Test.stopTest();
  //
  //      AcctSeed__Project__c erp = [SELECT Id, Stage__c FROM AcctSeed__Project__c WHERE Id = :erps[0].Id];
  //      System.assertEquals('Pending Review', erp.Stage__c);
  //
  //    }
  //  }
  //
  //  @IsTest
  //  static void afterUpdate_PendingFinancing_Test()
  //  {
  //    init();
  //    buildBoat('Pontoon', 50000, null);
  //    System.runAs(partnerUser)
  //    {
  //      buildDealerOrder(true, 'Draft');
  //      insert order;
  //      createDealerOrderLines(order, 1);
  //      Test.startTest();
  //      order.Stage__c = 'Pending Financing';
  //      update order;
  //      Test.stopTest();
  //
  //      AcctSeed__Project__c erp = [SELECT Id, Stage__c FROM AcctSeed__Project__c WHERE Id = :erps[0].Id];
  //      System.assertEquals('Pending Financing', erp.Stage__c);
  //
  //    }
  //  }
  //
  //  @IsTest
  //  static void afterUpdate_Approved_Test()
  //  {
  //    init();
  //    buildBoat('Pontoon', 50000, null);
  //    System.runAs(partnerUser)
  //    {
  //      buildDealerOrder(true, 'Draft');
  //      insert order;
  //      createDealerOrderLines(order, 1);
  //      Test.startTest();
  //      order.Stage__c = 'Approved';
  //      update order;
  //      Test.stopTest();
  //
  //      AcctSeed__Project__c erp = [SELECT Id, Stage__c FROM AcctSeed__Project__c WHERE Id = :erps[0].Id];
  //      System.assertEquals('Tagging Pending', erp.Stage__c);
  //
  //    }
  //  }
  //
  //  @IsTest
  //  static void afterUpdate_OwnerPropagation_Test()
  //  {
  //    init();
  //    buildBoat('Pontoon', 50000, null);
  //    buildDealerOrder(true, 'Pending Review');
  //    insert order;
  //    createDealerOrderLines(order, 1);
  //    Test.startTest();
  //    order.OwnerId = partnerUser.Id;
  //    update order;
  //    Test.stopTest();
  //
  //    order = [SELECT Id, OwnerId FROM Dealer_Order__c WHERE Id = :order.Id ];
  //    AcctSeed__Project__c erp = [SELECT Id, OwnerId FROM AcctSeed__Project__c WHERE Id = :erps[0].Id];
  //    System.assertEquals( partnerUser.Id, order.OwnerId );
  //    System.assertEquals( partnerUser.Id, erp.OwnerId );
  //
  //  }
  //
  //  @IsTest
  //  static void afterUpdate_MotorRequest_SendEmail_Test()
  //  {
  //    init();
  //    buildMotor( 2000 );
  //    System.runAs(partnerUser)
  //    {
  //      buildDealerOrder(true, 'Draft');
  //      insert order;
  //      Dealer_Motor_Request__c dmr = new Dealer_Motor_Request__c(
  //        Motor__c = motor.Id,
  //        Notes__c = 'Test DMR',
  //        Quantity__c = 1
  //      );
  //      insert dmr;
  //      Factory_DealerOrder.createDealerOrderLines(new List<Dealer_Motor_Request__c>{ dmr }, order, motor );
  //      Test.startTest();
  //      order.Stage__c = 'Pending Financing';
  //      update order;
  //      Test.stopTest();
  //
  //      order = [ SELECT Id, Merc_Order_Sent__c FROM Dealer_Order__c WHERE Id = :order.Id ];
  //      System.assert( order.Merc_Order_Sent__c );
  //    }
  //  }
}
