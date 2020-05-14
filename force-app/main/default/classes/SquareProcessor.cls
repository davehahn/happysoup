/**
 * Created by dave on 2020-04-22.
 */

public with sharing class SquareProcessor
{
  public class SquareException extends Exception {}

  private static Boolean inSandbox
  {
    get
    {
      if (inSandbox == null)
      {
        inSandbox = Test.isRunningTest() || LGND_Constants.runningInASandbox;
      }
      return inSandbox;
    }
    private set{}
  }

  private static Square_Setting__mdt squareSettings
  {
    get
    {
      if( squareSettings == null )
      {
        try
        {
          squareSettings = [
            SELECT ApplicationId__c, AuthToken__c, Version__c, PaymentEndpoint__c
            FROM Square_Setting__mdt
            WHERE IsSandbox__c = :inSandbox
          ];
        }
        catch( Exception e )
        {
          String env = inSandbox ? 'Sandbox' : 'Product';
          throw new SquareException( 'Square setting for ' + env + ' not found. Please contact your administrator' );
        }
      }
      return squareSettings;
    }
    private set{}
  }

  public SquareProcessor()
  {
  }

  public PaymentResponse postPayment( Decimal amount, String nonce )
  {
    //Square only handle cents
    amount = amount * 100;
    String jsonData = JSON.serialize( new Payment( amount, nonce ) );
    jsonData = jsonData.replace('"currency_type":', '"currency":');
    System.debug( jsonData );
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint( squareSettings.PaymentEndpoint__c );
    request.setMethod( 'POST' );
    request.setHeader( 'Authorization', 'Bearer ' + squareSettings.AuthToken__c );
    request.setHeader( 'Content-Type', 'application/json' );
    request.setHeader( 'Square-Version', squareSettings.Version__c );
    request.setBody( jsonData );

    try
    {
      HttpResponse response = http.send(request);
      String jsonResponse = response.getBody();
      jsonResponse = jsonResponse.replace('"currency":', '"currency_type":');
      PaymentResponse r = (PaymentResponse)JSON.deserialize( jsonResponse, PaymentResponse.class );
      return r;
    }
    catch( System.CalloutException e )
    {
      System.debug( 'Callout error: '+ e );
      System.debug( request.toString() );
      return null;
    }

  }

  public static String getApplicationId()
  {
    return squareSettings.ApplicationId__c;
  }

  public class Payment {
    public String idempotency_key;
    public String source_id;
    public PaymentAmount amount_money;
    public Payment( Decimal amount, String nonce )
    {
      this.idempotency_key = LGND_Utilities.generateRandomString( 22 );
      this.source_id = nonce;
      this.amount_money = new PaymentAmount( amount );
    }
  }


  public class PaymentResponse {
    public List<PaymentError> errors;
    public PaymentResult payment;
    public PaymentResponse(){}
  }

  public class PaymentResult {
    public String id;
    public DateTime created_at;
    public DateTime updated_at;
    public PaymentAmount amount_money;
    public String status;
    public String source_type;
    public PaymentCardDetails card_details;
    public String location_id;
    public String order_id;
    public PaymentAmount total_money;
    public String receipt_number;
    public String receipt_url;
    public PaymentResult(){}
  }

  public class PaymentError
  {
    public String code;
    public String detail;
    public String category;
    public PaymentError(){}
  }

  public class PaymentAmount {
    public Decimal amount;
    public String currency_type;
    public PaymentAmount(){}
    public PaymentAmount( Decimal amount )
    {
      this.amount = amount;
      this.currency_type = 'CAD';
    }
  }

  public class PaymentCardDetails {
    public String status;
    public PaymentCard card;
    public String entry_method;
    public String cvv_status;
    public String avs_status;
    public String statement_description;
    public PaymentCardDetails(){}
  }

  public class PaymentCard {
    public String card_brand;
    public String last_4;
    public Integer exp_month;
    public Integer exp_year;
    public String fingerprint;
    public String card_type;
    public String bin;
    public PaymentCard(){}
  }
}
