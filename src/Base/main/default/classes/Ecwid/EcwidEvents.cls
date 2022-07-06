@RestResource(urlMapping='/Ecwid/events')
global without sharing class EcwidEvents{

    @HttpPost
    global static void process() {
        Rest_Service_Log__c serviceLog ;
        try{
            RestRequest  request = RestContext.request;
            RestResponse response = RestContext.response;
            System.debug('JSON.serializePretty( request )= '+JSON.serializePretty( request ));
           
            EcwidRestCommon.RequestPayloadModel requestPayloadModel = ( EcwidRestCommon.RequestPayloadModel ) JSON.deserialize(JSON.serializePretty( request ) ,  EcwidRestCommon.RequestPayloadModel .class);
            requestPayloadModel.body = EcwidRestUtils.parseRequest(requestPayloadModel.requestBody);
            System.debug('requestPayloadModel = '+requestPayloadModel );
            requestPayloadModel.headers.XEcwidWebhookSignature = EcwidRestUtils.parseHeader(JSON.serialize( request ));
           	EcwidRestUtils.storeId = requestPayloadModel.body.storeId;
            if(EcwidRestUtils.verifySignature(requestPayloadModel.headers.XEcwidWebhookSignature, requestPayloadModel.body )){
                response.statusCode = 200;
                System.debug('requestPayloadModel.body .eventType= '+requestPayloadModel.body.eventType);
                System.debug('requestPayloadModel.body .storeId= '+requestPayloadModel.body.storeId);
                serviceLog = EcwidRestUtils.ServiceLog(request,requestPayloadModel.body);
            }else{
                //signature is not verified
                response.statusCode = 400;
            }

        }catch(Exception e){
            System.debug(e);
        }
    }

}