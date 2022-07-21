/**
 * Created by dave on 2020-05-04.
 */

public with sharing class ProductUpgrade_Selector extends Application_Selector {
  public ProductUpgrade_Selector() {
    this.sObjectName = 'Product_Upgrade__c';
    this.fields = new List<String>{ 'From_Product__c', 'To_Product__c', 'To_Product__r.Name' };
  }

  public static List<Product_Upgrade__c> allUpgradesByStandardIdsWithRetailCost(
    Set<Id> standardIds,
    Set<Id> upgradeIds
  ) {
    Id retailPbId = LGND_Constants.retailPricebookId;
    ProductUpgrade_Selector selector = new ProductUpgrade_Selector();
    selector
      .addChildQuery('(SELECT Cost__c FROM Product_Upgrade_Costs__r WHERE Price_Book__c = \'' + retailPbId + '\')')
      .addWhere(whereInClauseBuilder('From_Product__c', standardIds))
      .addWhere(whereInClauseBuilder('To_Product__c', upgradeIds))
      .addWhere('To_Product__r.IsActive = true');
    return (List<Product_Upgrade__c>) selector.query();
  }
}
