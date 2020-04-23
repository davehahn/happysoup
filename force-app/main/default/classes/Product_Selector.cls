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
      'Description'
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
}