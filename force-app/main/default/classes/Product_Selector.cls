/**
 * Created by dave on 2020-04-23.
 */

public with sharing class Product_Selector extends Application_Selector
{

  public Product_Selector()
  {
    this.sObjectName = 'Product2';
    this.fields = new List<String>{
      'Id',
      'Name',
      'Family',
      'RecordTypeId',
      'RecordType.Name',
      'ProductCode',
      'Description',
      'Default_Gallery_Image_Original__c'
    };
  }

  public static List<Product2> allBoatsAvailableForOnlineSale()
  {
    Id boatRtId = LGND_Constants.productRtId_Boat;
    Product_Selector selector = new Product_Selector();
    selector.addWhere('RecordTypeId = \'' + boatRtId + '\'')
      .addWhere('Available_Online__c = true');
    return (List<Product2>)selector.query();
  }

  public static List<Product2> allWithFullDetailsById( Set<Id> productIds )
  {
    Product_Selector selector = new Product_Selector();
    selector
      .addWhere( whereInClauseBuilder(
      'Id',
      (Set<String>)JSON.deserialize( JSON.serialize(productIds), Set<String>.class)
    ));
    return (List<Product2>)selector.query();
  }

  public static Product2 getOnlineBoat( String recordId )
  {
    Product_Selector selector = new Product_Selector();
    selector.addWhere('Id = \'' + recordId + '\'')
      .addChildQuery( '(SELECT From_Product__c, From_Product__r.Name, Standard__c, Maximum__c FROM To_Product_Options__r WHERE Available_Online__c = true)');
    List<Sobject> results = selector.query();
    return (Product2)results[0];
  }
}