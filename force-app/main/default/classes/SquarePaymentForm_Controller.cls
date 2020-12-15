/**
 * Created by dave on 2020-04-21.
 */

global with sharing class SquarePaymentForm_Controller
{

  public String pageLang { get; set; }

  public SquarePaymentForm_Controller()
  {
    String currentLanguage = ApexPages.currentPage().getParameters().get('currentLanguage');
    this.pageLang = currentLanguage != null && currentLanguage == 'french' ? 'fr' : 'en_US';
  }

  @RemoteAction
  global static String postToSquare( Decimal paymentAmount, String referenceId, String token )
  {
    SquareProcessor square = new SquareProcessor();
    return JSON.serialize( square.postPayment( paymentAmount, referenceId, token ) );
  }

  public String getApplicationId()
  {
    return SquareProcessor.getApplicationId();
  }

  public String getPaymentFormJsUrl()
  {
    return SquareProcessor.getPaymentFormJsUrl();
  }


}

