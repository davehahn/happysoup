/**
 * Created by dave on 2020-05-14.
 */

@IsTest
private class SquareProcessor_T
{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  public class SquareSuccessResponse implements HttpCalloutMock
  {
    public HTTPResponse respond(HTTPRequest req)
    {
      String resString = '{"payment":{';
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
      res.setBody( resString );
      res.setStatusCode(200);
      return res;
    }
  }

  public class SquareErrorResponse implements HttpCalloutMock
  {
    public HTTPResponse respond(HTTPRequest req)
    {
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
      res.setBody( resString );
      res.setStatusCode(200);
      return res;
    }
  }


  @IsTest
  static void getApplication_Test()
  {
    Square_Setting__mdt sqrSettings =
      [ SELECT ApplicationId__c
        FROM Square_Setting__mdt
        WHERE IsSandbox__c = true
        LIMIT 1 ];

    Test.startTest();
    String appId = SquareProcessor.getApplicationId();
    Test.stopTest();

    System.assertEquals( sqrSettings.ApplicationId__c, appId );
  }

  @IsTest
  static void postPayment_Success_Test()
  {
    Test.setMock( HttpCalloutMock.class, new SquareSuccessResponse() );
    Test.startTest();
    SquareProcessor square = new SquareProcessor();
    SquareProcessor.PaymentResponse result =
      square.postPayment( 1000, 'some123random9r83stuff' );
    Test.stopTest();

    System.assert( result != null , 'Response should not be null');
    System.assert( result.errors == null, 'Response should not contain errors');
    System.assertEquals( 1000, result.payment.amount_money.amount );
    System.assertEquals( 'COMPLETED', result.payment.status );
  }

  @IsTest
  static void postPayment_Success_HelpCenterUser_Test()
  {
    Test.setMock( HttpCalloutMock.class, new SquareSuccessResponse() );
    User u = Factory_User.buildUser('public', 'helpcenter', 'Legend Help Center Profile');
    insert u;
    System.runAs( u )
    {
      Test.startTest();
      SquareProcessor square = new SquareProcessor();
      SquareProcessor.PaymentResponse result =
        square.postPayment(1000, 'some123random9r83stuff');
      Test.stopTest();

      System.assert(result != null, 'Response should not be null');
      System.assert(result.errors == null, 'Response should not contain errors');
      System.assertEquals(1000, result.payment.amount_money.amount);
      System.assertEquals('COMPLETED', result.payment.status);
    }
  }

  @IsTest
  static void postPayment_SquareError_Test()
  {
    Test.setMock( HttpCalloutMock.class, new SquareErrorResponse() );
    Test.startTest();
    SquareProcessor square = new SquareProcessor();
    SquareProcessor.PaymentResponse result =
      square.postPayment( 1000, 'some123random9r83stuff' );
    Test.stopTest();

    System.assert( result != null , 'Response should not be null');
    System.assert( result.errors != null, 'Response should contain errors');
    System.assertEquals( 1, result.errors.size(), 'There should be One error');
    System.assertEquals( 'INSUFFICIENT_FUNDS', result.errors[0].code );
    System.assertEquals( 'Authorization error: \'INSUFFICIENT_FUNDS\'', result.errors[0].detail );
    System.assertEquals( 'PAYMENT_METHOD_ERROR', result.errors[0].category );
  }

}
