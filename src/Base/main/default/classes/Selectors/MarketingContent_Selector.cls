/**
 * Created by dave on 2020-05-05.
 */

public with sharing class MarketingContent_Selector extends Application_Selector
{

  public MarketingContent_Selector()
  {
    this.sObjectName = 'Marketing_Content__c';
    this.fields = new List<String>{
      'Id',
      'Product__c',
      'Product_Option__c',
      'Label__c',
      'Content__c'
    };
  }

  public static List<Marketing_Content__c> allByProductAndProductOption( Set<Id> ids )
  {
    MarketingContent_Selector selector = new MarketingContent_Selector();
    selector
      .addWhere( whereInClauseBuilder( 'Product__c', ids ) )
      .addWHere( whereInClauseBuilder( 'Product_Option__c', ids ), 'OR' );
    return (List<Marketing_Content__c>)selector.query();
  }
}