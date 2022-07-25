/**
 * Created by Tim on 2021-09-17.
 */

public with sharing class SerialNumber_Selector extends Application_Selector {
  public SerialNumber_Selector() {
    this.sObjectName = 'GMBLASERP__Serial_Number__c';
    this.fields = new List<String>{
      'Id',
      'Location__c',
      'Name',
      'Model_Year__c',
      'GMBLASERP__Product__c',
      'GMBLASERP__Lot__c',
      'GMBLASERP__Inventory_Balance__c',
      'Product_Name__c',
      'Product_Record_Type__c',
      'Status__c',
      'Description__c',
      'Description_Used__c',
      'RetailSalePrice__c',
      'List_on_Retail_Website__c',
      'Default_Gallery_Image__c',
      'Legend_Gallery_Image__c'
    };
  }

  public static GMBLASERP__Serial_Number__c getSerialNumber(String recordId) {
    SerialNumber_Selector selector = new SerialNumber_Selector();
    selector.addWhere('Id = \'' + recordId + '\'');
    List<Sobject> results = selector.query();
    if (results.size() > 0)
      return (GMBLASERP__Serial_Number__c) results[0];
    return null;
  }
}
