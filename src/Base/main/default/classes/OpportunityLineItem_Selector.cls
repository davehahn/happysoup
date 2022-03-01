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
    'ParentProductId__r.RecordTypeId',
    'Product2.RecordTypeId',
    'Product2.RecordType.Name',
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

  public static List<OpportunityLineItem> selectAllByOpportunityId( Id oppId )
  {
    return new OpportunityLineItem_Selector()
      .addWhere( 'OpportunityId = \'' + oppId + '\'' )
      .query();
  }
}