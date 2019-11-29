@isTest
private class RegistrationExt_Test {

  static AcctSeed__Project__c erp;
  static GMBLASERP__Serial_Number__c serial;
  //static GMBLASERP__Serial_Number__c serial_motor;
  static Account customer;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }


  private static void init()
  {
    Account dealer = AccountFactory.buildDealerAccount('Test Dealer UnitTester');
    insert dealer;
    serial = Factory_SerialNumber.insertFullSerial( 'Boat',
                                                    'Pontoon',
                                                    '1234567890-UNIT-TESTER');
    erp = Factory_ERPOrder.createPartnerBoatSale( dealer, serial );
  }

//  private static AcctSeedERP__Warehouse__c determineWarehouse()
//  {
//    User u = [SELECT GL_Account_Variable_1__c FROM User WHERE Id = :UserInfo.getUserId() ];
//    try {
//      return  [
//        SELECT Id, Name, GL_Account_Variable_3__c
//        FROM AcctSeedERP__Warehouse__c
//        WHERE Name = :u.GL_Account_Variable_1__c
//        LIMIT 1
//      ];
//    }
//    catch( Exception e )
//    {
//      return [
//        SELECT Id, Name, GL_Account_Variable_3__c
//        FROM AcctSeedERP__Warehouse__c
//        WHERE Name LIKE '%Whitefish%'
//        LIMIT 1
//      ];
//    }
//  }

//  private static void initRetail()
//  {
//    init_toCustomer();
//    serial_motor = Factory_SerialNumber.insertFullSerial( 'Motor',
//      'Remote',
//      '666TESTMOTOR666');
//    AcctSeedERP__Warehouse__c wh = determineWarehouse();
//    erp = Factory_ERPOrder.insertRetailBoatSale( customer,
//                                                 wh,
//                                                 null,
//                                                 serial,
//                                                 serial_motor );
//  }

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

  @isTest
  static void createRegistrations_Test()
  {
    init_toCustomer();
    DateTime dDate = DateTime.now();
    Test.startTest();
    Registration__c result = RegistrationExt.createRegistration( String.valueOf(customer.Id),
                                                                 String.valueOf(serial.Id),
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

}