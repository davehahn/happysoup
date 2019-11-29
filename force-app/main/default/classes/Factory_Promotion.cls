@isTest
public with sharing class Factory_Promotion {
	public static Promotion__c createPromotion(String name, DateTime startDate, DateTime endDate) {
		Promotion__c promo = new Promotion__c(
			Name = name,
			Start_Date__c = startDate,
			End_Date__c = endDate
		);
		insert promo;
		return promo;
	}

	public static Promotion_Item__c createPromoItem(Promotion__c promo, Product2 product, Decimal amount) {
		Promotion_Item__c item = new Promotion_Item__c(
			Promotion__c = promo.Id,
			Product__c = product.Id,
			Amount__c = amount
		);
		insert item;
		return item;
	}
}