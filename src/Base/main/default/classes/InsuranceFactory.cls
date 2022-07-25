@isTest
public with sharing class InsuranceFactory {
  public static List<InsurancePlan__c> insertInsurancePlansWithItems(Integer planCount) {
    List<InsurancePlan__c> plans = buildPlans(planCount);
    insert plans;
    //List<InsurancePlanItem__c> planItems = buildPlanItems(plans);
    Product2[] insuranceProducts = buildInsuraceProducts(plans);
    //insert planItems;
    insert insuranceProducts;
    makeStandardPricebookEntries(insuranceProducts);
    Map<Id, InsurancePlan__c> planMap = new Map<Id, InsurancePlan__c>(plans);

    return [
      SELECT Id, Name, Profit_Percent__c, (SELECT Id, Family, Name FROM InsuranceProducts__r)
      FROM InsurancePlan__c
      WHERE Id IN :planMap.keySet()
    ];
  }

  public static List<InsurancePlan__c> buildPlans(Integer planCount) {
    List<InsurancePlan__c> plans = new List<InsurancePlan__c>();
    for (Integer i = 0; i < planCount; i++) {
      plans.add(new InsurancePlan__c(Name = 'Insurance Plan - ' + i, Profit_Percent__c = 52));
    }
    return plans;
  }

  public static List<InsurancePLanItem__c> buildPlanItems(List<InsurancePlan__c> plans) {
    List<InsurancePLanItem__c> items = new List<InsurancePLanItem__c>();
    Map<String, Set<String>> planItemsMap = new Map<String, Set<String>>();
    planItemsMap.put(
      'Critical Illness Coverage',
      new Set<String>{ 'Critical Illness Decreasing Term Life', 'Critical Illness Residual Value' }
    );
    planItemsMap.put('Disability Insurance Coverage', new Set<String>{ '7 Day', '14 Day', '30 Day' });
    for (InsurancePLan__c plan : plans) {
      for (String cat : planItemsMap.keySet()) {
        for (String itemName : planItemsMap.get(cat)) {
          items.add(new InsurancePlanItem__c(InsurancePlan__c = plan.Id, Category__c = cat, Name = itemName));
        }
      }
    }

    return items;
  }

  private static List<Product2> buildInsuraceProducts(List<InsurancePlan__c> plans) {
    Id insRTid = LGND_Utilities.recordTypeIdFromName('Product2', 'Insurance');
    List<Product2> insuranceProducts = new List<Product2>();
    Map<String, Set<String>> planItemsMap = new Map<String, Set<String>>();
    planItemsMap.put(
      'Critical Illness Coverage',
      new Set<String>{ 'Critical Illness Decreasing Term Life', 'Critical Illness Residual Value' }
    );
    planItemsMap.put('Disability Insurance Coverage', new Set<String>{ '7 Day', '14 Day', '30 Day' });

    for (InsurancePlan__c plan : plans) {
      for (String cat : planItemsMap.keySet()) {
        for (String itemName : planItemsMap.get(cat)) {
          insuranceProducts.add(
            new Product2(
              Name = itemName,
              Family = cat,
              recordTYpeId = insRTid,
              InsurancePlan__c = plan.Id,
              isActive = true
            )
          );
        }
      }
    }
    return insuranceProducts;
  }

  private static void makeStandardPricebookEntries(List<Product2> items) {
    Pricebook2 stdPb = [SELECT Id FROM Pricebook2 WHERE isStandard = TRUE AND isActive = TRUE LIMIT 1];
    PricebookEntry[] entries = new List<PricebookEntry>();
    for (Product2 p : items) {
      entries.add(new PricebookEntry(Product2Id = p.Id, Pricebook2Id = stdPb.Id, UnitPrice = 0, isActive = true));
    }
    insert entries;
  }
}
