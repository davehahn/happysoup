public without sharing class  EcwidOrderStatusService {
    
    @InvocableMethod(label='Ecwid Update Order Status' category='UpdateStatus')
    public static void updateOrderStatus(List<OrderStatusRequest> inuputParamList){
        updateOrderStatus(inuputParamList[0].ecwidOrderId,inuputParamList[0].orderId,inuputParamList[0].stage,inuputParamList[0].storeId,inuputParamList[0].paymentStatus);
    }
    
    @future(callout=true)
    static void updateOrderStatus(String ecwidOrderId, Id orderId,String stage,String storeId,String paymentStatus){
        //List<Rest_Service_Log__c> serviceLogList =new List<Rest_Service_Log__c>();
        Rest_Service_Log__c serviceLogToInsert = new Rest_Service_Log__c();
        Rest_Service_Log__c serviceLogToUpdate = new Rest_Service_Log__c();
        try{
           /* System.debug('in status update');
            EcwidRestUtils.init();
             System.debug('after init');
            Body body = new Body();
            System.debug('after body');
            body.fulfillmentStatus = 'DELIVERED';
            System.debug('after assignment');
            String reqBody = JSON.serialize(body);
            System.debug('after reqBody= '+reqBody);
            // String r = '{"fulfillmentStatus": "PROCESSING"}';
          //  System.debug('after r= '+r);
            String strResponse = EcwidRestCallOutService.ecwidCallOut('Order_Status_Update',ecwidOrderId,reqBody);
           
            //,'GET',null,'secret_hrNwHfhuHc49b1qsGAyfFwF5FsFaAkk7','GCE5A',
            System.debug('@@ response= '+strResponse);
            /*proessCustomerData(strResponse);
            serviceLogToUpdate.id = ServiceLogId;
            serviceLogToUpdate.Is_Processed__c = true;
            serviceLogToInsert.Response__c = strResponse;*/
            EcwidRestUtils.storeId = storeId;
            EcwidRestUtils.init();
            System.debug('after init');
            //String reqBody = '{"billingPerson":{"name":"Eugene K","companyName":"Hedgehog and Bucket","street":"My Street","city":"SanDiego","countryCode":"US","postalCode":"90002","stateOrProvinceCode":"CA","phone":"123141321"}}';
           	Body body = new Body();
            System.debug('after body');
            body.fulfillmentStatus = stage;//'DELIVERED';
            body.paymentStatus = paymentStatus;
           
            System.debug('after assignment');
            String reqBody = JSON.serialize(body);
            String strResponse = EcwidRestCallOutService.ecwidCallOut('Order_Status_Update',ecwidOrderId,reqBody);
            
        }catch(Exception e){
            System.debug(e);
            serviceLogToUpdate.Is_Processed__c = false;
            serviceLogToUpdate.Error__c =  EcwidRestUtils.getExceptionDetail(e);
        }
       // serviceLogToInsert.Parent_Service_Log__c = ServiceLogId;
       // serviceLogToInsert.recordTypeId =  Schema.SObjectType.Rest_Service_Log__c.getRecordTypeInfosByDeveloperName().get('Ecwid_Outbound').getRecordTypeId();

        //upsert new List<Rest_Service_Log__c>{serviceLogToUpdate,serviceLogToInsert};
    }
    
     public class OrderStatusRequest{
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
    
    public class Body{
        String fulfillmentStatus{get;set;}
        String paymentStatus{get;set;}
    }


}
