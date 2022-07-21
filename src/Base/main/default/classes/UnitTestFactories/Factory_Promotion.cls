@isTest
public with sharing class Factory_Promotion {
  public static List<Promotion__c> buildPromotions(Integer count) {
    List<Promotion__c> promos = new List<Promotion__c>();
    DateTime sDate = DateTime.now().addMonths(-1);
    DateTime eDate = DateTime.now().addMonths(1);
    for (Integer i = 0; i < count; i++) {
      promos.add(buildPromotion('Test Promotion ' + String.valueOf(i), sDate, eDate));
    }
    return promos;
  }

  public static Promotion__c buildPromotion(String name, DateTime startDate, DateTime endDate) {
    return new Promotion__c(Name = name, Start_Date__c = startDate, End_Date__c = endDate);
  }

  public static Promotion__c createPromotion(String name, DateTime startDate, DateTime endDate) {
    Promotion__c promo = buildPromotion(name, startDate, endDate);
    insert promo;
    return promo;
  }

  public static Promotion_Item__c buildPromoItem(Promotion__c promo, Product2 product, Decimal amount) {
    return new Promotion_Item__c(Promotion__c = promo.Id, Product__c = product.Id, Amount__c = amount);
  }

  public static Promotion_Item__c createPromoItem(Promotion__c promo, Product2 product, Decimal amount) {
    Promotion_Item__c item = buildPromoItem(promo, product, amount);
    insert item;
    return item;
  }
}
