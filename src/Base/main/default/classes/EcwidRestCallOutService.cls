public without sharing class EcwidRestCallOutService {

    public static String  ecwidCallOut(String api,String itemId,String body){
//        String method,String body,String token,

       /* HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        EcwidAPI__mdt ecwidApiSetting;
        System.debug('EcwidRestUtils.ApiSettingMap= '+EcwidRestUtils.ApiSettingMap);
        if(EcwidRestUtils.ApiSettingMap.containsKey(api))
            ecwidApiSetting = EcwidRestUtils.ApiSettingMap.get(api);

        System.debug('url = '+EcwidRestUtils.setting.base_URL__c+EcwidRestUtils.setting.Store_Id__c+ecwidApiSetting.URL__c+'/'+itemId+'?token='+(ecwidApiSetting.Require_Secret_Key__c ?EcwidRestUtils.setting.Secret_Key__c:EcwidRestUtils.setting.Public_Key__c) );
        System.debug('ecwidApiSetting.Method__c= '+ecwidApiSetting.Method__c);
       // req.setEndpoint(EcwidRestUtils.setting.base_URL__c+EcwidRestUtils.setting.Store_Id__c+ecwidApiSetting.URL__c+'/'+itemId+'?token='+(ecwidApiSetting.Require_Secret_Key__c ?EcwidRestUtils.setting.Secret_Key__c:EcwidRestUtils.setting.Public_Key__c) );
       // req.setMethod(ecwidApiSetting.Method__c);
        req.setEndpoint('https://app.ecwid.com/api/v3/63103347/orders/HKF37?token=secret_hrNwHfhuHc49b1qsGAyfFwF5FsFaAkk7');
		req.setMethod('PUT');
        if(body != null){
           // System.debug('### req= '+body.indexOf('['));
          //  body=body.substring(body.indexOf('{'),body.indexOf('}')+1);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept','application/json');
            req.setHeader('Host', 'app.ecwid.com');
            req.setBody('{"billingPerson":{"name":"Eugene K","companyName":"Hedgehog and Bucket","street":"My Street","city":"San Diego","countryCode":"US","postalCode":"90002","stateOrProvinceCode":"CA","phone":"123141321"}}');    
        }
        
//           req.setHeader('token', token);
        req.setCompressed(true); // otherwise we hit a limit of 32000
        try {
            System.debug('Req body= '+req.getBody());
            res = http.send(req);
            System.debug('after call out');
            if(null != res.getBody()){
              //  System.debug('@@@ index= '+res.indexOf('['));
                System.debug('@@ response = '+res);
                System.debug('@@ response body = '+res.getBody());
               System.debug('@@ status = '+res.getStatus());
                return  res.getBody();
            }
            */
            /////////////////
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            Http http = new Http();
        	EcwidAPI__mdt ecwidApiSetting;
        	if(EcwidRestUtils.ApiSettingMap.containsKey(api))
            	ecwidApiSetting = EcwidRestUtils.ApiSettingMap.get(api);
        	
            //req.setEndpoint('https://app.ecwid.com/api/v3/63103347/orders/HKF37?token=secret_hrNwHfhuHc49b1qsGAyfFwF5FsFaAkk7');
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

            
        /*}catch(Exception e){
            System.debug(e);
        }*/
        return res.getBody();
    }

}