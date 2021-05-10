@RestResource(urlMapping='/v1/product-options/*')
global class LGND_APIv1_Product_Options {

  static Id pricebookId;
  static {
    pricebookId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
  }

  @HttpGet
  global static void getOptioanlProducts()
  {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    res.addHeader('Content-Type', 'application/json');
    String callback = req.params.get('callback');
    String jsonResponse = '';
    JSONGenerator json_gen = JSON.createGenerator(true);

    String productId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);

    try
    {
      if( productId == null )
      {
         jsonResponse = '{}';
      }
      else
      {
        Product2[] optionalProducts = [SELECT ID, Name, RecordType.Name, Default_Gallery_Image__c,
                                      (SELECT Id, UnitPrice, Pricebook2.Name
                                       FROM PricebookEntries
                                       WHERE isActive = true
                                       AND Pricebook2.isActive = true),
                                      (SELECT Id, Standard__c, Maximum__c FROM From_Product_Options__r WHERE To_Product__c = :productId LIMIT 1)
                                     FROM Product2
                                     WHERE Id IN (SELECT From_Product__c
                                                  FROM Product_Option__c
                                                  WHERE To_Product__c = :productId ) ];
        Boat.PartProduct[] parts = new List<Boat.PartProduct>();
        for( Product2 p : optionalProducts )
        {
          parts.add( new Boat.PartProduct(p) );
        }
        json_gen.writeStartArray();
        json_gen.writeObject(parts);
        json_gen.writeEndArray();
        jsonResponse = json_gen.getAsString();
      }
      res.statusCode = 200;
      if(callback != null)
      {
          jsonResponse = callback + '(' + jsonResponse + ')';
      }
      res.responseBody = blob.valueOf(jsonResponse);
      return;
    }
    catch(Exception ex)
    {
      res.statusCode = 500;
      jsonResponse = '{"json_gen": {"status": "Failure", "message": "' + ex.getMessage() + '" }}';
      res.responseBody = blob.valueOf(jsonResponse);
      return;
    }

  }

}