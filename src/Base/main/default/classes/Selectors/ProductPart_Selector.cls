/**
 * Created by dave on 2020-05-06.
 */

public with sharing class ProductPart_Selector extends Application_Selector
{


  public ProductPart_Selector()
  {
    this.sObjectName = 'AcctSeed__Product_Part__c';
    this.fields = new List<String>{
      'Id',
      'AcctSeed__Product__c',
      'AcctSeed__Product_Part__c',
      'AcctSeed__Product_Part__r.Name',
      'AcctSeed__Quantity__c'
    };
  }

  public static List<AcctSeed__Product_Part__c> allForPartKitsByParentIds( Set<Id> parentProductIds )
  {
    Id partRtId = LGND_Constants.productRtId_Part;
    ProductPart_Selector selector = new ProductPart_Selector();
    selector
      .addWhere( whereInClauseBuilder( 'AcctSeed__Product__c', parentProductIds ) )
      .addWhere( 'AcctSeed__Product__r.RecordTypeId = \'' + partRtId + '\'', 'AND' );
    return (List<AcctSeed__Product_Part__c>)selector.query();
  }
}