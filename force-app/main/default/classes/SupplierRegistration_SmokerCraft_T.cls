/**
 * Created by dave on 2019-10-17.
 */

@IsTest
private class SupplierRegistration_SmokerCraft_T
{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    insertData();
  }

  private static void insertData()
  {
    Account customer = Factory_Account.insertFullPersonAccount('Tester', 'McTesterson');
    Account smoker = Factory_Account.insertSupplierAccounts( 1 )[0];
    Account dealer = Factory_Account.insertDealerAccounts( 1 )[0];
    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
    settings.Smokercraft_Account_Id__c = smoker.Id;
    update settings;
    Product2 boat = Factory_Product.buildSerializedProduct('Boat', 'Full Windshield');
    boat.AcctSeedERP__Default_Vendor__c = smoker.Id;
    insert boat;
    GMBLASERP__Serial_Number__c boatSerial = Factory_SerialNumber.insertSerialNumber( boat, 'Test666' );
    GMBLASERP__Serial_Number__c motorSerial = Factory_SerialNumber.insertFullSerial( 'Motor', 'Remote', 'TEST666MOTOR');
    AcctSeedERP__Warehouse__c wfWarehouse = [ SELECT Id,
                                                     Name
                                              FROM AcctSeedERP__Warehouse__c
                                              WHERE Name LIKE '%Whitefish%'
                                              LIMIT 1];
    AcctSeed__Project__c retailERP = Factory_ERPOrder.insertRetailBoatSale( customer,
                                                                            wfWarehouse,
                                                                            DateTime.now().addDays(10),
                                                                            boatSerial,
                                                                            motorSerial);
    Registration__c reg = Factory_Registration.buildRegistration( dealer.Id, customer.Id, boatSerial.Id );
    reg.ErpOrder__c = retailERP.Id;
    TriggerHandler.bypass('Registration_TriggerHandler');
    Registration_Domain.setDefaults( new List<Registration__c>{reg} );
    insert reg;
    TriggerHandler.clearBypass('Registration_TriggerHandler');
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

  public class SmokerMock_Error implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req)
    {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/xml');
      res.setBody('<XMLRESPONSE><RESPONSE></RESPONSE><STATUSCODE>400</STATUSCODE><RESPONSEERROR>A test Error</RESPONSEERROR></XMLRESPONSE>');
      res.setStatusCode(200);
      return res;
    }
  }

  @IsTest
  static void execute_success_Test()
  {
    Registration__c reg = [SELECT Id FROM Registration__c LIMIT 1];
    Registration_Helper.RegistrationWrapper wrapper = new Registration_Helper.RegistrationWrapper( reg.Id );
    Test.setMock( HttpCalloutMock.class, new SmokerMock_Registration() );
    Test.startTest();
    SupplierRegistration_SmokerCraft sc_reg = new SupplierRegistration_SmokerCraft();
    SupplierRegistration.Result result = sc_reg.execute( wrapper );
    Test.stopTest();
    System.assertEquals( 'success', result.status );
  }

  @IsTest
  static void execute_error_Test()
  {
    Registration__c reg = [SELECT Id FROM Registration__c LIMIT 1];
    Registration_Helper.RegistrationWrapper wrapper = new Registration_Helper.RegistrationWrapper( reg.Id );
    Test.setMock( HttpCalloutMock.class, new SmokerMock_Error() );
    Test.startTest();
    SupplierRegistration_SmokerCraft sc_reg = new SupplierRegistration_SmokerCraft();
    SupplierRegistration.Result result = sc_reg.execute( wrapper );
    Test.stopTest();
    System.assertEquals( 'error', result.status );
  }
}