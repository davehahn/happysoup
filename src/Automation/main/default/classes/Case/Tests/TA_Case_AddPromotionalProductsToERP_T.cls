/**
 * Created by dave on 2022-01-10.
 */

@IsTest
private class TA_Case_AddPromotionalProductsToERP_T {
  private static Account dealer;
  private static List<Case> newList;
  private static List<Case> oldList;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    dealer = AccountFactory.buildDealerAccount('Testy McDealer');
    insert dealer;
    newList = new List<Case>();
    oldList = new List<Case>();
  }

  @IsTest
  static void TA_AfterUpdate() {
    init();
    Product2 boat = Factory_Product.createSerializedProducts('Boat', 'Pontoon', 1)[0];
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    AcctSeed__Project__c erp = Factory_ERPOrder.createPartnerBoatSales(dealer, new List<Product2>{ boat }, 1)[0];
    Promotion__c promo = Factory_Promotion.buildPromotions(1)[0];
    promo.Available_On__c = 'Reservation';
    insert promo;
    Promotion_Item__c promoItem = Factory_Promotion.buildPromoItem(promo, boat, 1000);
    insert promoItem;
    Promotion_Incentive_Product__c iProd = new Promotion_Incentive_Product__c(
      Product__c = part.Id,
      Promotion__c = promo.Id,
      Quantity__c = 1
    );
    insert iProd;
    Case promoCase = new Case(
      RecordTypeId = new Application_RecordType().getCaseRecordTypes().getPromotionId(),
      AccountId = dealer.Id,
      Promotion_Item__c = promoItem.Id,
      Promotion_Erp__c = erp.Id,
      Status = 'Pending documentation'
    );
    TriggerBase.bypass('Case');
    insert promoCase;
    TriggerBase.clearBypass('Case');
    promoCase = [SELECT Id, RecordTypeId, Promotion_ERP__c, PromotionId__c, Status FROM Case WHERE Id = :promoCase.Id];
    Case oldPromoCase = promoCase.clone(true, true, true, true);
    oldList.add(oldPromoCase);
    newList.add(promoCase);

    erp = [
      SELECT Id, (SELECT Id FROM AcctSeedERP__Project_Materials__r), (SELECT Id FROM AcctSeed__Project_Tasks__r)
      FROM AcctSeed__Project__c
      WHERE Id = :erp.Id
    ];

    System.assertEquals(1, erp.AcctSeedERP__Project_Materials__r.size());
    System.assertEquals(1, erp.AcctSeed__Project_Tasks__r.size());

    Test.startTest();
    newList[0].Status = 'Complete';
    new TA_Case_AddPromotionalProductsToERP().afterupdate(newList, oldList);
    Test.stopTest();

    erp = [
      SELECT Id, (SELECT Id FROM AcctSeedERP__Project_Materials__r), (SELECT Id FROM AcctSeed__Project_Tasks__r)
      FROM AcctSeed__Project__c
      WHERE Id = :erp.Id
    ];

    System.assertEquals(2, erp.AcctSeedERP__Project_Materials__r.size());
    System.assertEquals(2, erp.AcctSeed__Project_Tasks__r.size());
  }
}
