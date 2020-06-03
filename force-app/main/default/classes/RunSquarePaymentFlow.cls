public class RunSquarePaymentFlow {

  //Instance of the Flow
  public Flow.Interview.Update_Square_Transaction squareFlow {get; set;}
  public Double value {get; set;}
  public String currentRecordId {get; set;}
  public String squareOrderId{get; set;}
  public String squareCaptureDate{get; set;}
  public String squareReceiptURL{get; set;}
  public String squareReceiptNum{get; set;}

  public RunSquarePaymentFlow(ApexPages.StandardController controller) {
    currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
  }

  @RemoteAction
  public static void finalizeSquarePayment(
    String recordId,
    String sqCaptureDate,
    String sqOrderId,
    String sqReceiptURL,
    String sqReceiptNum )
  {
    Map<String, String> params = new Map<String, String>{
      'recordId' => recordId,
      'sqOID' => sqOrderId,
      'PaymentCompleteDate' => sqCaptureDate,
      'receiptURL' => sqReceiptURL,
      'receiptNum' => sqReceiptNum
    };
    System.debug( params );
    if( !Test.isRunningTest() )
    {
      try
      {
        new Flow.Interview.Update_Square_Transaction( params ).start();
      }
      catch( Exception e )
      {
        throw new SquareProcessor.SquareException(e.getMessage());
      }
    }
  }


}