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
   // if( !Test.isRunningTest() )
   // {
      try
      {
        new Flow.Interview.Update_Square_Transaction( params ).start();
      }
      catch( Exception e )
      {
        throw new SquareProcessor.SquareException(e.getMessage());
      }
//    }
  }


//  public void start() {
//    squareCaptureDate = ApexPages.CurrentPage().getParameters().get('sqCaptureDate');
//    squareOrderId = ApexPages.CurrentPage().getParameters().get('sqOrderId');
//    squareReceiptURL = ApexPages.CurrentPage().getParameters().get('sqReceiptURL');
//    squareReceiptNum = ApexPages.CurrentPage().getParameters().get('sqReceiptNum');
//    Map<String, Object> myMap = new Map<String, Object>();
//    myMap.put('recordId', currentRecordId);
//    myMap.put('sqOID', squareOrderId);
//    myMap.put('PaymentCompleteDate', squareCaptureDate);
//    myMap.put('receiptURL', squareReceiptURL);
//    myMap.put('receiptNum', squareReceiptNum);
////    if( !Test.isRunningTest() )
////    {
//      squareFlow = new Flow.Interview.Update_Square_Transaction(myMap);
//      squareFlow.start();
////    }
//  }
}