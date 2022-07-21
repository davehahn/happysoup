/**
 * Created by dave on 2020-08-11.
 */

@IsTest
private class PartnerProgram_Service_T {
  static String partnerAccountName = 'TestPartner';

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    insert new Partner_Program_Settings__c(
      Coop_Discount_Percent__c = 2,
      Kickstart_Booking_Order_Discount_Percent__c = 2
    );
    Account partner = Factory_Account.buildDealerAccounts(1)[0];
    partner.Name = partnerAccountName;
    partner.BillingState = 'Ontario';
    insert partner;
    Factory_User.createPartnerUser(partner);
    createBoats();
  }

  private static Account findPartner() {
    Id rtId = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer');
    return [SELECT Id, Name, BillingState FROM Account WHERE Name = :partnerAccountName AND RecordTypeId = :rtId];
  }

  private static Map<String, Product2> createBoats() {
    Id fpbId = LGND_Constants.factoryPricebookId;
    Map<String, Product2> boats = new Map<String, Product2>();
    boats.put('Pontoon', Factory_Product.buildSerializedProduct('Boat', 'Pontoon'));
    boats.put('FullWindshield', Factory_Product.buildSerializedProduct('Boat', 'Full WindShield'));
    Product2 utility = Factory_Product.buildSerializedProduct('Boat', 'utility');
    utility.Stack_Size__c = 3;
    boats.put('Utility', utility);
    insert boats.values();
    Factory_PricebookEntry.insertStandardEntries(boats.values(), 1000);
    List<PricebookEntry> pbes = new List<PricebookEntry>();
    pbes.add(Factory_PricebookEntry.buildEntry(boats.get('Utility').Id, fpbId, 10000));
    pbes.add(Factory_PricebookEntry.buildEntry(boats.get('FullWindshield').Id, fpbId, 50000));
    pbes.add(Factory_PricebookEntry.buildEntry(boats.get('Pontoon').Id, fpbId, 30000));
    insert pbes;
    return boats;
  }

  @IsTest
  static void UtilityOnly_Test() {
    Account partner = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
    Id boatRtId = LGND_Constants.productRtId_Boat;
    List<Product2> boats = [SELECT Id FROM Product2 WHERE Family = 'Utility' AND RecordTypeId = :boatRtId LIMIT 1];

    System.runAs(partnerUser) {
      Dealer_Order__c order = Factory_DealerOrder.createDealerOrder(partner);
      List<AcctSeed__Project__c> erps = Factory_ERPOrder.createPartnerBoatSales(partner, boats, 9);
      List<Dealer_Order_Line__c> orderLines = new List<Dealer_Order_Line__c>();
      Factory_DealerOrder.createDealerOrderLines(erps, order, boats[0]);

      Test.startTest();
      PartnerProgram_Service service = new PartnerProgram_Service(new Set<Id>{ order.Id });
      service.checkAndApply();
      Test.stopTest();

      System.assertEquals(1, service.dealerOrderIds.size());
      System.assertEquals(1, service.dealerOrderMap.keySet().size());
      System.assertEquals(1, service.erpsByDealerOrder.keySet().size());
      for (Id key : service.erpsByDealerOrder.keySet()) {
        System.assertEquals(9, service.erpsByDealerOrder.get(key).size());
      }
    }
  }

  @IsTest
  static void Pontoon4_Test() {
    Account partner = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
    Id boatRtId = LGND_Constants.productRtId_Boat;
    List<Product2> boats = [SELECT Id FROM Product2 WHERE Family = 'Pontoon' AND RecordTypeId = :boatRtId LIMIT 1];

    System.runAs(partnerUser) {
      Dealer_Order__c order = Factory_DealerOrder.createDealerOrder(partner);
      order.Is_Booking_Order__c = true;
      update order;
      List<AcctSeed__Project__c> erps = Factory_ERPOrder.createPartnerBoatSales(partner, boats, 4);
      List<Dealer_Order_Line__c> orderLines = new List<Dealer_Order_Line__c>();
      Factory_DealerOrder.createDealerOrderLines(erps, order, boats[0]);

      Test.startTest();
      PartnerProgram_Service service = new PartnerProgram_Service(new Set<Id>{ order.Id });
      service.checkAndApply();
      Test.stopTest();

      System.assertEquals(1, service.dealerOrderIds.size());
      System.assertEquals(1, service.dealerOrderMap.keySet().size());
      System.assertEquals(1, service.erpsByDealerOrder.keySet().size());
      for (Id key : service.erpsByDealerOrder.keySet()) {
        System.assertEquals(4, service.erpsByDealerOrder.get(key).size());
      }
    }
  }

  @IsTest
  static void Pontoon12_Test() {
    Account partner = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
    Id boatRtId = LGND_Constants.productRtId_Boat;
    List<Product2> boats = [SELECT Id FROM Product2 WHERE Family = 'Pontoon' AND RecordTypeId = :boatRtId LIMIT 1];

    System.runAs(partnerUser) {
      Dealer_Order__c order = Factory_DealerOrder.createDealerOrder(partner);
      order.Is_Booking_Order__c = true;
      update order;
      List<AcctSeed__Project__c> erps = Factory_ERPOrder.createPartnerBoatSales(partner, boats, 12);
      Factory_DealerOrder.createDealerOrderLines(erps, order, boats[0]);

      Test.startTest();
      PartnerProgram_Service service = new PartnerProgram_Service(new Set<Id>{ order.Id });
      service.checkAndApply();
      Test.stopTest();

      System.assertEquals(1, service.dealerOrderIds.size());
      System.assertEquals(1, service.dealerOrderMap.keySet().size());
      System.assertEquals(1, service.erpsByDealerOrder.keySet().size());
      for (Id key : service.erpsByDealerOrder.keySet()) {
        System.assertEquals(12, service.erpsByDealerOrder.get(key).size());
      }
    }
  }

  @IsTest
  static void Vhull_Test() {
    Account partner = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
    Id boatRtId = LGND_Constants.productRtId_Boat;
    Product2 boat = [SELECT Id FROM Product2 WHERE Family = 'Full Windshield' AND RecordTypeId = :boatRtId LIMIT 1];
    List<PricebookEntry> pbes = [
      SELECT Id, Product2Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :boat.Id AND Pricebook2Id = :LGND_Constants.factoryPricebookId
    ];
    System.runAs(partnerUser) {
      Dealer_Order__c order = Factory_DealerOrder.createDealerOrder(partner);
      order.Is_Booking_Order__c = true;
      update order;
      List<AcctSeed__Project__c> erps = Factory_ERPOrder.createPartnerBoatSales(partner, pbes, 4);
      //List<Dealer_Order_Line__c> orderLines = new List<Dealer_Order_Line__c>();
      Factory_DealerOrder.createDealerOrderLines(erps, order, boat);

      Test.startTest();
      PartnerProgram_Service service = new PartnerProgram_Service(new Set<Id>{ order.Id });
      service.checkAndApply();
      Test.stopTest();

      System.assertEquals(1, service.dealerOrderIds.size());
      System.assertEquals(1, service.dealerOrderMap.keySet().size());
      System.assertEquals(1, service.erpsByDealerOrder.keySet().size());
      for (Id key : service.erpsByDealerOrder.keySet()) {
        System.assertEquals(4, service.erpsByDealerOrder.get(key).size());
      }
    }
  }

  @IsTest
  static void Vhull_withPreviousBookingOrder_Test() {
    Account partner = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
    Id boatRtId = LGND_Constants.productRtId_Boat;
    Product2 boat = [SELECT Id FROM Product2 WHERE Family = 'Full Windshield' AND RecordTypeId = :boatRtId LIMIT 1];
    List<PricebookEntry> pbes = [
      SELECT Id, Product2Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :boat.Id AND Pricebook2Id = :LGND_Constants.factoryPricebookId
    ];
    System.runAs(partnerUser) {
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
      List<AcctSeed__Project__c> erps = Factory_ERPOrder.createPartnerBoatSales(partner, pbes, 4);
      //List<Dealer_Order_Line__c> orderLines = new List<Dealer_Order_Line__c>();
      Factory_DealerOrder.createDealerOrderLines(erps, order, boat);

      Test.startTest();
      PartnerProgram_Service service = new PartnerProgram_Service(new Set<Id>{ order.Id });
      service.checkAndApply();
      Test.stopTest();

      System.assertEquals(1, service.dealerOrderIds.size());
      System.assertEquals(1, service.dealerOrderMap.keySet().size());
      System.assertEquals(1, service.erpsByDealerOrder.keySet().size());
      for (Id key : service.erpsByDealerOrder.keySet()) {
        System.assertEquals(4, service.erpsByDealerOrder.get(key).size());
      }
    }
  }

  @IsTest
  static void multiple_Test() {
    Account partner = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
    Id boatRtId = LGND_Constants.productRtId_Boat;
    Product2 pontoon = [SELECT Id FROM Product2 WHERE Family = 'Pontoon' AND RecordTypeId = :boatRtId LIMIT 1];
    List<PricebookEntry> pontoon_pbes = [
      SELECT Id, Product2Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :pontoon.Id AND Pricebook2Id = :LGND_Constants.factoryPricebookId
    ];
    Product2 vHull = [SELECT Id FROM Product2 WHERE Family = 'Full Windshield' AND RecordTypeId = :boatRtId LIMIT 1];
    List<PricebookEntry> vhull_pbes = [
      SELECT Id, Product2Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :vHull.Id AND Pricebook2Id = :LGND_Constants.factoryPricebookId
    ];
    System.runAs(partnerUser) {
      Dealer_Order__c order = Factory_DealerOrder.createDealerOrder(partner);
      order.Is_Booking_Order__c = true;
      update order;
      List<AcctSeed__Project__c> pontoon_erps = Factory_ERPOrder.createPartnerBoatSales(partner, pontoon_pbes, 4);
      List<Dealer_Order_Line__c> pontoon_dols = Factory_DealerOrder.createDealerOrderLines(
        pontoon_erps,
        order,
        pontoon
      );
      List<AcctSeed__Project__c> vhull_erps = Factory_ERPOrder.createPartnerBoatSales(partner, vhull_pbes, 1);
      List<Dealer_Order_Line__c> vhull_dols = Factory_DealerOrder.createDealerOrderLines(vhull_erps, order, vHull);

      Test.startTest();
      PartnerProgram_Service service = new PartnerProgram_Service(new Set<Id>{ order.Id });
      service.checkAndApply();
      Test.stopTest();

      System.assertEquals(1, service.dealerOrderIds.size());
      System.assertEquals(1, service.dealerOrderMap.keySet().size());
      System.assertEquals(1, service.erpsByDealerOrder.keySet().size());
      for (Id key : service.erpsByDealerOrder.keySet()) {
        System.assertEquals(5, service.erpsByDealerOrder.get(key).size());
      }
    }
  }
}
