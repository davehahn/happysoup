/**
 * Created by dave on 2020-05-07.
 */

public with sharing class ProductFeeMap_Selector extends Application_Selector
{

  public ProductFeeMap_Selector()
  {
    this.sObjectName = 'Product_Fee_Map__c';
    this.fields = new List<String>{
      'Fee_Product__c',
      'Parent_Product__c'
    };
  }

  public static List<Product_Fee_Map__c> allProductFeeMapsByParentProductId( Set<Id> parentProductIds )
  {
    ProductFeeMap_Selector selector = new ProductFeeMap_Selector();
    selector.addWhere( whereInClauseBuilder( 'Parent_Product__c', parentProductIds ) );
    return (List<Product_Fee_Map__c>)selector.query();
  }
}