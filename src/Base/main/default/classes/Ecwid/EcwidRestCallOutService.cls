public without sharing class EcwidRestCallOutService {

    public static String  ecwidCallOut(String api,String itemId,String body){
            /////////////////
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            Http http = new Http();
        	EcwidAPI__mdt ecwidApiSetting;
        	if(EcwidRestUtils.ApiSettingMap.containsKey(api))
            	ecwidApiSetting = EcwidRestUtils.ApiSettingMap.get(api);

            req.setEndpoint(EcwidRestUtils.setting.base_URL__c+EcwidRestUtils.setting.Store_Id__c+ecwidApiSetting.URL__c+'/'+itemId+'?token='+(ecwidApiSetting.Require_Secret_Key__c ?EcwidRestUtils.setting.Secret_Key__c:EcwidRestUtils.setting.Public_Key__c) );
        	req.setMethod(ecwidApiSetting.Method__c);
        
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept','application/json');
            req.setHeader('Host', 'app.ecwid.com');
            if(body != null){
                req.setBody(body); 
            }    
        	// req.setCompressed(true);    
            res = http.send(req);
            System.debug('@@ response = '+res);
            System.debug('@@ response body = '+res.getBody());
        return res.getBody();
    }

}