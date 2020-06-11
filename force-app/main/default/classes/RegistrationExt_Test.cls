@isTest
private class RegistrationExt_Test {

  static AcctSeed__Project__c erp;
  static GMBLASERP__Serial_Number__c serial;
  //static GMBLASERP__Serial_Number__c serial_motor;
  static Account customer;
  static Account dealer;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }


  private static void init()
  {
    dealer = AccountFactory.buildDealerAccount('Test Dealer UnitTester');
    insert dealer;
    serial = Factory_SerialNumber.insertFullSerial( 'Boat',
                                                    'Pontoon',
                                                    '1234567890-UNIT-TESTER');
    erp = Factory_ERPOrder.createPartnerBoatSale( dealer, serial );
  }

  private static void init_toCustomer()
  {
    customer = Factory_Account.insertFullPersonAccount('fName', 'lName');
    serial = Factory_SerialNumber.insertFullSerial( 'Boat',
                                                    'Pontoon',
                                                    '1234567890-UNIT-TESTER');
  }

	@isTest static void coverageTest() {
		RegistrationExt.coverage();
	}

  @isTest
  static void autoCreateRegistrationOnErpDelivered_Test()
  {
    init();
    Registration__c[] beforeRegs = [SELECT Id
                                    FROM Registration__c
                                    WHERE SerialNumber__c = :serial.Id
                                    AND isCurrent__c = true];
    Test.startTest();
    erp.Stage__c = 'Delivered';
    erp.AcctSeed__Status__c = 'Ready For Accounting';
    update erp;
    Test.stopTest();
    Registration__c[] afterRegs = [SELECT Id
                                    FROM Registration__c
                                    WHERE SerialNumber__c = :serial.Id
                                    AND isCurrent__c = true];
    System.assertEquals(0, beforeRegs.size() );
    System.assertEquals(1, afterRegs.size() );
  }

  @isTest
  static void autoCreateRegistrationOnErpDelivered_LimitedUser_Test()
  {
    User elisha;
    init();

    System.runAs(new User(Id = Userinfo.getUserId())) {
      elisha = User_TestFactory.newUser('Test-Elisha', 'Test-Sanders', 'Legend Standard User - New');
      insert elisha;
      PermissionSetAssignment[] psas = new List<PermissionSetAssignment>();
      Set<String> permSetNames = new Set<String>{ 'Can Manager External Users',
                                                  'Legend Dealer Care and Logistics',
                                                  'Legend JR Accounting',
                                                  'Legend JR Parts and Service',
                                                  'Legend JR Product Specialist',
                                                  'Legend SR Parts and Service',
                                                  'Lightning Experience',
                                                  'PartnerCommunityChatter' };
      for( PermissionSet ps : [SELECT Id FROM PermissionSet WHERE Name IN :permSetNames] )
      {
        psas.add( new PermissionSetAssignment(AssigneeId = elisha.Id,
                                              PermissionSetId = ps.Id) );
      }
      insert psas;
    }

    System.runAs( elisha )
    {
      Registration__c[] beforeRegs = [SELECT Id
                                    FROM Registration__c
                                    WHERE SerialNumber__c = :serial.Id];
      Test.startTest();
      erp.Stage__c = 'Delivered';
      erp.AcctSeed__Status__c = 'Ready For Accounting';
      update erp;
      Test.stopTest();
      Registration__c[] afterRegs = [SELECT Id
                                      FROM Registration__c
                                      WHERE SerialNumber__c = :serial.Id];
      System.assertEquals(0, beforeRegs.size() );
      System.assertEquals(1, afterRegs.size() );
    }
  }

  @isTest
  static void fetchAccountContacts_Test()
  {
    Account dealer = Factory_Account.insertDealerAccounts(1)[0];
    Contact[] contacts = new List<Contact>();
    Contact partnerContact = Factory_Contact.buildContact( dealer.Id, 'fName-Admin', 'lName-Admin', 'admin@testcompany.com');
    for( Integer i=0;i<4;i++ )
    {
      contacts.add( Factory_Contact.newContact( dealer.Id,
                                                'fName'+String.valueOf(i),
                                                'lName'+String.valueOf(i) ) );
    }
    insert contacts;
    User partner = [SELECT Id FROM User WHERE ContactId = :partnerContact.Id LIMIT 1];
    System.runAs( partner )
    {
      Contact[] result = RegistrationExt.fetchAccountContacts();
      System.assertEquals( 5, result.size() );
    }
  }

  @isTest
  static void fetchAccountContacts_NoPartnerUser_Test()
  {
    Contact[] result = RegistrationExt.fetchAccountContacts();
    System.assertEquals( 0, result.size() );
  }

  @IsTest
  static void fetchCustomer_Account_Test()
  {
    init_toCustomer();
    String custJSON = RegistrationExt.fetchCustomer( customer.Id );
    Customer.Person person =
      (Customer.Person)JSON.deserialize( custJSON, Customer.Person.class );

    System.assertEquals( customer.Id, person.id );
    System.assertEquals( customer.FirstName, person.firstName );
    System.assertEquals( customer.LastName, person.lastName );
    System.assertEquals( customer.PersonEmail, person.email );
  }

  @IsTest
  static void fetchCustomer_Lead_Test()
  {
    Lead l = new Lead(
      FirstName = 'Tester',
      LastName = 'LastTester',
      Email = 'atester@someplace.somedomain',
      Phone = '111-111-1111'
    );
    TriggerHandler.bypass('Lead_TriggerHandler');
    insert l;
    TriggerHandler.clearBypass('Lead_TriggerHandler');
    String custJSON = RegistrationExt.fetchCustomer( l.Id );
    Customer.Person person =
      (Customer.Person)JSON.deserialize( custJSON, Customer.Person.class );

    System.assertEquals( l.Id, person.id );
    System.assertEquals( l.FirstName, person.firstName );
    System.assertEquals( l.LastName, person.lastName );
    System.assertEquals( l.Email, person.email );
  }

  @isTest
  static void createRegistrations_Customer_Test()
  {
    init_toCustomer();
    DateTime dDate = DateTime.now();
    Map<String, String> cust = new Map<String, String>
    {
      'type' => 'person',
      'id' => customer.Id,
      'firstName' => customer.FirstName,
      'lastName' => customer.LastName,
      'phone' => customer.Phone,
      'email' => customer.PersonEmail,
      'street' => customer.BillingStreet,
      'city' => customer.BillingCity,
      'state' => customer.BillingState,
      'country' => customer.BillingCountry,
      'postalCode' => customer.BillingPostalCode
    };
    Test.startTest();
    Registration__c result = RegistrationExt.createRegistration(
      String.valueOf(serial.Id),
      JSON.serialize( cust ),
      'person',
      new List<GMBLASERP__Serial_Number__c>(),
      null,
      '',
      dDate,
      null,
      '',
      'Cash'
    );
    Test.stopTest();
    serial = [SELECT Id, Retail_Registration_Date__c
              FROM GMBLASERP__Serial_Number__c
              WHERE Id = :serial.Id];

    System.assertEquals( result.SerialNumber__c, serial.Id );
    System.assertEquals( result.Account__c, customer.Id );
  }

  @isTest
  static void createRegistrations_Dealer_Test()
  {
    init();
    DateTime dDate = DateTime.now();
    Map<String, String> cust = new Map<String, String>
    {
      'type' => 'dealer',
      'id' => dealer.Id
    };
    Test.startTest();
    Registration__c result = RegistrationExt.createRegistration(
      String.valueOf(serial.Id),
      JSON.serialize( cust ),
      'dealer',
      new List<GMBLASERP__Serial_Number__c>(),
      null,
      '',
      dDate,
      null,
      '',
      'Cash'
    );
    Test.stopTest();
    serial = [SELECT Id, Retail_Registration_Date__c
    FROM GMBLASERP__Serial_Number__c
    WHERE Id = :serial.Id];

    System.assertEquals( result.SerialNumber__c, serial.Id );
    System.assertEquals( result.Account__c, dealer.Id );
  }

}