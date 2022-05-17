public without sharing class  EcwidOrderService{
    
    @future(callout=true)
    static void processOrder(id ServiceLogId, String orderId,String storeId){
        //List<Rest_Service_Log__c> serviceLogList =new List<Rest_Service_Log__c>();
        Rest_Service_Log__c serviceLogToInsert = new Rest_Service_Log__c();
        Rest_Service_Log__c serviceLogToUpdate = new Rest_Service_Log__c(); 
        EcwidRestUtils.storeId = storeId;
        System.debug('StoreId from flow= '+storeId);
        try{
            EcwidRestUtils.init();
            String strResponse = EcwidRestCallOutService.ecwidCallOut('Order',orderId,null);
            //,'GET',null,'secret_hrNwHfhuHc49b1qsGAyfFwF5FsFaAkk7','GCE5A',   
            System.debug('@@ response= '+strResponse);
            proessCustomerData(strResponse);
            serviceLogToUpdate.id = ServiceLogId;
            serviceLogToUpdate.Is_Processed__c = true;
            serviceLogToInsert.Response__c = strResponse;

        }catch(Exception e){
            System.debug(e);
            serviceLogToUpdate.Is_Processed__c = false;
            serviceLogToUpdate.Error__c =  EcwidRestUtils.getExceptionDetail(e);
        }
        serviceLogToInsert.Parent_Service_Log__c = ServiceLogId;
        serviceLogToInsert.recordTypeId =  Schema.SObjectType.Rest_Service_Log__c.getRecordTypeInfosByDeveloperName().get('Ecwid_Outbound').getRecordTypeId();

        upsert new List<Rest_Service_Log__c>{serviceLogToUpdate,serviceLogToInsert};
    }

    @InvocableMethod(label='Ecwid Update Orders' category='CallOut')
    public static void updateOrders(List<Request> inuputParamList){
        processOrder(inuputParamList[0].serviceLogId,inuputParamList[0].orderId,inuputParamList[0].storeId);
    }

   /*
	* Order has been processed if the Order status is not 'DELIVERED'
	*/ 
       
   public static void proessCustomerData(String strResponse){
       
       Customer customer = new Customer();
       AcctSeedERP__Sales_Order__c salesOrder;
       Account accountForOrder = new Account();
       
       EcwidOrderMessageProcessing orderMessageProcessing = new EcwidOrderMessageProcessing(strResponse);
       
     // Order has been processed if the Order status is not 'DELIVERED'
        if(orderMessageProcessing.checkOrderStatus()){
            orderMessageProcessing.prepareAccountObject();
            List<sObject> lstSobject = orderMessageProcessing.findDuplicateAccount();
            List <AcctSeedERP__Sales_Order__c> lstSalesOrder = orderMessageProcessing.checkExistingSalesOrder();
            
            if(!lstSobject.isEmpty() && lstSobject.size()>0){
                orderMessageProcessing.updateAccount((Account)lstSobject[0]);
                accountForOrder = (Account)lstSobject[0]; 
            }else {
                Lead lead = orderMessageProcessing.ceateLead();
                Customer.Person person = new  Customer.Person(lead);
                person.revertToLead();
                Customer.AccountSaveResult accResult = person.convertLead('lead');
                accountForOrder = accResult.record;
            }
            salesOrder = orderMessageProcessing.createSalesOrder(accountForOrder,lstSalesOrder!=null && ! lstSalesOrder.isEmpty() ? lstSalesOrder[0] : new AcctSeedERP__Sales_Order__c() );
          	System.debug('salesOrder= '+salesOrder);
            //List<AcctSeed__Billing__c> lstBilling = orderMessageProcessing.Billing(new List<AcctSeedERP__Sales_Order__c>{salesOrder});
            //orderMessageProcessing.billingCashReceipt(lstBilling);

            Ecwid_Sales_Order__e evt = new Ecwid_Sales_Order__e(
                    Status__c = true,
                    Sales_Order_Id__c = salesOrder.id
            );
            Database.SaveResult result = EventBus.publish( evt );

            // Inspect publishing result for each event
            if (result.isSuccess()) {
                System.debug('Successfully published event SO Ecwid.');
            } else {
                for(Database.Error err : result.getErrors()) {
                    System.debug('Error returned: ' +
                            err.getStatusCode() +
                            ' - ' +
                            err.getMessage());
                }
            }
            //List<AcctSeedERP__Sales_Order__c>lstSalesOrderForCashReceipt = [Select Id,AcctSeedERP__Customer__c,GL_Account_Variable_1__c,GL_Account_Variable_2__c,AcctSeedERP__Total__c,Name from AcctSeedERP__Sales_Order__c where Id = :salesOrder.id];
    	
            //SalesOrder_Service.generateCashReceipt(lstSalesOrderForCashReceipt);
            
        }
    }
   
    public class Response{
        @InvocableVariable(Required=true)
        public boolean success;
        @InvocableVariable
        public String error;
        @InvocableVariable
        public String ResponsePayload;
        @InvocableVariable
        public String RequestPayload;

        public Response(boolean success){
            this.success=success;
        }
    }
    
    public class Request{
        @InvocableVariable(Required=true)
        public Id serviceLogId;
        @InvocableVariable(Required=true)
        public String orderId;
        @InvocableVariable(Required=true)
        public String storeId;

    }

//    @InvocableMethod(label = 'Ecwid Update Orders'category= 'CallOut')
//    public static List<Response> updateOrders(List<String> orderIdList) {
//        Response output;
//        try {
//            String strResponse = EcwidRestCallOutService.ecwidCallOut('Order', 'GCE5A');
//            ,'GET', null, 'secret_hrNwHfhuHc49b1qsGAyfFwF5FsFaAkk7', 'GCE5A',
//            System.debug('@@ response= ' + strResponse);
//
//            EcwidOrderMessageProcessing order = new EcwidOrderMessageProcessing(strResponse);
//            order.createAccount();
//            List<sObject> sobjectList = order.findDuplicateAccount();
//            Customer customer;
//
//            if (!sobjectList.isEmpty()) {
//                customer = new Customer((Account) sobjectList[0]);
//                Customer.Person person = new Customer.Person((Account) sobjectList[0]);
//                person.convertLeadForEcwid('account');
//            } else {
//                customer = new Customer();
//                Lead lead = new Lead(FirstName = 'Test',
//                        LastName = 'lname',
//                        LeadSource = 'email',
//                        Email = 'test@mail.com'
//                );
//                insert lead;
//                Customer.Person person = new Customer.Person(lead);
//                // customer.theLead =lead;
//                person.revertToLead();
//                person.convertLeadForEcwid('lead');
//            }
//            Customer.AccountSaveResult result = person.upsertRecord();
//            Business logic functions will be called here
//
//            Map<String, Object> return_map = order.processData(null);
//            System.debug('@@after: ' + return_map);
//            output = new Response(true);
//            output.ResponsePayload = strResponse;
//            output.RequestPayload = '';
//
//        } catch (Exception e) {
//            output = new Response(false);
//            output.error = EcwidRestUtils.getExceptionDetail(e);
//        }
//        return new List<Response> {
//            output
//        } ;
//    }

}
