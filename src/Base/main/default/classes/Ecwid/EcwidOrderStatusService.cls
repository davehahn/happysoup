public without sharing class EcwidOrderStatusService {
  @InvocableMethod(label='Ecwid Update Order Status' category='UpdateStatus')
  public static void updateOrderStatus(List<OrderStatusRequest> inuputParamList) {
    updateOrderStatus(
      inuputParamList[0].ecwidOrderId,
      inuputParamList[0].orderId,
      inuputParamList[0].stage,
      inuputParamList[0].storeId,
      inuputParamList[0].paymentStatus
    );
  }

  @future(callout=true)
  static void updateOrderStatus(String ecwidOrderId, Id orderId, String stage, String storeId, String paymentStatus) {
    Rest_Service_Log__c serviceLogToUpdate = new Rest_Service_Log__c();
    try {
      EcwidRestUtils.storeId = storeId;
      EcwidRestUtils.init();
      Body body = new Body();
      body.fulfillmentStatus = stage; //'DELIVERED';
      body.paymentStatus = paymentStatus;
      String reqBody = JSON.serialize(body);
      EcwidRestCallOutService.ecwidCallOut('Order_Status_Update', ecwidOrderId, reqBody);
    } catch (Exception e) {
      System.debug(e);
      serviceLogToUpdate.Is_Processed__c = false;
      serviceLogToUpdate.Error__c = EcwidRestUtils.getExceptionDetail(e);
    }
  }

  public class OrderStatusRequest {
    @InvocableVariable(Required=true)
    public Id orderId;
    @InvocableVariable(Required=true)
    public String ecwidOrderId;
    @InvocableVariable(Required=true)
    public String stage;
    @InvocableVariable(Required=true)
    public String storeId;
    @InvocableVariable(Required=true)
    public String paymentStatus;
  }

  public class Body {
    String fulfillmentStatus { get; set; }
    String paymentStatus { get; set; }
  }
}
