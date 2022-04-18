public with sharing class Opportunity_Quote_Builder_Controller {

  public class InitWrapper {
    public String url;
    public String syncedQuoteId;
    public String syncedQuoteName;
    public List<Quote> quotes;
    public Boolean isOutdated = false;

    public InitWrapper( String oppId )
    {
      this.url = String.valueof(System.URL.getSalesforceBaseURL().gethost());
      Set<Id> prodRTs = new Set<Id>{
        LGND_Constants.productRTId_Boat,
        LGND_Constants.productRTId_Motor,
        LGND_Constants.productRTId_Trailer,
        LGND_Constants.productRTId_TrollingMotor
      };
      Opportunity opp = [SELECT Id, Pricebook2Id, SyncedQuoteId, SyncedQuote.Name FROM Opportunity WHERE Id =:oppId];
      this.syncedQuoteId = opp.SyncedQuoteId;
      this.syncedQuoteName = opp.SyncedQuote.Name;
      this.quotes = [SELECT Id,
                            Name,
                            Deposit__c,
                            Grand_Total__c,
                            Tax_Amount_Total__c,
                            Finance_Ammortization__c,
                            Finance_Annual_Interest__c,
                            Finance_Term__c,
                            GL_Account_Variable_3__c,
                      ( SELECT Id,
                               Product2.Name
                        FROM QuoteLineItems
                        WHERE Product2.RecordTypeId IN :prodRTs
                        ORDER BY Product2.RecordType.Name )
                     FROM Quote
                     WHERE OpportunityId = :oppId
                     ORDER BY IsSyncing DESC];
      this.isOutdated = opp.Pricebook2Id != LGND_Constants.retailPricebookId;
    }
  }

  @AuraEnabled
  public static String fetchQuotes( String oppId )
  {
    return JSON.serialize( new InitWrapper( oppId ) );
  }

  @AuraEnabled
  public static String syncQuoteToOpp( String quoteId, String oppId )
  {
    Opportunity opp = new Opportunity(
      Id = oppId,
      SyncedQuoteId = quoteId
    );
    upsert opp;
    return quoteId;
  }

  @AuraEnabled
  public static Quote updateQuote( String quoteJSON )
  {
    Quote q = (Quote)JSON.deserialize( quoteJSON, Quote.class );
    update q;
    return fetchQuote( q.Id );
  }

  private static Quote fetchQuote( Id qId )
  {
    return [SELECT Id,
                   Name,
                   Deposit__c,
                   Grand_Total__c,
                   Finance_Ammortization__c,
                   Finance_Annual_Interest__c,
                   Finance_Term__c
            FROM Quote
            WHERE Id = :qId];
  }

}