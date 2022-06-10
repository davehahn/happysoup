global without sharing class EcwidRestCommon {

    global class RequestPayloadModel{
        global String requestBody  { get; set; } 
        global Map<String,String> params { get; set; } 
        global RequestPayloadHeaders headers{ get; set; } 
        global String resourcePath { get; set; }
        global String requestURI { get; set; }
        global String remoteAddress { get; set; }
        global RequestPayloadBody body { get; set; }
           
        
    }
    
    global class RequestPayloadHeaders {
        global String XEcwidWebhookSignature ;
        
        //{ get; set; } 
    }
    
    global class RequestPayloadBody {
        global String eventId { get; set; } 
        global String eventCreated { get; set; } 
        global String storeId { get; set; } 
        global String entityId { get; set; }
        global String eventType { get; set; }
    }
    
     global class RequestPayloadData {
        global String oldPaymentStatus { get; set; } 
        global String newPaymentStatus { get; set; } 
        global String oldFulfillmentStatus { get; set; } 
        global String newFulfillmentStatus { get; set; }
     }
        
}