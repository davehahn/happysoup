/**
 * Created by dave on 2019-10-17.
 */

@IsTest
private class SupplierRegistration_T
{
  private static Registration_Helper.RegistrationWrapper wrapper;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    insertData();
  }

  private static void insertData()
  {

    Account smoker = Factory_Account.insertSupplierAccounts(1)[0];
    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
    settings.Smokercraft_Account_Id__c = smoker.Id;
    update settings;
    Product2 boat = Factory_Product.buildSerializedProduct('Boat', 'Full Windshield');
    boat.AcctSeedERP__Default_Vendor__c = smoker.Id;
    insert boat;
    GMBLASERP__Serial_Number__c boatSerial = Factory_SerialNumber.insertSerialNumber(boat, 'Test666');
  }

  private static void buildWrapper()
  {
    GMBLASERP__Serial_Number__c serial = [SELECT Id,
      Name,
      GMBLASERP__Product__r.Name,
      GMBLASERP__Product__r.RecordType.Name
    FROM GMBLASERP__Serial_Number__c
    LIMIT 1 ];
    Account customer = Factory_Account.insertFullPersonAccount('Tester', 'McTesterson');
    DateTime dtNow = DateTime.now();
    wrapper = new Registration_Helper.RegistrationWrapper();
    wrapper.isCurrent = true;
    wrapper.deliveryDate = dtNow;
    wrapper.registeredDate = dtNow;
    wrapper.createDate = dtNow;
    wrapper.registeredToCustomer = true;
    wrapper.toAccount = customer;
    wrapper.serialId = serial.Id;
    wrapper.serialNumber = serial.Name;
    wrapper.serialRegisteredWithSupplier = false;
    wrapper.productName = serial.GMBLASERP__Product__r.Name;
    wrapper.productRecordTypeId = serial.GMBLASERP__Product__r.RecordTypeId;
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

  @IsTest
  static void execute_SmokerCraft_Test()
  {
    buildWrapper();
    wrapper.supplierRegistrationClass = 'SupplierRegistration_SmokerCraft';
    Test.setMock( HttpCalloutMock.class, new SmokerMock_Registration() );
    Test.startTest();
    SupplierRegistration sr = new SupplierRegistration( new List<Registration_Helper.RegistrationWrapper>{ wrapper } );
    List<SupplierRegistration.Result> results = sr.execute();
    Test.stopTest();
    System.assertEquals( 1, results.size() );
    System.assertEquals( 'success', results[0].status );
  }
}