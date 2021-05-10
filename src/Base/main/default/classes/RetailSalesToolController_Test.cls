@isTest
private class RetailSalesToolController_Test {

  static User salesUser;
  static List<Account> accounts = new List<Account>();
  static List<Account> dealerAccounts = new List<Account>();
  static List<Lead> leads = new List<Lead>();
  static List<Schema.PicklistEntry> languageEntries;
  static List<Schema.PicklistEntry> relationshipEntries;
  static List<Schema.PicklistEntry> hobbyEntries;
  static List<Schema.PicklistEntry> emotiveEntries;
  static List<Schema.PicklistEntry> animalEntries;
  static List<Schema.PicklistEntry> towVehicleEntries;
  static List<Schema.PicklistEntry> preferredLanguages;
  static String leadSource {
    get {
      Schema.DescribeFieldResult fieldResult = Opportunity.LeadSource.getDescribe();
      List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
      return ple[0].getValue();
    }
  }

  private static void init() {
    salesUser = User_TestFactory.newUser( 'Sales', 'Tester', 'Legend Standard User - New');
    insert salesUser;
    accounts.add( AccountFactory.buildPersonAccount('Dave', 'Hahnzzzwwwrrr') );
    accounts.add( AccountFactory.buildPersonAccount('Doug', 'Fudge') );
    accounts.add( AccountFactory.buildPersonAccount('Sean', 'McKenty') );
    accounts.add( AccountFactory.buildPersonAccount('Julie', 'Hahnzzzwwwrrr') );
    insert accounts;

    dealerAccounts.add( AccountFactory.buildDealerAccount('This is an awesome company') );
    dealerAccounts.add( AccountFactory.buildDealerAccount('Another Cool Business') );
    insert dealerAccounts;

    leads.add( new Lead(FirstName = 'Evan', LastName='Hahnzzzwwwrrr') );
    leads.add( new Lead(FirstName = 'Adam', LastName='Hahnzzzwwwrrr') );
    leads.add( new Lead(FirstName = 'Erica', LastName='Hahnzzzwwwrrr') );
    leads.add( new Lead(FirstName = 'Hulk', LastName='Hogan') );
    insert leads;

    languageEntries = Account.Preferred_Language__c.getDescribe().getPicklistValues();
    relationshipEntries = Account.Relationship_Status__c.getDescribe().getPicklistValues();
    hobbyEntries = Account.Hobbies__c.getDescribe().getPicklistValues();
    emotiveEntries = Account.Emotional_Motivation__c.getDescribe().getPicklistValues();
    animalEntries = Account.Animals__c.getDescribe().getPicklistValues();
    towVehicleEntries = Account.Tow_Vehicle__c.getDescribe().getPicklistValues();
    preferredLanguages = Account.Preferred_Language__c.getDescribe().getPicklistValues();

    OpportunityTriggerHandler.disableAutoPricebookSet = true;
  }

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @isTest static void getSelectOptionsTest()
  {
    init();
    RetailSalesToolController rstc = new RetailSalesToolController();
    List<SelectOption> languageOptions = rstc.getLanguageOptions();
    List<SelectOption> relationshipOptions = rstc.getRelationshipStatusOptions();
    List<SelectOption> hobbyOptions = rstc.getHobbyOptions();
    List<SelectOption> emotiveOptions = rstc.getEmotionalMotivationOptions();
    List<SelectOption> animalOptions = rstc.getAnimalOptions();
    List<SelectOption> towVehicleOptions = rstc.getTowVehicleOptions();

    System.assertEquals( preferredLanguages.size(), languageOptions.size() );
    System.assertEquals( languageEntries.size(), languageOptions.size() );
    System.assertEquals( relationshipEntries.size(), relationshipOptions.size() - 1 );
    System.assertEquals( hobbyEntries.size(), hobbyOptions.size() );
    System.assertEquals( emotiveEntries.size(), emotiveOptions.size() );
    System.assertEquals( animalEntries.size(), animalOptions.size() );
    System.assertEquals( towVehicleEntries.size(), towVehicleOptions.size() - 1 );
  }

  @isTest static void customer_search_Test()
  {
    init();
    Map<String, List<Map<String, String>>> searchResults;

    searchResults = RetailSalesToolController.customerSearch('somelongrandomstringthatwillnotbefound');
    System.assertEquals(null, searchResults);

    searchResults = RetailSalesToolController.customerSearch('Hahnzzzwwwrrr');
    System.assertEquals(2, searchResults.keyset().size() );
    System.assertEquals(2, searchResults.get('Accounts').size() );
    System.assertEquals(3, searchResults.get('Leads').size() );
  }

  @isTest static void dealerSearch_Test()
  {
    init();
    List<RetailSalesToolController.DealerWrapper> dealers = RetailSalesToolController.dealerSearch('Another');
    System.assertEquals( 1, dealers.size() );
  }

  @isTest static void customer_select_Test()
  {
    init();
    Id acctId = accounts[1].Id;
    Id leadId = leads[3].Id;
    RetailSalesToolController.CustomerWrapper acctResult = RetailSalesToolController.selectCustomer(acctId);
    RetailSalesToolController.CustomerWrapper leadResult = RetailSalesToolController.selectCustomer(leadId);

    System.assertEquals( Account.sObjectType, Id.valueOf( acctResult.Id ).getSObjectType() );
    System.assertEquals( 'Doug', acctResult.FirstName );
    System.assertEquals( Lead.sObjectType, Id.valueOf( leadResult.Id ).getSObjectType() );
    System.assertEquals( 'Hulk', leadResult.FirstName );
  }

  @isTest static void create_sale_from_account_Test()
  {
    init();
    Test.startTest();
    //lets create an opportunity for the account we are going to use
    Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Opportunity;
    Map<String,Schema.RecordTypeInfo> OpportunityRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
    Id retailRTId = OpportunityRecordTypeInfo.get('Retail').getRecordTypeId();
    Opportunity opp = new Opportunity( AccountId = accounts[0].Id,
                                       Name = accounts[0].FirstName + ' ' + accounts[0].LastName,
                                       StageName = 'Quoting',
                                       CloseDate = Date.today(),
                                       RecordTypeId = retailRTId );
    insert opp;
    System.assertEquals(accounts[0].Id, opp.AccountId);
    Map<String, String> customerData = new Map<String, String>();
    customerData.put('Id', accounts[0].Id);
    customerData.put('FirstName', accounts[0].FirstName );
    customerData.put('LastName', accounts[0].LastName );
    customerData.put('Email', 'this_is_a@test.net');
    customerData.put('TowVehicle', towVehicleEntries[0].getValue() );

    Map<String,String> oppData = new Map<String,String>();
    oppData.put('oppLeadSource', leadSource);
    oppData.put('oppCampaignId', '');
    oppData.put('oppCloseDate', '31/08/2014');

    RetailSalesToolController.createSale( JSON.serialize(customerData), JSON.serialize(oppData) );
    Account tAcct = [SELECT Id, PersonEmail, Tow_Vehicle__c FROM Account WHERE Id = :accounts[0].Id];
    Opportunity[] opps = [SELECT Id FROM Opportunity WHERE AccountId = :accounts[0].Id];
    Test.stopTest();

    System.assertEquals(2, opps.size() );
    System.assertEquals(customerData.get('Email'), tAcct.PersonEmail);
    System.assertEquals( customerData.get('TowVehicle'), tAcct.Tow_Vehicle__c );

  }

  @isTest static void create_sale_from_lead_Test()
  {
    init();
    System.debug('create sale from lead test');
    system.runAs(salesUser) {
      Test.startTest();
      Map<String, String> customerData = new Map<String, String>();
      customerData.put('Id', leads[0].Id);
      customerData.put('FirstName', leads[0].FirstName );
      customerData.put('LastName', leads[0].LastName );
      customerData.put('Email', 'this_is_a_too@test.net');
      customerData.put('TowVehicle', towVehicleEntries[0].getValue() );
      customerData.put('PreferredLanguage', languageEntries[1].getValue() );

      Map<String,String> oppData = new Map<String,String>();
      oppData.put('oppLeadSource', leadSource);
      oppData.put('oppCampaignId', '');
      oppData.put('oppCloseDate', Datetime.now().addDays(20).format('dd/MM/yyyy') );

      RetailSalesToolController.createSale( JSON.serialize(customerData), JSON.serialize(oppData) );
      Lead tLead = [SELECT Id, FirstName, LastName, Email, OwnerId, Preferred_Language__c, isConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :leads[0].Id];
      Account tAcct = [SELECT Id, FirstName, LastName, PersonEmail, Tow_Vehicle__c, Preferred_Language__c, OwnerId FROM Account WHERE Id = :tLead.ConvertedAccountId];
      Opportunity[] opps = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :tLead.ConvertedOpportunityId];
      Test.stopTest();

      System.assert( tLead.isConverted );
      System.assertNotEquals( tLead.OwnerId, salesUser.Id);
      System.assertEquals( opps[0].OwnerId, salesUser.Id);
      System.assertEquals( tAcct.OwnerId, salesUser.Id);
      System.assertEquals(customerData.get('Email'), tLead.Email);
      System.assertNotEquals(null, tLead.ConvertedAccountId );
      System.assertNotEquals(null, tLead.ConvertedOpportunityId );
      System.assertEquals(tLead.FirstName, tAcct.FirstName);
      System.assertEquals(tLead.LastName, tAcct.LastName);
      System.assertEquals(tLead.Email, tAcct.PersonEmail);
      System.assertEquals(tLead.Preferred_Language__c, tAcct.Preferred_Language__c );
      System.assertEquals( customerData.get('TowVehicle'), tAcct.Tow_Vehicle__c );
      System.assertEquals(1, opps.size() );
    }
  }

  @isTest static void create_new_sale_Test()
  {
    init();
    Test.startTest();
    Map<String, String> customerData = new Map<String, String>();
    customerData.put('FirstName', 'NewFirstName' );
    customerData.put('LastName', 'NewLastName' );
    customerData.put('Email', 'newRecordCreated@test.net');
    customerData.put('PreferredLanguage', languageEntries[1].getValue() );

    Map<String,String> oppData = new Map<String,String>();
    oppData.put('oppLeadSource', leadSource);
    oppData.put('oppCampaignId', '');
    oppData.put('oppCloseDate', Datetime.now().addDays(20).format('dd/MM/yyyy') );

    RetailSalesToolController.createSale( JSON.serialize(customerData), JSON.serialize(oppData) );
    Lead tLead = [SELECT Id, FirstName, LastName, Email, isConverted, Preferred_Language__c, ConvertedAccountId, ConvertedOpportunityId
                  FROM Lead
                  WHERE FirstName = :customerData.get('FirstName')
                  AND LastName = :customerData.get('LastName')];
    Account tAcct = [SELECT Id, FirstName, LastName, PersonEmail, Preferred_Language__c
                     FROM Account
                     WHERE Id = :tLead.ConvertedAccountId];
    Opportunity[] opps = [SELECT Id FROM Opportunity WHERE Id = :tLead.ConvertedOpportunityId];
    Test.stopTest();

    System.assert( tLead.isConverted );
    System.assertEquals(customerData.get('Email').toLowerCase(), tLead.Email);
    System.assertNotEquals(null, tLead.ConvertedAccountId );
    System.assertNotEquals(null, tLead.ConvertedOpportunityId );
    System.assertEquals(tLead.FirstName, tAcct.FirstName);
    System.assertEquals(tLead.LastName, tAcct.LastName);
    System.assertEquals(tLead.Email, tAcct.PersonEmail);
    System.assertEquals( tLead.Preferred_Language__c, tAcct.Preferred_Language__c);
    System.assertEquals(1, opps.size() );
  }

  @isTest static void helperMethods_Test()
  {
    init();
    RetailSalesToolController tool = new RetailSalesToolController();
    tool.getPriceBookOptions();
    tool.getPartnerPriceBookOptions();
    //System.assert(tool.getCampaignOptions().size() > 0);
    Date today = Date.today();
    Integer pYear = today.month() > 9 ? today.year() + 1 : today.year();
    System.assertEquals( String.valueOf( pYear ), RetailSalesToolController.getProductYear(null) );
  }

}