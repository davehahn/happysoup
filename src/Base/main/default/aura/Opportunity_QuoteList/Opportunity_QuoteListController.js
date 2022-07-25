({
  handleQuoteUpdated: function (component, event, helper) {
    var params = event.getParam("arguments"),
      updatedQuote = params.updatedQuote,
      quotes = component.get("v.quotes");

    for (let q of quotes) {
      if (q.Id === updatedQuote.Id) {
        q.Deposit__c = updatedQuote.Deposit__c;
        q.Grand_Total__c = updatedQuote.Grand_Total__c;
        q.Finance_Ammortization__c = updatedQuote.Finance_Ammortization__c;
        q.Finance_Annual_Interest__c = updatedQuote.Finance_Annual_Interest__c;
        q.Finance_Term__c = updatedQuote.Finance_Term__c;
        break;
      }
    }
    component.set("v.quotes", quotes);
  }
});
