@RestResource(urlMapping='/*/*/trailers/*')
global with sharing class LGND_API_Trailers {

  public class TrailerAPIException extends Exception {}

  //static Id retailPricebookId;
  //static Id partnerPricebookId;
  //static Map<Id, String> pricebookMap;
  static Set<String> validAPIVersions = new Set<String>{'v1', 'v2'};
  static Set<String> validAPITypes = new Set<String>{'retail', 'partner', 'dev-retail'};
  //static {
  //  pricebookMap = new Map<Id, String>();
  //  pricebookMap.put(Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c, 'retail');
  //  pricebookMap.put(Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c, 'partner');
  //  retailPricebookId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
  //  partnerPricebookId = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;
  //}

  @HttpGet
  global static void fetchTrailers()
  {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    res.addHeader('Content-Type', 'application/json');
    String callback = req.params.get('callback');
    String jsonResponse = '';
    JSONGenerator json_gen = JSON.createGenerator(true);

    String trailerId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
    String apiVersion = req.requestURI.removeStart('/').split('/')[0];
    String apiType = req.requestURI.removeStart('/').split('/')[1];

    try {
      if( !validAPIVersions.contains(apiVersion) )
      {
        throw new TrailerAPiException('invalid Api Version Specified ' + apiVersion);
      }
      if( !validAPITypes.contains(apiType) )
      {
        throw new TrailerAPiException('invalid Api Type Specified ' + apiType);
      }
      if( trailerId.length() > 0 && trailerId != 'trailers')
      {
        if( apiVersion == 'v1' )
        {
          LGND_APIv1_Product trailer = new LGND_APIv1_Product(trailerId, apiType, 'Trailer');
          if(trailer.Id == null)
          {
            jsonResponse = '{}';
          }
          else
          {
            json_gen.writeObject(trailer);
            jsonResponse = json_gen.getAsString();
          }
        }
        if( apiVersion == 'v2' )
        {
          LGND_APIv2_Product trailer = new LGND_APIv2_Product(trailerId, apiType, 'Trailer');
          if(trailer.Id == null)
          {
            jsonResponse = '{}';
          }
          else
          {
            json_gen.writeObject(trailer);
            jsonResponse = json_gen.getAsString();
          }
        }
      }
      else
      {
        jsonResponse = LGND_API.productsJSON('Trailer', apiType);
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