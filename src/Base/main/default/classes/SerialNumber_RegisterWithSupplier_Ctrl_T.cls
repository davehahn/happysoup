/**
 * Created by dave on 2019-10-22.
 */

@IsTest
private class SerialNumber_RegisterWithSupplier_Ctrl_T {
  static GMBLASERP__Serial_Number__c serial;
  static Registration__c registration;
  static Registration__c nonApplicableRegistration;
  static Account customer;
  static Account dealer;

  public class SmokerMock_Registration implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/xml');
      res.setBody('<XMLRESPONSE><RESPONSE>Success</RESPONSE><STATUSCODE>200</STATUSCODE></XMLRESPONSE>');
      res.setStatusCode(200);
      return res;
    }
  }

  public class SmokerMock_Error implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/xml');
      res.setBody(
        '<XMLRESPONSE><RESPONSE></RESPONSE><STATUSCODE>400</STATUSCODE><RESPONSEERROR>A test Error</RESPONSEERROR></XMLRESPONSE>'
      );
      res.setStatusCode(200);
      return res;
    }
  }

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  public static void init() {
    customer = Factory_Account.insertFullPersonAccount('Tester', 'McTesterson');
    Account smoker = Factory_Account.insertSupplierAccounts(1)[0];
    dealer = Factory_Account.insertDealerAccounts(1)[0];
    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
    settings.Smokercraft_Account_Id__c = smoker.Id;
    update settings;
    Product2 boat = Factory_Product.buildSerializedProduct('Boat', 'Full Windshield');
    boat.AcctSeedERP__Default_Vendor__c = smoker.Id;
    insert boat;
    serial = Factory_SerialNumber.insertSerialNumber(boat, 'Test666');
    registration = Factory_Registration.buildRegistration(dealer.Id, customer.Id, serial.Id);
    insert registration;
  }

  private static void init2() {
    Product2 boat = Factory_Product.buildSerializedProduct('Boat', 'Full Windshield');
    insert boat;
    GMBLASERP__Serial_Number__c serial2 = Factory_SerialNumber.insertSerialNumber(boat, 'Test667');
    nonApplicableRegistration = Factory_Registration.buildRegistration(dealer.Id, customer.Id, serial2.Id);
    insert nonApplicableRegistration;
  }

  @IsTest
  static void fetchSerialNumber_Test() {
    init();
    Test.startTest();
    GMBLASERP__Serial_Number__c result = SerialNumber_RegisterWithSupplier_Ctrl.fetchSerialNumber(serial.Id);
    Test.stopTest();
    System.assertEquals(result.Id, serial.Id);
    System.assertEquals(false, serial.IsRegisteredWithSupplier__c);
    System.assertEquals(null, serial.RegisteredWithSupplierDate__c);
  }

  @IsTest
  static void fetchRegistration_Test() {
    init();
    Test.startTest();
    Registration__c result = SerialNumber_RegisterWithSupplier_Ctrl.fetchRegistration(serial.Id);
    Test.stopTest();
    System.assertEquals(result.Id, registration.Id);
    System.assertEquals(result.Account__r.Id, customer.Id);
  }

  @IsTest
  static void doRegister_Test() {
    init();
    Test.setMock(HttpCalloutMock.class, new SmokerMock_Registration());
    Test.startTest();
    SerialNumber_RegisterWithSupplier_Ctrl.doRegister(registration.Id);
    Test.stopTest();
    serial = [
      SELECT Id, IsRegisteredWithSupplier__c, RegisteredWithSupplierDate__c
      FROM GMBLASERP__Serial_Number__c
      WHERE Id = :serial.Id
    ];
    System.assertEquals(true, serial.IsRegisteredWithSupplier__c);
    System.assert(serial.RegisteredWithSupplierDate__c != null);
  }

  @IsTest
  static void doRegister_Error_Test() {
    String msg;
    init();
    Test.setMock(HttpCalloutMock.class, new SmokerMock_Error());
    Test.startTest();
    try {
      SerialNumber_RegisterWithSupplier_Ctrl.doRegister(registration.Id);
    } catch (Exception e) {
      msg = e.getMessage();
    }
    Test.stopTest();
    serial = [
      SELECT Id, IsRegisteredWithSupplier__c, RegisteredWithSupplierDate__c
      FROM GMBLASERP__Serial_Number__c
      WHERE Id = :serial.Id
    ];
    System.assertEquals('Test Error', msg);
    System.assertEquals(false, serial.IsRegisteredWithSupplier__c);
    System.assert(serial.RegisteredWithSupplierDate__c == null);
  }

  @IsTest
  static void doRegister_NoSupplierRegistrationClassError_Test() {
    String msg;
    init();
    init2();
    Test.startTest();
    try {
      SerialNumber_RegisterWithSupplier_Ctrl.doRegister(nonApplicableRegistration.Id);
    } catch (Exception e) {
      msg = e.getMessage();
    }
    Test.stopTest();
    System.assertEquals('Registration through Salesforce is not supported for this Supplier. Yet!', msg);
  }
}
