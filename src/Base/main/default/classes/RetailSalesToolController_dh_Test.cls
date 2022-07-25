@isTest
private class RetailSalesToolController_dh_Test {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @isTest
  static void buildSelectOptions_Test() {
    RetailSalesToolController_dh.buildSelectOptions();
  }

  @isTest
  static void fetchCustomer_PearsonAccount_Test() {
    Test.startTest();
    Account acct = Factory_Account.insertFullPersonAccount('Testy', 'McTestFace');
    String jsonCustomer = RetailSalesToolController_dh.fetchCustomer(acct.Id);
    Test.stopTest();
    Customer.Person customer = (Customer.Person) JSON.deserialize(jsonCustomer, Customer.Person.class);

    System.assertEquals('Testy', customer.firstName);
    System.assertEquals('McTestFace', customer.lastName);
    System.assertEquals(acct.Id, customer.Id);
  }

  @isTest
  static void fetchCustomer_Lead_Test() {
    Test.startTest();
    Lead l = Factory_Lead.insertLead('Testy', 'McTestFace');
    String jsonCustomer = RetailSalesToolController_dh.fetchCustomer(l.Id);
    Test.stopTest();
    Customer.Person customer = (Customer.Person) JSON.deserialize(jsonCustomer, Customer.Person.class);

    System.assertEquals('Testy', customer.firstName);
    System.assertEquals('McTestFace', customer.lastName);
    System.assertEquals(l.Id, customer.Id);
  }

  @isTest
  static void createSale_ExistingPersonAccount_Test() {
    Test.startTest();
    Account acct = Factory_Account.insertFullPersonAccount('Testy', 'McTestFace');
    String jsonCustomer = RetailSalesToolController_dh.fetchCustomer(acct.Id);
    RetailSalesToolController_dh.OppWrapper oppWrapper = new RetailSalesToolController_dh.OppWrapper();
    Date d = Date.today();
    oppWrapper.closeDate = d;
    String oppId = RetailSalesToolController_dh.createSale(jsonCustomer, JSON.serialize(oppWrapper));
    Opportunity opp = [SELECT Id, AccountId, CloseDate FROM Opportunity WHERE Id = :oppId];
    Test.stopTest();

    System.assertEquals(acct.Id, opp.AccountId);
    System.assertEquals(d, opp.CloseDate);
  }

  @isTest
  static void createSale_ExistingLead_Test() {
    Test.startTest();
    Lead l = Factory_Lead.buildAcceptedLead('Testy', 'McTestFace');
    insert l;
    String jsonCustomer = RetailSalesToolController_dh.fetchCustomer(l.Id);
    RetailSalesToolController_dh.OppWrapper oppWrapper = new RetailSalesToolController_dh.OppWrapper();
    Date d = Date.today();
    oppWrapper.closeDate = d;
    String oppId = RetailSalesToolController_dh.createSale(jsonCustomer, JSON.serialize(oppWrapper));
    Opportunity opp = [SELECT Id, Account.FirstName, Account.LastName, CloseDate FROM Opportunity WHERE Id = :oppId];
    Lead convertedLead = [SELECT Id, FirstName, LastName, isConverted FROM Lead WHERE Id = :l.Id];
    Test.stopTest();

    System.assert(convertedLead.isConverted);
    System.assertEquals(d, opp.CloseDate);
    System.assertEquals(convertedLead.FirstName, opp.Account.FirstName);
    System.assertEquals(convertedLead.LastName, opp.Account.LastName);
  }

  @isTest
  static void createSale_NonExisting_Person_Test() {
    Test.startTest();
    String[] hobbies = LGND_Utilities.getPicklistValues('Account', 'Hobbies__c');
    String[] emoMoto = LGND_Utilities.getPicklistValues('Account', 'Emotional_Motivation__c');
    String[] animals = LGND_Utilities.getPicklistValues('Account', 'Animals__c');
    String[] towVehicles = LGND_Utilities.getPicklistValues('Account', 'Tow_Vehicle__c');
    String[] relStatuses = LGND_Utilities.getPicklistValues('Account', 'Relationship_Status__c');
    String[] langs = LGND_Utilities.getPicklistValues('Account', 'Preferred_Language__c');
    String[] genders = LGND_Utilities.getPicklistValues('Account', 'Gender__pc');
    Customer.Person cust = new Customer.Person();
    cust.firstName = 'Testy';
    cust.lastName = 'McTestFace';
    cust.street = '139 Fittons Rd West';
    cust.city = 'Orillia';
    cust.stateCode = 'ON';
    cust.country = 'Canada';
    cust.postalCode = 'L3V 3V3';
    cust.email = 'mctestface@theinternet.com';
    cust.phone = '111-111-1111';
    cust.mobilePhone = '222-222-2222';
    cust.preferredLanguage = langs[0];
    cust.relationshipStatus = relStatuses[0];
    cust.numberOfChildren = 99;
    cust.towVehicle = towVehicles[0];
    cust.isTaxExempt = true;
    cust.taxExemptNumber = '111-111-111';
    cust.emotionalMotivation = new List<String>{ emoMoto[0] };
    cust.hobbies = new List<String>{ hobbies[0] };
    cust.animals = new List<String>{ animals[0] };
    RetailSalesToolController_dh.OppWrapper oppWrapper = new RetailSalesToolController_dh.OppWrapper();
    Date d = Date.today();
    oppWrapper.closeDate = d;
    String oppId = RetailSalesToolController_dh.createSale(JSON.serialize(cust), JSON.serialize(oppWrapper));
    Test.stopTest();
    Opportunity opp = [SELECT Id, Account.FirstName, Account.LastName, CloseDate FROM Opportunity WHERE Id = :oppId];
    System.assertEquals(d, opp.CloseDate);
    System.assertEquals(cust.firstName, opp.Account.FirstName);
    System.assertEquals(cust.lastName, opp.Account.LastName);
  }

  @isTest
  static void fetchBusiness_Test() {
    Test.startTest();
    Account a = Factory_Account.insertBusinessAccountWithContacts('Test Company', 2);
    String jsonResult = RetailSalesToolController_dh.fetchBusiness(a.Id);
    RetailSalesToolController_dh.Business result = (RetailSalesToolController_dh.Business) JSON.deserialize(
      jsonResult,
      RetailSalesToolController_dh.Business.class
    );
    Test.stopTest();
    System.assertEquals(a.Id, result.id);
    System.assertEquals(2, result.contacts.size());
  }

  @isTest
  static void createSale_NonExisting_Business_Test() {
    Test.startTest();
    RetailSalesToolController_dh.Business bus = new RetailSalesToolController_dh.Business();
    bus.name = 'Testy Co';
    bus.email = 'george@testyco.com';
    bus.phone = '111-111-1111';
    bus.fax = '222-222-2222';
    bus.contacts = new List<RetailSalesToolController_dh.BusinessContact>();
    bus.billingStreet = '139 Fittons Rd West';
    bus.billingCity = 'Orillia';
    bus.billingStateCode = 'ON';
    bus.billingCountry = 'Canada';
    bus.billingPostalCode = 'L3V 3V3';
    RetailSalesToolController_dh.BusinessContact bc1 = new RetailSalesToolController_dh.BusinessContact();
    bc1.firstName = 'fname1';
    bc1.lastName = 'lname1';
    bc1.phone = '111-222-3333';
    bc1.mobilePhone = '111-222-4444';
    bc1.email = 'bc1@tastyco.com';
    bc1.contactRoleType = 'buyer';
    RetailSalesToolController_dh.BusinessContact bc2 = new RetailSalesToolController_dh.BusinessContact();
    bc2.firstName = 'fname2';
    bc2.lastName = 'lname2';
    bc2.phone = '111-222-5555';
    bc2.mobilePhone = '111-222-6666';
    bc2.email = 'bc2@tastyco.com';
    bc2.contactRoleType = 'cobuyer';

    bus.contacts.add(bc1);
    bus.contacts.add(bc2);

    RetailSalesToolController_dh.OppWrapper oppWrapper = new RetailSalesToolController_dh.OppWrapper();
    Date d = Date.today();
    oppWrapper.closeDate = d;

    String oppId = RetailSalesToolController_dh.createSale_Business(JSON.serialize(bus), JSON.serialize(oppWrapper));
    Test.stopTest();
    Opportunity opp = [
      SELECT
        Id,
        Account.Name,
        Account.BillingCountry,
        Account.BillingCountryCode,
        Account.BillingState,
        Account.BillingStateCode,
        CloseDate,
        (SELECT Id FROM OpportunityContactRoles)
      FROM Opportunity
      WHERE Id = :oppId
    ];

    System.assertEquals(d, opp.CloseDate);
    System.assertEquals(bus.name, opp.Account.Name);
    System.assertEquals(2, opp.OpportunityContactRoles.size());
    System.assertEquals('Ontario', opp.Account.BillingState);
    System.assertEquals('ON', opp.Account.BillingStateCode);
    System.assertEquals('Canada', opp.Account.BillingCountry);
    System.assertEquals('CA', opp.Account.BillingCountryCode);
  }

  @isTest
  static void createSale_Existing_Business_Test() {
    Test.startTest();
    Account a = Factory_Account.insertBusinessAccountWithContacts('Test Company', 2);
    String jsonResult = RetailSalesToolController_dh.fetchBusiness(a.Id);
    RetailSalesToolController_dh.Business bus = (RetailSalesToolController_dh.Business) JSON.deserialize(
      jsonResult,
      RetailSalesToolController_dh.Business.class
    );

    bus.contacts[0].contactRoleType = 'buyer';
    bus.contacts[1].contactRoleType = 'cobuyer';

    RetailSalesToolController_dh.OppWrapper oppWrapper = new RetailSalesToolController_dh.OppWrapper();
    Date d = Date.today();
    oppWrapper.closeDate = d;

    String oppId = RetailSalesToolController_dh.createSale_Business(JSON.serialize(bus), JSON.serialize(oppWrapper));
    Test.stopTest();
    Opportunity opp = [
      SELECT Id, Account.Name, CloseDate, (SELECT Id FROM OpportunityContactRoles)
      FROM Opportunity
      WHERE Id = :oppId
    ];

    System.assertEquals(d, opp.CloseDate);
    System.assertEquals(bus.name, opp.Account.Name);
    System.assertEquals(2, opp.OpportunityContactRoles.size());
  }
}
