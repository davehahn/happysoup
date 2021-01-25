@isTest
public class Factory_OpportunityLineItem {

  public static OpportunityLineItem buildLineItem( PricebookEntry pbe,
                                                   Id oppId,
                                                   Integer quantity,
                                                   Id parentProductId )
  {
    return buildLineItem( pbe.Id,
                          oppId,
                          pbe.UnitPrice,
                          quantity,
                          parentProductId );
  }

  public static OpportunityLineItem buildLineItem( Id relatedId,
                                                   Id oppId,
                                                   Decimal price,
                                                   Integer quantity,
                                                   Id parentProductId )
  {
    OpportunityLineItem oli = new OpportunityLineItem(
      OpportunityId = oppId,
      UnitPrice = price,
      Quantity = quantity,
      ParentProductId__c = parentProductId
    );
    String relatedObjectType = LGND_Utilities.sObjectNameFromId(relatedId);
    if( relatedObjectType == 'PriceBookEntry' )
    {
      oli.PricebookEntryId = relatedId;
    }
    if( relatedObjectType == 'Product2' )
    {
      oli.Product2Id = relatedId;
    }
    return oli;
  }
}