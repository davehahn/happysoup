/**
 * Created by dave on 2020-05-14.
 */

@IsTest
private class SquareProcessor_T {
  static final Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
  static final String sqOrderId = 'jQa7fkUAAaGPFqg251PKrVexample';

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  public class SquareSuccessResponse implements HttpCalloutMock {
    private final String reference_id;

    public SquareSuccessResponse() {
      this.reference_id = null;
    }
    public SquareSuccessResponse(String reference_id) {
      this.reference_id = reference_id;
    }

    public HTTPResponse respond(HTTPRequest req) {
      Date t = Date.today();
      String dateString = String.valueOf(t.year()) + '-';
      dateString += String.valueOf(t.month()) + '-';
      dateString += String.valueOf(t.day());
      dateString += 'T16:20:20.000Z';
      String resString = '{"payment":{';
      resString +=
        '"id":"6aVfIp7gEaxzracrrrZPexample","created_at":"' +
        dateString +
        '","updated_at":"' +
        dateString +
        '",';
      resString += '"amount_money":{"amount":1000,"currency":"CAD"},';
      resString += '"status":"COMPLETED", "source_type":"CARD", "card_details":{';
      resString += ' "status":"CAPTURED","card":{';
      resString += '"card_brand":"MASTERCARD","last_4":"5809","exp_month":9,"exp_year":2022,"fingerprint":"sq-1-..."},';
      resString += '"entry_method":"KEYED","cvv_status":"CVV_ACCEPTED","avs_status":"AVS_ACCEPTED","auth_result_code":"01721P"},';
      resString +=
        ' "location_id":"X9XWRESTK1CZ1","order_id":"' +
        sqOrderId +
        '","reference_id":"' +
        reference_id +
        '",';
      resString += '"total_money":{"amount":1000,"currency":"CAD"}}}';
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody(resString);
      res.setStatusCode(200);
      return res;
    }
  }

  public class SquareErrorResponse implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      String resString = '{"errors":[{';
      resString += '"code": "INSUFFICIENT_FUNDS",';
      resString += '"detail": "Authorization error: \'INSUFFICIENT_FUNDS\'",';
      resString += ' "category": "PAYMENT_METHOD_ERROR"}],';
      resString += '"payment":{';
      resString += '"id":"6aVfIp7gEaxzracrrrZPexample","created_at":"2019-07-14T02:51:35.984Z","updated_at":"2019-07-14T02:51:36.701Z",';
      resString += '"amount_money":{"amount":1000,"currency":"CAD"},';
      resString += '"status":"COMPLETED", "source_type":"CARD", "card_details":{';
      resString += ' "status":"CAPTURED","card":{';
      resString += '"card_brand":"MASTERCARD","last_4":"5809","exp_month":9,"exp_year":2022,"fingerprint":"sq-1-..."},';
      resString += '"entry_method":"KEYED","cvv_status":"CVV_ACCEPTED","avs_status":"AVS_ACCEPTED","auth_result_code":"01721P"},';
      resString += ' "location_id":"X9XWRESTK1CZ1","order_id":"jQa7fkUAAaGPFqg251PKrVexample",';
      resString += '"total_money":{"amount":1000,"currency":"CAD"}}}';
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody(resString);
      res.setStatusCode(200);
      return res;
    }
  }

  @IsTest
  static void singletonSquareSettings_Test() {
    Square_Setting__mdt settings;
    if (runningInASandbox) {
      settings = [
        SELECT ApplicationId__c, LocationId__c ,Payment_Form_JS__c
        FROM Square_Setting__mdt
        WHERE IsSandbox__c = TRUE
      ];
    } else {
      settings = [
        SELECT ApplicationId__c, LocationId__c, Payment_Form_JS__c
        FROM Square_Setting__mdt
        WHERE IsSandbox__c = FALSE
      ];
    }

    SquareProcessor sp = SquareProcessor.getInstance();
    System.assertEquals(settings.ApplicationId__c, sp.getAppId());
    System.assertEquals(settings.Payment_Form_JS__c, sp.getFormJsUrl());
    System.assertEquals(settings.LocationId__c, sp.getLocId());
  }

  @IsTest
  static void squareSettings_Test() {
    Square_Setting__mdt settings;
    if (runningInASandbox)
      settings = [
        SELECT ApplicationId__c, AuthToken__c, Version__c, PaymentEndpoint__c
        FROM Square_Setting__mdt
        WHERE IsSandbox__c = TRUE
      ];
    else
      settings = [
        SELECT ApplicationId__c, AuthToken__c, Version__c, PaymentEndpoint__c
        FROM Square_Setting__mdt
        WHERE IsSandbox__c = FALSE
      ];
    System.assertEquals(settings.ApplicationId__c, SquareProcessor.staticSquareSettings.ApplicationId__c);
    System.assertEquals(settings.AuthToken__c, SquareProcessor.staticSquareSettings.AuthToken__c);
    System.assertEquals(settings.Version__c, SquareProcessor.staticSquareSettings.Version__c);
    System.assertEquals(settings.PaymentEndpoint__c, SquareProcessor.staticSquareSettings.PaymentEndpoint__c);
  }

  @IsTest
  static void getApplication_Test() {
    Square_Setting__mdt sqrSettings = [
      SELECT ApplicationId__c
      FROM Square_Setting__mdt
      WHERE IsSandbox__c = :runningInASandbox
      LIMIT 1
    ];

    Test.startTest();
    String appId = SquareProcessor.getApplicationId();
    Test.stopTest();

    System.assertEquals(sqrSettings.ApplicationId__c, appId);
  }

  @IsTest
  static void getPaymentFormJsUrl_Test() {
    Square_Setting__mdt sqrSettings = [
      SELECT Payment_Form_JS__c
      FROM Square_Setting__mdt
      WHERE IsSandbox__c = :runningInASandbox
      LIMIT 1
    ];

    Test.startTest();
    String jsURL = SquareProcessor.getPaymentFormJsUrl();
    Test.stopTest();

    System.assertEquals(sqrSettings.Payment_Form_JS__c, jsURL);
  }

  @IsTest
  static void PaymentConstructor_SquareTransaction_Test() {
    String fake_nonce = '123thisisanonce456';
    Account acct = Factory_Account.insertFullPersonAccount('Grumpy', 'McFloppyPants');
    Square_Transaction__c sqT = new Square_Transaction__c(
      Account__c = acct.Id,
      Amount__c = 10.00,
      Description__c = 'Apex Unit Test',
      Email__c = acct.PersonEmail
    );
    insert sqT;
    Test.startTest();
    SquareProcessor.Payment payment = new SquareProcessor.Payment(sqt.Amount__c, sqT.Id, fake_nonce);
    Test.stopTest();

    System.assertEquals(fake_nonce, payment.source_id);
    System.assertEquals(sqT.Id, payment.reference_id);
    System.assertEquals(sqT.Description__c, payment.note);
    System.assertEquals(sqT.Amount__c, payment.amount_money.amount);
    System.assertEquals(acct.PersonEmail, payment.buyer_email_address);
    System.assertEquals(acct.FirstName, payment.billing_address.first_name);
    System.assertEquals(acct.LastName, payment.billing_address.last_name);
    System.assertEquals(acct.BillingStreet, payment.billing_address.address_line_1);
    System.assertEquals(acct.BillingCity, payment.billing_address.locality);
    System.assertEquals(acct.BillingState, payment.billing_address.administrative_district_level_1);
    System.assertEquals(acct.BillingCountry, payment.billing_address.administrative_district_level_2);
    System.assertEquals('CA', payment.billing_address.country);
    System.assertEquals(acct.BillingPostalCode, payment.billing_address.postal_code);
  }

  @IsTest
  static void postPayment_Success_Test() {
    Test.setMock(HttpCalloutMock.class, new SquareSuccessResponse());
    Test.startTest();
    SquareProcessor square = new SquareProcessor();
    SquareProcessor.PaymentResponse result = square.postPayment(1000, null, 'some123random9r83stuff');
    Test.stopTest();

    System.assert(result != null, 'Response should not be null');
    System.assert(result.errors == null, 'Response should not contain errors');
    System.assertEquals(1000, result.payment.amount_money.amount);
    System.assertEquals('COMPLETED', result.payment.status);
  }

  @IsTest
  static void postPayment_Success_HelpCenterUser_Test() {
    Test.setMock(HttpCalloutMock.class, new SquareSuccessResponse());
    User u = Factory_User.buildUser('public', 'helpcenter', 'Legend Help Center Profile');
    insert u;
    System.runAs(u) {
      Test.startTest();
      SquareProcessor square = new SquareProcessor();
      SquareProcessor.PaymentResponse result = square.postPayment(1000, null, 'some123random9r83stuff');
      Test.stopTest();

      System.assert(result != null, 'Response should not be null');
      System.assert(result.errors == null, 'Response should not contain errors');
      System.assertEquals(1000, result.payment.amount_money.amount);
      System.assertEquals('COMPLETED', result.payment.status);
    }
  }

  @IsTest
  static void postPayment_Success_FromBoatReservation_Test() {
    User guest = Factory_User.createUser('Guest', 'BoatRes', 'Boat Reservation Profile');
    Account acct;
    Opportunity opp;
    System.runAs(guest) {
      acct = new Account(
        FirstName = 'TestFirst',
        LastName = 'TestLast',
        Phone = '111-111-1111',
        PersonEmail = 'someone@someplace.somedomain',
        RecordTypeId = LGND_Utilities.recordTypeIdFromName('Account', 'Person Account'),
        BillingState = 'Ontario'
      );
      insert acct;
      opp = new Opportunity(
        Deposit__c = 1000,
        Name = 'Test Opportunity',
        Pricebook2Id = LGND_Constants.retailPricebookId,
        StageName = 'Quoting',
        CloseDate = Date.today().addMonths(1),
        AccountId = acct.Id
      );
      insert opp;
      Test.setMock(HttpCalloutMock.class, new SquareSuccessResponse(opp.Id));
      Test.startTest();
      SquareProcessor square = new SquareProcessor();
      SquareProcessor.PaymentResponse result = square.postPayment(1000, opp.Id, 'some123random9r83stuff');
      Test.stopTest();

      System.assert(result != null, 'Response should not be null');
      System.assert(result.errors == null, 'Response should not contain errors');
      System.assertEquals(1000, result.payment.amount_money.amount);
      System.assertEquals('COMPLETED', result.payment.status);
      System.assertEquals(opp.Id, result.payment.reference_id);
    }

    Square_Transaction__c[] sqTs = [
      SELECT Id, Amount__c, Account__c, Description__c, Notes__c, sqOrderId__c, sqStatus__c, sqReferenceId__c
      FROM Square_Transaction__c
      WHERE Account__c = :acct.Id
    ];

    AcctSeed__Cash_Receipt__c[] cashReceipts = [
      SELECT Id, AcctSeed__Amount__c, AcctSeed__Payment_Reference__c, AcctSeed__Purpose__c, Payment_Method__c
      FROM AcctSeed__Cash_Receipt__c
      WHERE AcctSeed__Account__c = :acct.Id
    ];

    System.assertEquals(1, sqTs.size(), 'Should be a Square_Transaction__c record');
    System.assertEquals(acct.Id, sqTs[0].Account__c);
    System.assertEquals(1000, sqTs[0].Amount__c);
    System.assertEquals('COMPLETED', sqTs[0].sqStatus__c);
    System.assertEquals(opp.Name, sqTs[0].Description__c);
    System.assertEquals(opp.Id, sqTs[0].sqReferenceId__c);
    System.assertEquals('Deposit for Online Boat Reservation', sqTs[0].Notes__c);

    System.assertEquals(1, cashReceipts.size(), '1 Cash Receipt should have been created');
    System.assertEquals(1000, cashReceipts[0].AcctSeed__Amount__c);
    System.assertEquals(sqTs[0].sqOrderId__c, cashReceipts[0].AcctSeed__Payment_Reference__c);
    System.assertEquals('Customer Receipt', cashReceipts[0].AcctSeed__Purpose__c);
    System.assertEquals('Online Store', cashReceipts[0].Payment_Method__c);
  }

  @IsTest
  static void postPayment_SquareError_Test() {
    Test.setMock(HttpCalloutMock.class, new SquareErrorResponse());
    Test.startTest();
    SquareProcessor square = new SquareProcessor();
    SquareProcessor.PaymentResponse result = square.postPayment(1000, 'recordId', 'some123random9r83stuff');
    Test.stopTest();

    System.assert(result != null, 'Response should not be null');
    System.assert(result.errors != null, 'Response should contain errors');
    System.assertEquals(1, result.errors.size(), 'There should be One error');
    System.assertEquals('INSUFFICIENT_FUNDS', result.errors[0].code);
    System.assertEquals('Authorization error: \'INSUFFICIENT_FUNDS\'', result.errors[0].detail);
    System.assertEquals('PAYMENT_METHOD_ERROR', result.errors[0].category);
  }
}
