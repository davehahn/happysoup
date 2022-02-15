/**
 * Created by dave on 2019-10-09.
 */

@IsTest
private class Registration_T
{

  static Account customer;
  static Account customer2;
  static Account dealer;
  static Account smoker;
  static Product2 boat;
  static AcctSeedERP__Warehouse__c wfWarehouse;
  static User wfUser;
  static User partnerUser;
  static AcctSeed__Project__c retailERP;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    init();
  }

  private static void init()
  {
    Account customer = Factory_Account.insertFullPersonAccount('Tester', 'McTesterson');
    Account smoker = Factory_Account.insertSupplierAccounts( 1 )[0];
    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
    settings.Smokercraft_Account_Id__c = smoker.Id;
    update settings;
    Product2 boat = Factory_Product.buildSerializedProduct('Boat', 'Full Windshield');
    boat.AcctSeedERP__Default_Vendor__c = smoker.Id;
    insert boat;
    GMBLASERP__Serial_Number__c boatSerial = Factory_SerialNumber.insertSerialNumber( boat, 'Test666' );
    GMBLASERP__Serial_Number__c motorSerial = Factory_SerialNumber.insertFullSerial( 'Motor', 'Remote', 'TEST666MOTOR');
    AcctSeedERP__Warehouse__c wfWarehouse = wfWarehouse = [ SELECT Id, Name FROM AcctSeedERP__Warehouse__c
                                                             WHERE Name LIKE '%Whitefish%' LIMIT 1];
    Boolean orig = gcProjectTask.ignoreCommissions;
    gcProjectTask.ignoreCommissions = true;
    gcProject.disableJob = true;
    AcctSeed__Project__c retailERP = Factory_ERPOrder.insertRetailBoatSale( customer,
                                                       wfWarehouse,
                                                       DateTime.now().addDays(10),
                                                       boatSerial,
                                                       motorSerial);
    System.debug('init retailERP.Id = ' + retailERP.Id);
    gcProjectTask.ignoreCommissions = orig;
    List<Registration__c> regs = new List<Registration__c>();
    regs.add( Factory_Registration.buildRegistration( null, customer.Id, boatSerial.Id ) );
    regs[0].ErpOrder__c = retailERP.Id;
    Account customer2 = Factory_Account.buildFullPersonAccount('Tester2', 'McTesterson2');
    customer2.BillingStreet = '137 Fittons Rd West';
    customer2.BillingPostalCode = 'L3V 3V4';
    customer2.Phone = '111-111-1112';
    customer2.PersonMobilePhone = '222-222-2223';
    insert customer2;
    GMBLASERP__Serial_Number__c boatSerial2 = Factory_SerialNumber.insertSerialNumber( boat, 'Test667', boatSerial.GMBLASERP__Lot__c );
    regs.add( Factory_Registration.buildRegistration( null, customer2.Id, boatSerial2.Id ) );
    TriggerHandler.bypass('Registration_TriggerHandler');
    Registration_Domain.setDefaults( regs );
    insert regs;
    TriggerHandler.clearBypass('Registration_TriggerHandler');
  }

  private static void dataInit()
  {
    for( Account a : [SELECT Id FROM Account WHERE IsPersonAccount = true ] )
    {
      if( customer == null )
        customer = a;
      else
        customer2 = a;
    }
    retailERP = [ SELECT Id FROM AcctSeed__Project__c WHERE RecordTYpeId = :gcConstants.idRtProjectBoatSale LIMIT 1];
    dealer = Factory_Account.insertDealerAccounts( 1 )[0];
    partnerUser = Factory_User.createPartnerUser( dealer );
    wfWarehouse = [ SELECT Id, Name FROM AcctSeedERP__Warehouse__c
                    WHERE Name LIKE '%Whitefish%' ];
    wfUser = Factory_User.newUser('WhiteFish', 'User', 'System Administrator', wfWarehouse );
    insert wfUser;
  }

  private static void buildSecondCustomer()
  {
    customer2 = Factory_Account.buildFullPersonAccount('Tester2', 'McTesterson2');
    customer2.BillingStreet = '137 Fittons Rd West';
    customer2.BillingPostalCode = 'L3V 3V4';
    customer2.Phone = '111-111-1112';
    customer2.PersonMobilePhone = '222-222-2223';
    insert customer2;
  }

  public class SmokerMock_Registration implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req)
    {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/xml');
      res.setBody('<XMLRESPONSE><RESPONSE>Success</RESPONSE><STATUSCODE>200</STATUSCODE></XMLRESPONSE>');
      res.setStatusCode(200);
      return res;
    }
  }


  /**
      _____    ____   __  __            _____  _   _
     |  __ \  / __ \ |  \/  |    /\    |_   _|| \ | |
     | |  | || |  | || \  / |   /  \     | |  |  \| |
     | |  | || |  | || |\/| |  / /\ \    | |  | . ` |
     | |__| || |__| || |  | | / ____ \  _| |_ | |\  |
     |_____/  \____/ |_|  |_|/_/    \_\|_____||_| \_|
  */

  @IsTest
  static void setDefaults_StandardUser_Test()
  {
    dataInit();
    Registration__c reg = [ SELECT Id,
                                   ErpOrder__c,
                                   RegisteredByAccount__c,
                                   SerialNumber__c
                           FROM Registration__c
                           WHERE ErpOrder__c = :retailERP.Id LIMIT 1];
    reg.RegisteredByAccount__c = null;
    System.runAs( wfUser )
    {
      Registration_Domain.setDefaults( new List<Registration__c>{ reg } );
      System.assertEquals( true, reg.isCurrent__c, 'Registration should be current');
      System.assertEquals( Legend_Settings__c.getOrgDefaults().LegendWhitefishAccountId__c,
                           reg.RegisteredByAccount__c );
      System.assertEquals( String.valueOf( retailERP.Id ) + '_' + String.valueOf( reg.SerialNumber__c ),
                           reg.Uniqueifier__c );
    }
  }

  @IsTest
  static void setDefaults_PartnerUser_Test()
  {
    dataInit();
    Registration__c reg = [ SELECT Id,
                                   ErpOrder__c,
                                   RegisteredByAccount__c,
                                   SerialNumber__c
                            FROM Registration__c
                            WHERE ErpOrder__c = :retailERP.Id LIMIT 1];
    reg.RegisteredByAccount__c = null;
    System.runAs( partnerUser )
    {
      Registration_Domain.setDefaults( new List<Registration__c>{ reg } );
      System.assertEquals( true, reg.isCurrent__c, 'Registration should be current');
      System.assertEquals( dealer.Id, reg.RegisteredByAccount__c );
      System.assertEquals( String.valueOf( retailERP.Id ) + '_' + String.valueOf( reg.SerialNumber__c ),
                           reg.Uniqueifier__c );
    }
  }


  /**
      _    _  ______  _       _____   ______  _____
     | |  | ||  ____|| |     |  __ \ |  ____||  __ \
     | |__| || |__   | |     | |__) || |__   | |__) |
     |  __  ||  __|  | |     |  ___/ |  __|  |  _  /
     | |  | || |____ | |____ | |     | |____ | | \ \
     |_|  |_||______||______||_|     |______||_|  \_\
  **/

  @IsTest
  static void createPartnerCustomers_Test()
  {
    Registration__c reg = [ SELECT Id,
                                   isCurrent__c,
                                   ErpOrder__c,
                                   RegisteredByAccount__c,
                                   Account__c,
                                   ErpOrder__r.RecordTypeId,
                                   Registered_Motor__c,
                                   SerialNumber__c,
                                   SerialNumber__r.GMBLASERP__Product__r.RecordTypeId
                            FROM Registration__c
                            WHERE ErpOrder__c <> null ];
    Registration_Helper.createPartnerCustomers( new List<Registration__c>{ reg } );
    Partner_Customer__c[] pcs = [ SELECT Id, Customer__c, Partner__c, Uniqueifier__c
                                  FROM Partner_Customer__c ];
    System.assertEquals( 1, pcs.size() );
    System.assertEquals( reg.Account__c, pcs[0].Customer__c );
    System.assertEquals( reg.RegisteredByAccount__c, pcs[0].Partner__c );
    System.assertEquals( String.valueOf( reg.RegisteredByAccount__c ) + '-' + String.valueOf( reg.Account__c ),
                         pcs[0].Uniqueifier__c );
  }

  @IsTest
  static void setRegistrationDateOnSerial_Test()
  {
    Registration__c reg = [ SELECT Id,
                                   isCurrent__c,
                                   ErpOrder__c,
                                   RegisteredByAccount__c,
                                   Registered_To_Customer__c,
                                   Account__c,
                                   ErpOrder__r.RecordTypeId,
                                   Registered_Motor__c,
                                   SerialNumber__c,
                                   SerialNumber__r.GMBLASERP__Product__r.RecordTypeId
                            FROM Registration__c
                            WHERE ErpOrder__c <> null ];
    reg.Delivery_Date__c = DateTime.now().addMonths(1);
    update reg;
    Test.startTest();
    Registration_Helper.setRegistrationDateOnSerial( new List<Registration__c>{ reg }, null );
    Test.stopTest();
    GMBLASERP__Serial_Number__c boatSerial = [ SELECT Id, Retail_Registration_Date__c
                                               FROM GMBLASERP__Serial_Number__c
                                               WHERE Id = :reg.SerialNumber__c ];
    System.assertEquals( reg.Delivery_Date__c, boatSerial.Retail_Registration_Date__c );
  }

  @IsTest
  static void AfterInsert_recordChanges_Test()
  {
    Registration__c reg = [ SELECT Id,
                                   isCurrent__c,
                                   ErpOrder__c,
                                   ErpOrder__r.RecordTypeId,
                                   Registered_Motor__c,
                                   SerialNumber__c,
                                   SerialNumber__r.GMBLASERP__Product__r.RecordTypeId
                           FROM Registration__c
                           WHERE ErpOrder__c <> null ];
    System.debug('test reg.erp_order__c = ' + reg.ErpOrder__c);
    Test.startTest();
    Registration_Helper.execute_AfterInsert_recordChanges( new Set<Id>{ reg.Id } );
    Test.stopTest();
    reg = [ SELECT Id, Registered_Motor__c, isCurrent__c
            FROM Registration__c
            WHERE Id = :reg.Id ];
    System.assert( reg.isCurrent__c, 'Registration should be current');
    System.assert( reg.Registered_Motor__c != null );
  }

  @IsTest
  static void AfterInsert_recordChanges2_Test()
  {
    Id regId;
    Id oldRegId;
    for( Registration__c reg : [ SELECT Id,
                                   isCurrent__c,
                                   ErpOrder__c,
                                   ErpOrder__r.RecordTypeId,
                                   Registered_Motor__c,
                                   SerialNumber__c,
                                   SerialNumber__r.GMBLASERP__Product__r.RecordTypeId
                            FROM Registration__c ] )
    {
      if( reg.ErpOrder__c == null )
      {
        regId = reg.Id;
      }
      else
        oldRegId = reg.Id;
    }
    Test.startTest();
    Registration_Helper.execute_AfterInsert_recordChanges( new Set<Id>{ regId } );
    Test.stopTest();
    Map<Id, Registration__c> regs = new Map<Id, Registration__c>([ SELECT Id, isCurrent__c FROM Registration__c]);
    System.assert( regs.get(regId).isCurrent__c );
    System.assert( regs.get(oldRegId).isCurrent__c );
  }

  @IsTest
  static void execute_RegisterWithSupplier_Test()
  {
    Test.setMock( HttpCalloutMock.class, new SmokerMock_Registration() );
    Set<Id> regIds = new Set<Id>();
    Set<Id> serialIds = new Set<Id>();
    for( Registration__c r : [SELECT Id, SerialNumber__c FROM Registration__c] )
    {
      regIds.add( r.Id );
      serialIds.add( r.SerialNumber__c );
    }
    Test.startTest();
    Registration_Helper.execute_RegisterWithSupplier( regIds );
    Test.stopTest();
  }

  @IsTest
  static void execute_UpdateSupplierRegisteredSerials_Test()
  {
    List<SupplierRegistration.Result> results = new List<SupplierRegistration.Result>();
    Set<id> serialIds = new Set<Id>();
    for( Registration__c r : [SELECT Id, SerialNumber__c FROM Registration__c] )
    {
      serialIds.add( r.SerialNumber__c );
      Registration_Helper.RegistrationWrapper wrapper = new Registration_Helper.RegistrationWrapper();
      wrapper.serialId = r.SerialNumber__c;
      SupplierRegistration.Result result = new SupplierRegistration.Result();
      result.status = 'success';
      result.wrapper = wrapper;
      results.add( result );
    }
    Test.startTest();
    Registration_Helper.execute_UpdateSupplierRegisteredSerials( results );
    Test.stopTest();
    GMBLASERP__Serial_Number__c[] serials = [ SELECT Id, RegisteredWithSupplierDate__c,
                                                     IsRegisteredWithSupplier__c
                                              FROM GMBLASERP__Serial_Number__c
                                              WHERE Id IN :serialIds ];
    System.assert( serials[0].IsRegisteredWithSupplier__c );
    System.assert( serials[0].RegisteredWithSupplierDate__c != null );
    System.assert( serials[1].IsRegisteredWithSupplier__c );
    System.assert( serials[1].RegisteredWithSupplierDate__c != null );
  }

  @IsTest
  static void execute_NotifyRegistrationFailure_Test()
  {
    Registration_Helper.RegistrationWrapper wr1 = new Registration_Helper.RegistrationWrapper();
    Registration_Helper.RegistrationWrapper wr2 = new Registration_Helper.RegistrationWrapper();
    wr1.serialNumber = 'test666serial';
    wr2.serialNumber = 'test667serial';
    SupplierRegistration.Result r1 = new SupplierRegistration.Result();
    r1.status = 'error';
    r1.wrapper = wr1;
    r1.errorMessage = 'This is the error message for Serial 1';
    SupplierRegistration.Result r2 = new SupplierRegistration.Result();
    r2.status = 'error';
    r2.wrapper = wr2;
    r2.errorMessage = 'This is the error message for Serial 2';
    List<SupplierRegistration.Result> results = new List<SupplierRegistration.Result>{ r1, r2 };
    Test.startTest();
    Registration_Helper.execute_NotifyRegistrationFailure( results );
    Test.stopTest();
  }

  /**
   _______  _____   _____  _____   _____  ______  _____    _    _            _   _  _____   _       ______  _____
  |__   __||  __ \ |_   _|/ ____| / ____||  ____||  __ \  | |  | |    /\    | \ | ||  __ \ | |     |  ____||  __ \
     | |   | |__) |  | | | |  __ | |  __ | |__   | |__) | | |__| |   /  \   |  \| || |  | || |     | |__   | |__) |
     | |   |  _  /   | | | | |_ || | |_ ||  __|  |  _  /  |  __  |  / /\ \  | . ` || |  | || |     |  __|  |  _  /
     | |   | | \ \  _| |_| |__| || |__| || |____ | | \ \  | |  | | / ____ \ | |\  || |__| || |____ | |____ | | \ \
     |_|   |_|  \_\|_____|\_____| \_____||______||_|  \_\ |_|  |_|/_/    \_\|_| \_||_____/ |______||______||_|  \_\
  **/

  @IsTest
  static void Trigger_Test()
  {
    Account c = Factory_Account.buildFullPersonAccount('Tester3', 'McTesterson3');
    c.BillingStreet = '135 Fittons Rd West';
    c.BillingPostalCode = 'L3V 3V5';
    c.Phone = '111-111-1113';
    c.PersonMobilePhone = '222-222-2223';
    insert c;
    GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'Test-151');
    AcctSeedERP__Warehouse__c wfWarehouse = [ SELECT Id, Name FROM AcctSeedERP__Warehouse__c
                                              WHERE Name LIKE '%Whitefish%' ];
    Boolean orig = gcProjectTask.disableTrigger;
    gcProjectTask.disableTrigger = true;
    arMaterial_PACKAGE.disableTrigger = true;
    gcProject.disableTrigger = true;
    AcctSeed__Project__c erp = Factory_ERPOrder.insertRetailBoatSale( c, wfWarehouse, DateTime.now().addDays(10), ser);
    gcProjectTask.disableTrigger = orig;
    Registration__c reg = Factory_Registration.buildRegistration( null, c.Id, ser.Id );
    reg.ErpOrder__c = erp.Id;
    wfUser = Factory_User.newUser('WhiteFish', 'User', 'System Administrator', wfWarehouse );
    insert wfUser;
    System.runAs( wfUser )
    {
      Test.startTest();
      insert reg;
      reg = [ SELECT Id,
                     RegisteredByAccount__c,
                     isCurrent__c,
                     Uniqueifier__c
              FROM Registration__c
              WHERE Id = :reg.Id ];
      Test.stopTest();
      System.assertEquals( true, reg.isCurrent__c, 'Registration should be current');
      System.assertEquals( Legend_Settings__c.getOrgDefaults().LegendWhitefishAccountId__c,
                           reg.RegisteredByAccount__c );
      System.assertEquals( String.valueOf( erp.Id ) + '_' + String.valueOf( ser.Id ),
                           reg.Uniqueifier__c );
      // just to cover after update in trigger handler
      reg.Delivery_Date__c = Datetime.now().addDays(10);
      update  reg;
      // just to cover after delete in trigger handler
      delete reg;
    }
  }

}