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

  public static List<PricebookEntry> allFactoryEntriesByProductId( Set<Id> productIds )
  {
    Id factoryPbId = LGND_Constants.factoryPricebookId;
    return new PricebookEntry_Selector()
      .addFields( new List<String>{'Product2.Rigging_Time__c'} )
      .addWhereIdInField( productIds, 'Product2Id' )
      .addWhere( 'Pricebook2Id = \'' + factoryPbId + '\'')
      .query();
  }
}