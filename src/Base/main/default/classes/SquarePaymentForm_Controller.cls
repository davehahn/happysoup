/**
 * Created by dave on 2020-04-21.
 */

global with sharing class SquarePaymentForm_Controller {
  public String pageLang { get; set; }
  private SquareProcessor sqProcessor {
    get {
      if( sqProcessor == null ){
        sqProcessor = SquareProcessor.getInstance();
      }
      return sqProcessor;
    }
    set{}
  }

  public SquarePaymentForm_Controller() {
    String currentLanguage = ApexPages.currentPage().getParameters().get('currentLanguage');
    this.pageLang = currentLanguage != null && currentLanguage == 'french' ? 'fr' : 'en_US';
  }

  @RemoteAction
  global static String postToSquare(Decimal paymentAmount, String referenceId, String token) {
    SquareProcessor square = new SquareProcessor();
    return JSON.serialize(square.postPayment(paymentAmount, referenceId, token));
  }

  public String getApplicationId() {
    return this.sqProcessor.getAppId();
  }

  public String getLocationId() {
    return this.sqProcessor.getLocId();
  }

  public String getPaymentFormJsUrl() {
    return this.sqProcessor.getFormJsUrl();
  }
}
