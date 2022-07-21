@RestResource(urlMapping='/*/*/motors/*')
global with sharing class LGND_API_Motors {
  public class MotorAPIException extends Exception {
  }

  //static Id retailPricebookId;
  //static Id partnerPricebookId;
  //static Map<Id, String> pricebookMap;
  static Set<String> validAPIVersions = new Set<String>{ 'v1', 'v2' };
  static Set<String> validAPITypes = new Set<String>{ 'retail', 'partner', 'dev-retail' };
  //static {
  //  pricebookMap = new Map<Id, String>();
  //  pricebookMap.put(Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c, 'retail');
  //  pricebookMap.put(Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c, 'partner');
  //  retailPricebookId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
  //  partnerPricebookId = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;
  //}

  @HttpGet
  global static void fetchMotors() {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    res.addHeader('Content-Type', 'application/json');
    String callback = req.params.get('callback');
    String jsonResponse = '';
    JSONGenerator json_gen = JSON.createGenerator(true);

    String motorId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
    String apiVersion = req.requestURI.removeStart('/').split('/')[0];
    String apiType = req.requestURI.removeStart('/').split('/')[1];

    try {
      if (!validAPIVersions.contains(apiVersion)) {
        throw new MotorAPiException('invalid Api Version Specified ' + apiVersion);
      }
      if (!validAPITypes.contains(apiType)) {
        throw new MotorAPiException('invalid Api Type Specified ' + apiType);
      }
      if (motorId.length() > 0 && motorId != 'motors') {
        if (apiVersion == 'v1') {
          LGND_APIv1_Product motor = new LGND_APIv1_Product(motorId, apiType, 'Motor');
          if (motor.Id == null) {
            jsonResponse = '{}';
          } else {
            json_gen.writeObject(motor);
            jsonResponse = json_gen.getAsString();
          }
        }
        if (apiVersion == 'v2') {
          LGND_APIv2_Product motor = new LGND_APIv2_Product(motorId, apiType, 'Motor');
          if (motor.Id == null) {
            jsonResponse = '{}';
          } else {
            json_gen.writeObject(motor);
            jsonResponse = json_gen.getAsString();
          }
        }
      } else {
        jsonResponse = LGND_API.productsJSON('Motor', apiType);
      }

      res.statusCode = 200;
      if (callback != null) {
        jsonResponse = callback + '(' + jsonResponse + ')';
      }
      res.responseBody = blob.valueOf(jsonResponse);
      return;
    } catch (Exception ex) {
      res.statusCode = 500;
      jsonResponse =
        '{"json_gen": {"status": "Failure", "message": "' +
        ex.getMessage() +
        '", "stackTrace": "' +
        ex.getStackTraceString().escapeUnicode() +
        '" }}';
      res.responseBody = blob.valueOf(jsonResponse);
      return;
    }
  } // fetchboats
}
