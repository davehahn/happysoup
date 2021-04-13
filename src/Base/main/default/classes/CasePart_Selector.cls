/**
 * Created by dave on 2021-02-26.
 */

public virtual class CasePart_Selector extends Application_Selector
{

  private final List<String> defaultFields = new List<String>
  {
    'Id',
    'Name',
    'Inventory_Product__c',
    'Material__c',
    'Order_Quantity__c',
    'Pricebook_ID__c',
    'Product__c',
    'Product__r.Name',
    'Product_Code__c',
    'Purchase_Order_Line__c',
    'Purchase_Order_Line__r.deliverDate__c',
    'Quantity__c',
    'Total_Price__c',
    'Unit_Price__c'
  };

  public CasePart_Selector()
  {
    this.sObjectName = 'Case_Part__c';
    this.fields = defaultFields;
  }

  public static List<Case_Part__c> allByIds( List<Id> ids )
  {
    return new CasePart_Selector()
      .addWhereIdIn( ids )
      .query();
  }
}
