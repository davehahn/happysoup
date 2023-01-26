/**
 * Created by dave on 2023-01-21.
 */

public with sharing class CPQ_InsuranceSelector_Controller {
  @AuraEnabled
  public static String init(String recordId, String cacheBypass) {
    System.debug('Insurance init');
    return JSON.serialize(new BusinessOffice_Controller.InsuranceInitWrapper(recordId));
  }

  @AuraEnabled(Cacheable=true)
  public static String fetchPlanItems(String planId, String pricebookId, String taxZoneId) {
    List<InsurancePlanWrapper> result = new List<InsurancePlanWrapper>();
    Map<String, List<InsuranceProduct>> groupedInsuranceProducts = new Map<String, List<InsuranceProduct>>();
    List<InsuranceProduct> insProds = new List<InsuranceProduct>();
    Set<Id> prodIds = new Set<Id>();
    for (PricebookEntry pbe : getInsurancePbesByPlan(planId, pricebookId)) {
      prodIds.add(pbe.Product2Id);
      insProds.add(new InsuranceProduct(pbe));
    }
    Map<Id, Product2> productMap = getProductAndRates(prodIds, taxZoneId);
    for (InsuranceProduct ip : insProds) {
      if (productMap.containsKey(ip.Id)) {
        ip.rates = productMap.get(ip.Id).Insurance_Rates__r;
      }
      if (!groupedInsuranceProducts.containsKey(ip.Family)) {
        groupedInsuranceProducts.put(ip.Family, new List<InsuranceProduct>());
      }
      groupedInsuranceProducts.get(ip.Family).add(ip);
    }
    for (String groupName : groupedInsuranceProducts.keySet()) {
      result.add(new InsurancePlanWrapper(groupName, groupedInsuranceProducts.get(groupName)));
    }
    return JSON.serialize(result);
  }

  @AuraEnabled(Cacheable=true)
  public static String fetchInsurancePlanItem(String productId, String taxZoneId) {
    return BusinessOffice_Controller.fetchInsurancePlanItem(productId, taxZoneId);
  }

  private static List<PricebookEntry> getInsurancePbesByPlan(String planId, String pricebookId) {
    return [
      SELECT Id, Product2.Name, Product2.Is_Residual_Insurance__c, Product2Id, Product2.Family
      FROM PricebookEntry
      WHERE Pricebook2Id = :pricebookId AND Product2.InsurancePlan__c = :planId
    ];
  }

  private static Map<Id, Product2> getProductAndRates(Set<Id> productIds, String taxZoneId) {
    return new Map<Id, Product2>(
      [
        SELECT
          Id,
          (
            SELECT
              Id,
              Single__c,
              Joint__c,
              Joint_Factored_Result__c,
              Lower_Term__c,
              Upper_Term__c,
              Lower_Finance_Term__c,
              Upper_Finance_Term__c
            FROM Insurance_Rates__r
            WHERE Tax_Zone__c = :taxZoneId
          )
        FROM Product2
        WHERE Id IN :productIds
      ]
    );
  }

  public class insurancePlanWrapper {
    public String groupName { get; set; }
    public String key { get; set; }
    public List<InsuranceProduct> planItems { get; set; }

    public insurancePlanWrapper(String name, List<InsuranceProduct> items) {
      this.key = LGND_Utilities.generateRandomString(8);
      this.groupName = name;
      this.planItems = items;
    }
  }

  public class InsuranceProduct {
    @AuraEnabled
    public String Id { get; set; }
    @AuraEnabled
    public String Name { get; set; }
    @AuraEnabled
    public String PricebookEntryId { get; set; }
    @AuraEnabled
    public Boolean isResidual { get; set; }
    @AuraEnabled
    public String Family { get; set; }
    @AuraEnabled
    public List<Insurance_Rate__c> rates { get; set; }

    public InsuranceProduct(PricebookEntry pbe) {
      this.Id = pbe.Product2Id;
      this.Name = pbe.Product2.Name;
      this.PricebookEntryId = pbe.Id;
      this.isResidual = pbe.Product2.Is_Residual_Insurance__c;
      this.Family = pbe.Product2.Family;
      this.rates = new List<Insurance_Rate__c>();
    }
  }
}
