@isTest
private class Opportunity_Quote_Builder_Ctrl_Test {

  static Quote quot;
  static Opportunity opp;

	@testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Id retailPbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    Account cust = Factory_Account.insertCustomerAccounts(1)[0];
    Opportunity opp = Factory_Opportunity.insertOpportunity( cust, retailPbId );
    Factory_Quote.insertQuoteForBoat( opp );
    //Account dealer = Factory_Account.insertDealerAccounts( 1 )[0];
    //Factory_User.createPartnerUser( dealer );
  }

  private static void init()
  {
    opp = [ SELECT Id,
                   Name,
                   AccountId,
                   Pricebook2Id,
                   StageName,
                   CloseDate
            FROM Opportunity
            LIMIT 1];
    quot = [SELECT Id,
                   OpportunityId,
                   IsSyncing,
                   Pricebook2Id,
                   Name
            FROM Quote
            WHERE OpportunityId = :opp.Id
            LIMIT 1];
  }

  @isTest
  static void fetchQuotes_Test()
  {
    init();
    Test.startTest();
    String jsonResult = Opportunity_Quote_Builder_Controller.fetchQuotes( opp.Id );
    Opportunity_Quote_Builder_Controller.InitWrapper result =
      (Opportunity_Quote_Builder_Controller.InitWrapper)JSON.deserialize(
        jsonResult, Opportunity_Quote_Builder_Controller.InitWrapper.class);
    Test.stopTest();
    System.assertEquals( result.url,
                         String.valueof(System.URL.getSalesforceBaseURL().gethost()) );
    System.assertEquals( null, result.syncedQuoteId );
    System.assertEquals( null, result.syncedQuoteName );
    System.assertEquals( 1, result.quotes.size() );
  }

  @isTest
  static void syncQuoteToOpp_Test()
  {
    init();
    System.assertEquals( false, quot.IsSyncing );
    String qId =  Opportunity_Quote_Builder_Controller.syncQuoteToOpp( quot.Id, opp.Id );
    Quote q = [SELECT Id, IsSyncing FROM Quote WHERE Id = :qId];
    System.assertEquals( true, q.IsSyncing );
  }

  @isTest
  static void updateQuote_Test()
  {
    init();
    String newName = 'This New Name';
    Map<String, String> qMap = new Map<String, String>{
      'Id' => String.valueOf( quot.Id ),
      'Name' => newName
    };
    Quote nQuot = Opportunity_Quote_Builder_Controller.updateQuote( JSON.serialize(qMap) );
    System.assertEquals( newName, nQuot.Name );
  }

}