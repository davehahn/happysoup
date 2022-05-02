@RestResource(urlMapping='/Ecwid/events')
global without sharing class EcwidEvents{

    @HttpPost
    global static void process() {
        Rest_Service_Log__c serviceLog ;
        try{
            RestRequest  request = RestContext.request;
            RestResponse response = RestContext.response;
            System.debug('JSON.serializePretty( request )= '+JSON.serializePretty( request ));
            //serviceLog = EcwidRestUtils.ServiceLog(request);

            EcwidRestCommon.RequestPayloadModel requestPayloadModel = ( EcwidRestCommon.RequestPayloadModel ) JSON.deserialize(JSON.serializePretty( request ) ,  EcwidRestCommon.RequestPayloadModel .class);
            requestPayloadModel.body = EcwidRestUtils.parseRequest(requestPayloadModel.requestBody);
            System.debug('requestPayloadModel = '+requestPayloadModel );
            requestPayloadModel.headers.XEcwidWebhookSignature = EcwidRestUtils.parseHeader(JSON.serialize( request ));
            System.debug('Signature= '+requestPayloadModel.headers.XEcwidWebhookSignature);
            //EcwidRestUtils.ecvidEvent(serviceLog,requestPayloadModel.body );
			EcwidRestUtils.storeId = requestPayloadModel.body.storeId;
            if(EcwidRestUtils.verifySignature(requestPayloadModel.headers.XEcwidWebhookSignature, requestPayloadModel.body )){
                response.statusCode = 200;
                //if(requestPayloadModel.body)
                System.debug('requestPayloadModel.body .eventType= '+requestPayloadModel.body.eventType);
                System.debug('requestPayloadModel.body .storeId= '+requestPayloadModel.body.storeId);
                serviceLog = EcwidRestUtils.ServiceLog(request,requestPayloadModel.body);
//                EcwidOrderService.updateOrders(requestPayloadModel.body.entityId);
                
//                 EcwidRestUtils.ecvidEvent(serviceLog,requestPayloadModel.body );  
//                 switch on requestPayloadModel.body .eventType {
//                    when 'order.updated'{       
//                       //Business logic
//                       EcwidOrderService.updateOrders(requestPayloadModel.body.entityId);
//                    }   
//                    when 'product.updated'{    
//                         
//                         //Business logic //Business logic
//                    }
//                    when else {  
//                        response.statusCode = 400;
//                        
//                    }    
//                 }

            }else{
                //signature is not verified
                response.statusCode = 400;
            }

        }catch(Exception e){
            System.debug(e);
            // if (null != serviceLog){
            //     serviceLog.Error__c = e.getMessage();
            //     update serviceLog;
            // } 
        }
    }

}