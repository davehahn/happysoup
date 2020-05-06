/**
 * Created by dave on 2020-05-01.
 */

public with sharing class PricebookEntry_Selector extends Application_Selector
{
  public PricebookEntry_Selector()
  {
    this.sObjectName = 'PricebookEntry';
    this.fields = new List<String>{
      'Id',
      'Pricebook2Id',
      'Pricebook2.Name',
      'Product2Id',
      'Product2.Name',
      'UnitPrice'
    };
  }

  public static List<PricebookEntry> allRetailEntriesByProductId( Set<Id> productIds )
  {
    Id retailPdId = LGND_Constants.retailPricebookId;
    PricebookEntry_Selector selector = new PricebookEntry_Selector();
    selector
      .addWhere( 'Pricebook2Id = \'' + retailPdId + '\'')
      .addWhere( whereInClauseBuilder(
        'Product2Id',
        (Set<String>)JSON.deserialize( JSON.serialize(productIds), Set<String>.class)
      ) );
    return (List<PricebookEntry>)selector.query();
  }
}