@isTest
private class SmokercraftAPI_Callout_Test {
  static Account supplier;
  static Account dealer;
  static Account customer;
  static Case theCase;
  static AcctSeed__Project__c recoverableERP;
  static GMBLASERP__Serial_Number__c serial;
  static Registration__c boatRegistration;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void initWarranty() {
    supplier = AccountFactory.insertSupplierAccount('testSupplier');
    theCase = Factory_Case.createWarrantyCase(supplier);
    recoverableERP = Factory_ERPOrder.createWarrantyERP(supplier, theCase.Serial_Number__c, 3);
    recoverableERP.Warranty_Case__c = theCase.Id;
    update recoverableERP;
  }

  private static void initRegistration() {
    dealer = Factory_Account.insertDealerAccounts(1)[0];
    customer = Factory_Account.insertFullPersonAccount('FTest', 'LTest');
    serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'Test12345DATA');
    boatRegistration = Factory_Registration.buildRegistration(dealer.Id, customer.Id, serial.Id);
    insert boatRegistration;
  }

  private static String buildData() {
    String data = 'hin=666TEST66&';
    data += 'dealer_number=1515&';
    data += 'dealer_seq=0';
    return data;
  }

  public class SmokerMock_Claim implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/xml');
      res.setBody('<XMLRESPONSE><RESPONSE>1234567890</RESPONSE><STATUSCODE>200</STATUSCODE></XMLRESPONSE>');
      res.setStatusCode(200);
      return res;
    }
  }

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

  @isTest
  static void submitClaimToSmoker_Test() {
    initWarranty();
    Test.setMock(HttpCalloutMock.class, new SmokerMock_Claim());
    Test.startTest();
    SmokercraftAPI_Callout.submitClaimToSmokercraft(recoverableERP.Id);
    Test.stopTest();
    AcctSeed__Project__c erp = [
      SELECT Id, Supplier_Claim_Number__c
      FROM AcctSeed__Project__c
      WHERE Id = :recoverableERP.Id
    ];

    System.assertEquals('1234567890', erp.Supplier_Claim_Number__c);
  }

  @isTest
  static void registerSerialNumber_Test() {
    Test.setMock(HttpCalloutMock.class, new SmokerMock_Registration());
    Test.startTest();
    String data = buildData();
    Map<String, String> result = SmokercraftAPI_Callout.registerSerialNumber(data, '666TEST666');
    Test.stopTest();
    System.assertEquals('success', result.get('status'));
  }

  @isTest
  static void submitClaimToSmoker_Error_Test() {
    initWarranty();
    Test.setMock(HttpCalloutMock.class, new SmokerMock_Error());
    String msg;
    Test.startTest();
    try {
      SmokercraftAPI_Callout.submitClaimToSmokercraft(recoverableERP.Id);
    } catch (SmokercraftAPI_Callout.SmokerAPIException e) {
      msg = e.getMessage();
    }
    Test.stopTest();

    System.assert(msg.contains('A test Error'));
  }

  @isTest
  static void registerSerialNumber_Error_Test() {
    Test.setMock(HttpCalloutMock.class, new SmokerMock_Error());
    String data = buildData();
    Test.startTest();
    Map<String, String> result = SmokercraftAPI_Callout.registerSerialNumber(data, '666TEST666');
    Test.stopTest();

    System.assertEquals('error', result.get('status'));
    System.assertEquals('Test Error', result.get('errorMessage'));
  }
}
