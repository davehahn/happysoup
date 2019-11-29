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

  public static OpportunityLineItem buildLineItem( Id pbeId,
                                                   Id oppId,
                                                   Decimal price,
                                                   Integer quantity,
                                                   Id parentProductId )
  {
    return new OpportunityLineItem(
      OpportunityId = oppId,
      PricebookEntryId = pbeId,
      UnitPrice = price,
      Quantity = quantity,
      ParentProductId__c = parentProductId
    );
  }
}