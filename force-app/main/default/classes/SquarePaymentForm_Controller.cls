/**
 * Created by dave on 2020-04-21.
 */

global with sharing class SquarePaymentForm_Controller
{

  public SquarePaymentForm_Controller(){}

  @RemoteAction
  global static String postToSquare( Decimal paymentAmount, String token )
  {
    SquareProcessor square = new SquareProcessor();
    return JSON.serialize( square.postPayment( paymentAmount, token ) );
  }

  public String getApplicationId()
  {
    return SquareProcessor.getApplicationId();
  }

}