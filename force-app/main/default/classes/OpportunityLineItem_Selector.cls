/**
 * Created by dave on 2021-01-13.
 */

public virtual class OpportunityLineItem_Selector extends Application_Selector
{

  private final List<String> defaultFields = new List<String>
  {
    'Id',
    'Description',
    'ListPrice',
    'Product2Id',
    'ParentProductId__c',
    'Product2.RecordTypeId',
    'Product2.Name',
    'Product2.Name_FR__c',
    'Product2.Family',
    'Quantity',
    'InsuranceCoverage__c',
    'Insurance_Rate__c',
    'UnitPrice'
  };

  public OpportunityLineItem_Selector()
  {
    this.sObjectName = 'OpportunityLineItem';
    this.fields = defaultFields;
  }
}