@isTest
private class ERPOrder_SendSupplierWarrantyEmail_Test {
  static Account acct;
  static Case c;
  static AcctSeed__Project__c recoverableERP;
  static Integer numOfContacts = 3;
  static Integer numOfParts = 3;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    acct = AccountFactory.insertSupplierAccountWithContacts('TestSupplier', numOfContacts);
    c = Factory_Case.createWarrantyCase(acct);
    recoverableERP = Factory_ERPOrder.createWarrantyERP(acct, c.Serial_Number__c, numOfParts);
    recoverableERP.Warranty_Case__c = c.Id;
    update recoverableERP;
  }

  public class SmokerMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/xml');
      res.setBody('<XMLRESPONSE><RESPONSE>1234567890</RESPONSE><STATUSCODE>200</STATUSCODE></XMLRESPONSE>');
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
  static void findContacts_test() {
    init();
    Contact[] contacts = ERPOrder_SendSupplierWarrantyEmail.findContacts(recoverableERP.Id);
    System.assertEquals(numOfContacts, contacts.size());
  }

  @isTest
  static void fetchERPInfo_Test() {
    init();
    String JSONresult = ERPOrder_SendSupplierWarrantyEmail.fetchERPInfo(recoverableERP.Id);
    Map<String, Boolean> result = (Map<String, Boolean>) JSON.deserialize(JSONresult, Map<String, Boolean>.class);
    System.assertEquals(true, result.get('isActive'));
    System.assertEquals(false, result.get('isSmoker'));
  }

  @isTest
  static void sendEmail_test() {
    init();
    Contact[] contacts = ERPOrder_SendSupplierWarrantyEmail.findContacts(recoverableERP.Id);
    List<String> cIds = new List<String>();
    for (Contact c : contacts) {
      cIds.add(c.Id);
    }
    ERPOrder_SendSupplierWarrantyEmail.sendRecoverableEmail(recoverableERP.Id, cIds);
    AcctSeed__Project__c erp = [SELECT Id, AcctSeed__Status__c FROM AcctSeed__Project__c WHERE Id = :recoverableERP.id];

    System.assertEquals('Completed', erp.AcctSeed__Status__c);
  }

  @isTest
  static void postToSmokerAPI_Test() {
    init();
    Test.setMock(HttpCalloutMock.class, new SmokerMock());
    Test.startTest();
    ERPOrder_SendSupplierWarrantyEmail.postToSmokerAPI(recoverableERP.Id);
    Test.stopTest();
    AcctSeed__Project__c erp = [
      SELECT Id, Supplier_Claim_Number__c
      FROM AcctSeed__Project__c
      WHERE Id = :recoverableERP.Id
    ];

    System.assertEquals('1234567890', erp.Supplier_Claim_Number__c);
  }

  @isTest
  static void postToSmokerAPI_Test_Error_Test() {
    init();
    Test.setMock(HttpCalloutMock.class, new SmokerMock_Error());
    String expectedError = 'SmokerCraft API Error';
    String msg;
    Test.startTest();
    try {
      ERPOrder_SendSupplierWarrantyEmail.postToSmokerAPI(recoverableERP.Id);
    } catch (AuraHandledException e) {
      msg = e.getMessage();
    }
    Test.stopTest();

    System.assertEquals(msg, expectedError);
  }
}
