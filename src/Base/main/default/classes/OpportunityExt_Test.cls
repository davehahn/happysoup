@isTest
private class OpportunityExt_Test {

  static Id rTId;

   //get the Id of the Person Account Record Type
  static {
      OpportunityTriggerHandler.disableAutoPricebookSet = true;
      Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Account;
      Map<String,Schema.RecordTypeInfo> AccountRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
      rTId = AccountRecordTypeInfo.get('Person Account').getRecordTypeId();
  }

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @isTest
  static void createOpportunityFromAccountTest() {

    Account a = new Account(FirstName= 'Test', LastName='User', RecordTypeId=rTId);
    insert a;
    // Tax_Class__c tc = new Tax_Class__c(Name = '31.4% Pi Tax', Percentage__c = 31.4);
    // insert tc;

    PageReference pageRef = Page.OpportunityForm;
    pageRef.getParameters().put('AccountId', a.Id);
    Test.setCurrentPageReference(pageRef);
    Opportunity opp = new Opportunity(
      CloseDate= Date.today(),
      StageName='Quoting'
      // Tax_Class__c=tc.Id
      );
    ApexPages.StandardController sc = new ApexPages.StandardController(opp);
    OpportunityExt ox = new OpportunityExt(sc);
    //SOME BS TO GET CODE COVERAGE
    System.assertEquals(false, ox.renderOtherDepositMethod );
    System.assertEquals('Build a Boat', ox.getBoatBuilderButtonText() );
    System.assertEquals(false, ox.getHasLineItems() );
    ox.getExcludedIds();
    ox.getProbabilityJSON();
    ox.getPageSubTitle();
    ox.depositMethodChanged();
    Account oppAccount = ox.account;

    System.assertEquals(oppAccount.Id, a.Id);
    System.assertEquals(ox.current_opportunity.AccountId, a.Id);

    ox.saveAndBuildBoat();

    Account account = [SELECT Id,
                        (SELECT Id FROM Opportunities)
                      FROM Account WHERE Id = :a.Id];

    System.assertEquals(1, account.Opportunities.size());

    //TEST SAVE ONLY FROM BOAT CONFIGURATOR FINALIZATION

    Opportunity reloadedOpp = [SELECT Id, Deposit__c FROM Opportunity WHERE Id = :account.Opportunities[0].Id];
    sc = new ApexPages.StandardController(reloadedOpp);
    ox = new OpportunityExt(sc);

    ox.current_opportunity.account.PersonEmail = 'thething@net.com';
    ox.current_opportunity.Deposit__c = 1000;
    ox.current_opportunity.Deposit_Method__c = 'Visa';

    PageReference pr = ox.finalSave();

    System.assertEquals(new PageReference('/' + reloadedOpp.Id).getUrl(), pr.getUrl());

    reloadedOpp = [SELECT Id, Deposit__c, Account.PersonEmail FROM Opportunity WHERE Id = :account.Opportunities[0].Id];

    System.assertEquals('thething@net.com', reloadedOpp.Account.PersonEmail);
    System.assertEquals(1000, reloadedOpp.Deposit__c);

   //TEST SAVE AND SUBMIT FOR APPROVAL FROM BOAT CONFIGURATOR FINALIZATION
    reloadedOpp = [SELECT Id, Deposit__c FROM Opportunity WHERE Id = :account.Opportunities[0].Id];
    sc = new ApexPages.StandardController(reloadedOpp);
    ox = new OpportunityExt(sc);

    ox.current_opportunity.account.Drivers_License__c = 'vhr4534jkb345';
    ox.current_opportunity.account.Phone = '705-39-4431';
    ox.current_opportunity.account.PersonMobilePhone = '705-905-9876';
    ox.current_opportunity.account.PersonBirthdate = Date.today();
    ox.current_opportunity.account.Sex__c = 'Male';
    ox.current_opportunity.account.BillingStreet = 'Viking Rd';
    ox.current_opportunity.account.BillingCountryCode = 'CA';
    ox.current_opportunity.account.BillingStateCode = 'ON';
    ox.current_opportunity.account.BillingCity = 'Orillia';
    ox.current_opportunity.account.BillingPostalCode = 'N8A4L1';

    ox.current_opportunity.Delivery_Date__c = Date.today();
    ox.current_opportunity.Pickup_Location__c = 'Barrie - Pick-up';

    ox.finalSaveAndSubmit();
   // ox.buildInvoiceAndSubmit();
    reloadedOpp = [SELECT Id, StageName, (SELECT Id From ProcessInstances) FROM Opportunity WHERE Id = :account.Opportunities[0].Id];

    System.assertEquals(1, reloadedOpp.ProcessInstances.size() );
    System.assertEquals('Sales Manager Approval Pending', reloadedOpp.StageName);

    ox.httpStage = 'Picked Up / Won';
    ox.httpUpdateStage();

    reloadedOpp = [SELECT Id, StageNAme, Probability FROM Opportunity WHERE Id = :account.Opportunities[0].Id];

    System.assertEquals('Picked Up / Won', reloadedOpp.StageName);
    System.assertEquals(100, Integer.valueOf(reloadedOpp.Probability));

  }

  @isTest
  static void createCoBuyerTest() {

     //set up setting so Opportunity Trigger will run
    //Legend_Settings__c ls = new Legend_Settings__c();
    //ls.TriggerEnable_OpportunityTrigger__c = true;
    //insert ls;

    Account a = new Account(FirstName= 'Test', LastName='User', RecordTypeId=rTId);
    insert a;

    Opportunity opp = new Opportunity(
      CloseDate= Date.today(),
      StageName='Quoting',
      AccountId = a.Id,
      Name='Test Opportunity'
      );

    insert opp;

    PageReference pageRef = Page.OpportunityCoBuyerForm;
    Test.setCurrentPageReference(pageRef);
    ApexPages.StandardController sc = new ApexPages.StandardController( opp );
    OpportunityExt oExt = new OpportunityExt(sc);

    System.assertEquals(1, oExt.previousOppContactIds.size() );

    oExt.cont.FirstName = 'test';
    oExt.cont.LastName ='Case';
    oExt.cont.Email='testcase@home.net';

    oExt.saveCoBuyer();

    List<OpportunityContactRole> ocrs = [Select Id ,Role FROM OpportunityContactRole WHERE OpportunityId = :opp.Id AND Role = 'Co-Buyer'];
    System.assertEquals(1, ocrs.size() );

    /* Now we will test adding another but with a found contact */

    Contact c = new Contact(FirstName ='Les', LastName='Claypool', Email='les@primusville.com');
    insert c;

    pageRef = Page.OpportunityCoBuyerForm;
    pageRef.getParameters().put('contactId', c.Id);
    Test.setCurrentPageReference(pageRef);
    sc = new ApexPages.StandardController( opp );
    oExt = new OpportunityExt(sc);

    System.assertEquals(2, oExt.previousOppContactIds.size() );
    oExt.saveCoBuyer();

    ocrs = [Select Id ,Role FROM OpportunityContactRole WHERE OpportunityId = :opp.Id AND Role = 'Co-Buyer'];
    System.assertEquals(2, ocrs.size() );

  }

  @isTest
  static void saveAndFinalize_Test()
  {
    Profile standardLegendUser = [SELECT id, name FROM Profile WHERE name = 'Legend Standard User - New'];
    User standardLU = new User(alias = 'standt',
      email='standarduser@testorg.com',
      emailencodingkey='UTF-8',
      lastname='Testing',
      languagelocalekey='en_US',
      localesidkey='en_US',
      profileid = standardLegendUser.Id,
      timezonesidkey='America/New_York',
      username='standardlegenduser@testorg.com');

     insert standardLU;

    System.runAs(standardLU)
    {

        Opportunity opp = OpportunityFactory.insertRetailBoatSale();
        /* lets create a really long name to test the opportunity Document Name ConCat function */
        opp.Name ='This has to be almost eighty characters long so we are sure hit the limit - 01';
        update opp;
        ApexPages.StandardController sc = new ApexPages.StandardController( opp );
        OpportunityExt oExt = new OpportunityExt(sc);

        System.assertEquals('Edit Boat Sale', oExt.getBoatBuilderButtonText() );
        System.assertEquals(false, oExt.getIsBOM_or_ADMIN() );
        System.assertEquals(true, oExt.getHasLineItems() );

        oExt.current_opportunity.Boat_Model_Year__c = '2015';
        oExt.current_opportunity.Trailer_Model_Year__c = '2015';
        oExt.current_opportunity.Delivery_Date__c = Date.today() + 100;
        oExt.current_opportunity.Deposit__c = 1000.00;
        oExt.current_opportunity.Deposit_Method__c = 'Cash';
        oExt.current_opportunity.Payment_Method__c = 'Finance';
        oExt.finalSave();
        opp = [SELECT Id, Invoice_Document_Id__c FROM Opportunity WHERE Id = :opp.Id];
        List<Processinstance> pi = [SELECT Id, Status
                                    FROM Processinstance
                                    WHERE TargetObjectId = :opp.Id
                                    AND Status = 'Pending'];

        System.assert( opp.Invoice_Document_Id__c == null );
        System.assertEquals( 0, pi.size() );

        sc = new ApexPages.StandardController( opp );
        oExt = new OpportunityExt(sc);
        oExt.finalSaveAndSubmit();
        opp = [SELECT Id, Invoice_Document_Id__c FROM Opportunity WHERE Id = :opp.Id];
        pi = [SELECT Id, Status
              FROM Processinstance
              WHERE TargetObjectId = :opp.Id
              AND Status = 'Pending'];


        System.assertEquals( 1, pi.size() );
        System.assert( opp.Invoice_Document_Id__c == null );
    }

  }

}