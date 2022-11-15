/**
 * Created by dave on 2020-05-14.
 */

@IsTest
private class SquarePaymentForm_Controller_T {
  static final Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  public class SquareSuccessResponse implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
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
      res.setBody(resString);
      res.setStatusCode(200);
      return res;
    }
  }

  @IsTest
  static void postToSquare_Test() {
    Test.setMock(HttpCalloutMock.class, new SquareSuccessResponse());
    Test.startTest();
    String resultJSON = SquarePaymentForm_Controller.postToSquare(1000, 'recordId', 'hfjsghfs87fsdgj');
    Test.stopTest();
    SquareProcessor.PaymentResponse result = (SquareProcessor.PaymentResponse) JSON.deserialize(
      resultJSON,
      SquareProcessor.PaymentResponse.class
    );

    System.assertEquals(1000, result.payment.amount_money.amount);
    System.assertEquals('COMPLETED', result.payment.status);
  }

  @IsTest
  static void getter_Tests() {
    Square_Setting__mdt settings = [
      SELECT ApplicationId__c, AuthToken__c, LocationId__c, Version__c, PaymentEndpoint__c, Payment_Form_JS__c
      FROM Square_Setting__mdt
      WHERE IsSandbox__c = :runningInASandbox
    ];
    SquarePaymentForm_Controller ctr = new SquarePaymentForm_Controller();

    System.assertEquals(settings.ApplicationId__c, ctr.getApplicationId());
    System.assertEquals(settings.Payment_Form_JS__c, ctr.getPaymentFormJsUrl());
    System.assertEquals(settings.LocationId__c, ctr.getLocationId());
  }
}
