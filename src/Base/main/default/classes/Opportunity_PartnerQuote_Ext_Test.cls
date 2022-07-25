@isTest
private class Opportunity_PartnerQuote_Ext_Test {
  static Quote quot;
  static Opportunity opp;
  static AcctSeed__Accounting_Variable__c ontarioTaxZone;
  static Account dealer;
  static Account customer;
  static User partner;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Id retailPbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    Account dealer = Factory_Account.insertDealerAccounts(1)[0];
    Factory_User.createPartnerUser(dealer);
  }

  public static void initDealerAndPartnerUser() {
    dealer = [
      SELECT Id, Name, RecordTypeId, Type
      FROM Account
      WHERE RecordType.Name = 'Dealer' AND Is_Internal__c = FALSE
      LIMIT 1
    ];
    dealer.BillingState = 'Ontario';
    dealer.BillingCountry = 'Canada';
    update dealer;
    partner = [SELECT Id, Name FROM User WHERE AccountId = :dealer.Id LIMIT 1];
  }

  private static void init() {
    Id retailPbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    initDealerAndPartnerUser();
    ontarioTaxZone = [
      SELECT Id, Name, Tax_is_Harmonized__c, Tax_Rate_Provincial__c, Tax_Rate_Retail__c
      FROM AcctSeed__Accounting_Variable__c
      WHERE AcctSeed__Type__c = 'GL Account Variable 3' AND Name = 'Ontario'
      LIMIT 1
    ];
    System.runAs(partner) {
      customer = Factory_Account.insertCustomerAccounts(1)[0];
      opp = Factory_Opportunity.insertOpportunity(customer, retailPbId);
      quot = Factory_Quote.insertQuoteForBoat(opp);
    }
  }

  @isTest
  static void constructor_Test() {
    init();
    System.runAs(partner) {
      Test.startTest();
      PageReference pageRef = Page.Opportunity_PartnerQuote;
      pageRef.getParameters().put('quoteId', quot.Id);
      Test.setCurrentPage(pageRef);
      Opportunity_PartnerQuote_Ext qExt = new Opportunity_PartnerQuote_Ext();
      Test.stopTest();
      System.assertEquals(dealer.Id, qExt.partner.Id);
      System.assertEquals(customer.Id, qExt.customer.Id);
    }
  }
}
