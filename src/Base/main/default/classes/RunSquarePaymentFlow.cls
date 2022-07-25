public without sharing class RunSquarePaymentFlow {
  //Instance of the Flow
  public Flow.Interview.Update_Square_Transaction squareFlow { get; set; }
  public Double value { get; set; }
  public String currentRecordId { get; set; }
  public String squareOrderId { get; set; }
  public String squareCaptureDate { get; set; }
  public String squareReceiptURL { get; set; }
  public String squareReceiptNum { get; set; }

  public RunSquarePaymentFlow(ApexPages.StandardController controller) {
    currentRecordId = ApexPages.CurrentPage().getparameters().get('id');
  }

  @RemoteAction
  public static void finalizeSquarePayment(
    String recordId,
    String sqCaptureDate,
    String sqOrderId,
    String sqReceiptURL,
    String sqReceiptNum
  ) {
    Map<String, String> params = new Map<String, String>{
      'recordId' => recordId,
      'sqOID' => sqOrderId,
      'PaymentCompleteDate' => sqCaptureDate,
      'receiptURL' => sqReceiptURL,
      'receiptNum' => sqReceiptNum
    };

    //    Square_Transaction__c sqTrans = new Square_Transaction__c(
    //      Id = recordId,
    //      sqCreateDate__c = Date.valueOf( sqCaptureDate ),
    //      sqOrderId__c = sqOrderId,
    //      sqReceiptURL__c = sqReceiptURL,
    //      sqReceiptNumber__c = sqReceiptNum,
    //      sqStatus__c = 'COMPLETED'
    //    );
    //    update sqTrans;

    //if( !Test.isRunningTest() )
    //{
    try {
      TriggerHandler.bypass('SquareTransaction_TriggerHandler');
      new Flow.Interview.Update_Square_Transaction(params).start();
      TriggerHandler.clearBypass('SquareTransaction_TriggerHandler');
    } catch (Exception e) {
      throw new SquareProcessor.SquareException(e.getMessage());
    }
    //}
  }
}
