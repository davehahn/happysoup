/**
 * Created by dave on 2020-06-11.
 */

@IsTest
private class Customer_T {
  static Id personRT = LGND_Utilities.recordTypeIdFromName('Account', 'Person Account');
  static String email = 'someone@someplace.somedomain';
  static Map<String, String> cust = new Map<String, String>{
    'firstName' => 'TestFirst',
    'lastName' => 'TestLast',
    'phone' => '111-111-1111',
    'email' => email,
    'street' => '139 Fittons Rd West',
    'city' => 'Orillia',
    'state' => 'Ontario',
    'country' => 'Canada',
    'postalCode' => 'L3V3V3'
  };
  static Account acct_diff = new Account(
    FirstName = 'TestFirst_diff',
    LastName = 'TestLast_diff',
    Phone = '111-111-2222',
    PersonEmail = 'aperson@aplace.somedomain',
    RecordTypeId = personRT
  );
  static Account acct = new Account(
    FirstName = 'TestFirst',
    LastName = 'TestLast',
    Phone = '111-111-1111',
    PersonEmail = email,
    RecordTypeId = personRT
  );

  private static Lead createLead() {
    Lead l = new Lead(
      FirstName = cust.get('firstName'),
      LastName = cust.get('lastName'),
      Email = cust.get('email'),
      Phone = cust.get('phone'),
      Street = cust.get('street'),
      City = cust.get('city'),
      State = cust.get('state'),
      Country = cust.get('country'),
      PostalCode = cust.get('postalCode'),
      Status = Lead_Service.ACCEPTED_STATUS
    );
    TriggerBase.bypass('Lead');
    insert l;
    TriggerBase.clearBypass('Lead');
    return l;
  }

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void personConstructor_Test() {
    Account a = new Account(
      FirstName = cust.get('firstName'),
      LastName = cust.get('lastName'),
      PersonEmail = cust.get('email'),
      Phone = cust.get('phone'),
      BillingStreet = cust.get('street'),
      BillingCity = cust.get('city'),
      BillingState = cust.get('state'),
      BillingCountry = cust.get('country'),
      BillingPostalCode = cust.get('postalCode')
    );
    insert a;
    Customer.Person emptyPerson = new Customer.Person();
    Customer.Person person = new Customer.Person(a);

    System.assertEquals('person', emptyPerson.type);
    System.assertEquals(cust.get('firstName'), person.firstName);
    System.assertEquals(cust.get('lastName'), person.lastName);
    System.assertEquals(cust.get('email'), person.email);
    System.assertEquals(cust.get('phone'), person.phone);
    System.assertEquals(cust.get('street'), person.street);
    System.assertEquals(cust.get('city'), person.city);
    System.assertEquals(cust.get('state'), person.state);
    System.assertEquals(cust.get('country'), person.country);
    System.assertEquals(cust.get('postalCode'), person.postalCode);
  }

  @IsTest
  static void newAccount_Pass_Test() {
    String custJSON = JSON.serialize(cust);
    Customer.Person person = (Customer.Person) JSON.deserialize(custJSON, Customer.Person.class);
    Test.startTest();
    Customer.AccountSaveResult result = person.upsertRecord();
    Test.stopTest();

    System.assertEquals('success', result.status);
    System.assertEquals(cust.get('firstName'), result.record.FirstName);
    System.assertEquals(cust.get('lastName'), result.record.LastName);
    System.assertEquals(cust.get('email'), result.record.PersonEmail);
    System.assertEquals(cust.get('phone'), result.record.Phone);
    System.assertEquals(cust.get('street'), result.record.BillingStreet);
    System.assertEquals(cust.get('city'), result.record.BillingCity);
    System.assertEquals(cust.get('state'), result.record.BillingState);
    System.assertEquals(cust.get('country'), result.record.BillingCountry);
    System.assertEquals(cust.get('postalCode'), result.record.BillingPostalCode);
  }

  @IsTest
  static void newAccount_DupEmail_Test() {
    insert acct;
    String custJSON = JSON.serialize(cust);
    Customer.Person person = (Customer.Person) JSON.deserialize(custJSON, Customer.Person.class);
    Customer.AccountSaveResult result;
    String errorMsg;
    String expectedError = errorMsg =
      email +
      ' is already in use by a Customer by the name of ' +
      acct.FirstName +
      ' ' +
      acct.LastName;
    Test.startTest();
    try {
      result = person.upsertRecord();
    } catch (Exception e) {
      errorMsg = e.getMessage();
    }
    Test.stopTest();

    System.debug(result);
    System.assert(result == null);
    System.assert(errorMsg != null);
    System.assertEquals(expectedError, errorMsg);
  }

  @IsTest
  static void newAccount_DupPhone_Test() {
    acct.PersonEmail = null;
    insert acct;
    String custJSON = JSON.serialize(cust);
    Customer.Person person = (Customer.Person) JSON.deserialize(custJSON, Customer.Person.class);

    Test.startTest();
    Customer.AccountSaveResult result = person.upsertRecord();
    Test.stopTest();

    System.assertEquals('success', result.status);
    System.assertEquals(cust.get('firstName'), result.record.FirstName);
    System.assertEquals(cust.get('lastName'), result.record.LastName);
    System.assertEquals(cust.get('email'), result.record.PersonEmail);
    System.assertEquals(cust.get('phone'), result.record.Phone);
    System.assertEquals(cust.get('street'), result.record.BillingStreet);
    System.assertEquals(cust.get('city'), result.record.BillingCity);
    System.assertEquals(cust.get('state'), result.record.BillingState);
    System.assertEquals(cust.get('country'), result.record.BillingCountry);
    System.assertEquals(cust.get('postalCode'), result.record.BillingPostalCode);
  }

  @IsTest
  static void newAccount2_Pass_Test() {
    insert acct_diff;
    String custJSON = JSON.serialize(cust);
    Customer.Person person = (Customer.Person) JSON.deserialize(custJSON, Customer.Person.class);
    Test.startTest();
    Customer.AccountSaveResult result = person.upsertRecord();
    Test.stopTest();

    Account[] accts = [SELECT Id FROM Account WHERE RecordTypeId = :personRT];

    System.assertEquals(2, accts.size());
    System.assertEquals('success', result.status);
  }

  @IsTest
  static void newAccount_ValidationFail_Test() {
    cust.put('lastName', null);
    String custJSON = JSON.serialize(cust);
    Customer.Person person = (Customer.Person) JSON.deserialize(custJSON, Customer.Person.class);
    Test.startTest();
    Customer.AccountSaveResult result = person.upsertRecord();
    Test.stopTest();

    System.assertEquals('error', result.status);
    System.assertEquals(1, result.messages.size());
  }

  @IsTest
  static void leadConvert_WithOpportunity_Test() {
    Lead l = createLead();
    User salesUser = Factory_User.createUser('Test', 'SalesPerson', 'System Administrator');
    Customer.Person person = new Customer.Person(l);
    person.setCreateOpportunityOnLeadConvert(true);
    Customer.AccountSaveResult result;
    System.runAs(salesUser) {
      Test.startTest();
      result = person.upsertRecord();
      Test.stopTest();
    }

    Account[] accts = [SELECT Id, OwnerId FROM Account WHERE RecordTypeId = :personRT];
    Opportunity[] opps = [SELECT Id, OwnerId, AccountId FROM Opportunity];
    l = [
      SELECT
        Id,
        IsConverted,
        ConvertedAccountId,
        ConvertedOpportunityId,
        FirstName,
        LastName,
        Phone,
        Email,
        Street,
        City,
        State,
        Country,
        PostalCode
      FROM Lead
      WHERE Id = :l.Id
    ];

    System.assert(l.IsConverted, 'Lead should be converted');
    System.assertEquals(1, accts.size());
    System.assertEquals(l.ConvertedAccountId, accts[0].Id);
    System.assertEquals(1, opps.size(), 'One Opportunity should have been created');
    System.assertEquals(l.ConvertedOpportunityId, opps[0].Id, 'Lead should have a Converted Opportunity Id');
    System.assertEquals('success', result.status);
    System.assertEquals(l.FirstName, result.record.FirstName);
    System.assertEquals(l.LastName, result.record.LastName);
    System.assertEquals(l.Email, result.record.PersonEmail);
    System.assertEquals(l.Phone, result.record.Phone);
    System.assertEquals(l.Street, result.record.BillingStreet);
    System.assertEquals(l.City, result.record.BillingCity);
    System.assertEquals(l.State, result.record.BillingState);
    System.assertEquals(l.Country, result.record.BillingCountry);
    System.assertEquals(l.PostalCode, result.record.BillingPostalCode);
    System.assertEquals(salesUser.Id, accts[0].OwnerId, 'Sales User should own the created Account');
    System.assertEquals(salesUser.Id, opps[0].OwnerId, 'Sales User should own the created Opportunity');
  }
}
