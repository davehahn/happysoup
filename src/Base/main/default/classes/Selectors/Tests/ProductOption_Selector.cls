/**
 * Created by dave on 2020-05-04.
 */

public with sharing class ProductOption_Selector extends Application_Selector {
  public ProductOption_Selector() {
    this.sObjectName = 'Product_Option__c';
    this.fields = new List<String>{
      'Id',
      'From_Product__c',
      'From_Product__r.Name',
      'From_Product__r.RecordTypeId',
      'To_Product__c',
      'To_Product__r.Name',
      'Standard__c',
      'Maximum__c'
    };
  }

  public static List<Product_Option__c> allChildOptions_AvailableOnline(Set<Id> parentIds) {
    ProductOption_Selector selector = new ProductOption_Selector();
    selector.addWhere(whereInClauseBuilder('To_Product__c', parentIds)).addWhere('Available_Online__c= true');
    return (List<Product_Option__c>) selector.query();
  }
}
