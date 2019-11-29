@isTest
public class Factory_QuoteLineItem {

  public static QuoteLineItem buildLineItem( PricebookEntry pbe,
                                             Id quoteId,
                                             Integer quantity,
                                             Id parentProductId )
  {
    return buildLineItem( pbe.Id,
                          quoteId,
                          pbe.UnitPrice,
                          quantity,
                          parentProductId );
  }

  public static QuoteLineItem buildLineItem( Id pbeId,
                                             Id quoteId,
                                             Decimal price,
                                             Integer quantity,
                                             Id parentProductId )
  {
    return new QuoteLineItem(
      QuoteId = quoteId,
      PricebookEntryId = pbeId,
      UnitPrice = price,
      Quantity = quantity,
      ParentProductId__c = parentProductId
    );
  }
}