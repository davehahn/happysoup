@RestResource(urlMapping='/*/*/boats/*')
global with sharing class LGND_API_Boats {

  public class BoatAPIException extends Exception {}

  //static Id retailPricebookId;
  //static Id partnerPricebookId;
  //static Id devRetailPricebookId;
  //static Map<Id, String> pricebookMap;
  static Set<String> validAPIVersions = new Set<String>{'v1', 'v2'};
  static Set<String> validAPITypes = new Set<String>{'retail', 'partner', 'media-vault', 'dev-retail'};
  //static {
  //  retailPricebookId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
  //  partnerPricebookId = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;
  //  devRetailPricebookId = Legend_Settings__c.getOrgDefaults(),Dev_Retail_Pricebook__c;
  //  pricebookMap = new Map<Id, String>();
  //  pricebookMap.put(retailPricebookId, 'retail');
  //  pricebookMap.put(devRetailPricebookId, 'dev-retail');
  //  pricebookMap.put(partnerPricebookId, 'partner');
  //}

  @HttpGet
  global static void fetchBoats()
  {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    res.addHeader('Content-Type', 'application/json');
    String callback = req.params.get('callback');
    String jsonResponse = '';
    JSONGenerator json_gen = JSON.createGenerator(true);

    String boatId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
    String apiVersion = req.requestURI.removeStart('/').split('/')[0];
    String apiType = req.requestURI.removeStart('/').split('/')[1];

    try {
      if( !validAPIVersions.contains(apiVersion) )
      {
        throw new BoatAPiException('invalid Api Version Specified ' + apiVersion);
      }
      if( !validAPITypes.contains(apiType) )
      {
        throw new BoatAPiException('invalid Api Type Specified ' + apiType);
      }
      if( boatId.length() > 0 && boatId != 'boats')
      {
        if( apiVersion == 'v1' )
        {
          LGND_APIv1_Product boat = new LGND_APIv1_Product(boatId, apiType, 'Boat');
          if(boat.Id == null)
          {
            jsonResponse = '{}';
          }
          else
          {
            json_gen.writeObject(boat);
            jsonResponse = json_gen.getAsString();
          }
        }
        if( apiVersion == 'v2' )
        {
          LGND_APIv2_Product boat = new LGND_APIv2_Product(boatId, apiType, 'Boat');
          if(boat.Id == null)
          {
            jsonResponse = '{}';
          }
          else
          {
            json_gen.writeObject(boat);
            jsonResponse = json_gen.getAsString();
          }
        }
      }
      else
      {
        jsonResponse = LGND_API.productsJSON('Boat', apiType);
      }

      res.statusCode = 200;
      if(callback != null) {
          jsonResponse = callback + '(' + jsonResponse + ')';
      }
      res.responseBody = blob.valueOf(jsonResponse);
      return;

    } catch ( Exception ex ) {
        res.statusCode = 500;
        jsonResponse = '{"json_gen": {"status": "Failure", "message": "' + ex.getMessage() + '", "stackTrace": "' + ex.getStackTraceString().escapeUnicode() + '" }}';
        res.responseBody = blob.valueOf(jsonResponse);
        return;
    }

  }// fetchboats

}