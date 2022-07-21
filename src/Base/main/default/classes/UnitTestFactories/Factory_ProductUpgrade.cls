/**
 * Created by dave on 2020-05-11.
 */
@isTest
public class Factory_ProductUpgrade {
  public static List<Product_Upgrade__c> createUpgradesWithCostInPricebook(
    Id fromProductId,
    List<Product2> toProducts,
    Id pricebookId,
    Decimal cost
  ) {
    List<Product_Upgrade__c> upgrades = new List<Product_Upgrade__c>();
    for (Product2 p : toProducts) {
      upgrades.add(new Product_Upgrade__c(From_Product__c = fromProductId, To_Product__c = p.Id));
    }
    insert upgrades;
    List<Product_Upgrade_Cost__c> upgradeCosts = new List<Product_Upgrade_Cost__c>();
    for (Product_Upgrade__c pu : upgrades) {
      upgradeCosts.add(
        new Product_Upgrade_Cost__c(Product_Upgrade__c = pu.Id, Price_Book__c = pricebookId, Cost__c = cost)
      );
    }
    insert upgradeCosts;
    return upgrades;
  }
}
