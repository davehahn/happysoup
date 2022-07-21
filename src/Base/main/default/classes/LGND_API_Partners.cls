@RestResource(urlMapping='/*/partners')
global with sharing class LGND_API_Partners {
  public class PartnerAPIException extends Exception {
  }

  static Set<String> validAPIVersions = new Set<String>{ 'v1', 'v2' };

  @HttpGet
  global static void fetchPartners() {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    res.addHeader('Content-Type', 'application/json');
    String callback = req.params.get('callback');
    String jsonResponse = '';
    JSONGenerator json_gen = JSON.createGenerator(true);

    String apiVersion = req.requestURI.removeStart('/').split('/')[0];

    try {
      if (!validAPIVersions.contains(apiVersion)) {
        throw new PartnerAPIException('Invalid Api Version Specified ' + apiVersion);
      }
      jsonResponse = buildPartnersJSON();
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
  }

  private static String buildPartnersJSON() {
    Id dealerRtId = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer');
    JSONGenerator json_gen = JSON.createGenerator(true);
    //start JSON object
    json_gen.writeStartArray();
    for (Account acct : [
      SELECT
        Id,
        Name,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingCountry,
        BillingPostalCode,
        BillingLatitude,
        BillingLongitude,
        Fax,
        Phone,
        AccountEmail__c
      FROM Account
      WHERE Active__c = TRUE AND Type = 'Dealer' AND RecordTypeId = :dealerRtId
      ORDER BY Name
    ]) {
      json_gen.writeStartObject();
      json_gen.writeStringField('id', acct.Id);
      json_gen.writeStringField('name', acct.Name);
      json_gen.writeStringField('street', acct.BillingStreet == null ? '' : acct.BillingStreet);
      json_gen.writeStringField('city', acct.BillingCity == null ? '' : acct.BillingCity);
      json_gen.writeStringField('province', acct.BillingState == null ? '' : acct.BillingState);
      json_gen.writeStringField('country', acct.BillingCountry == null ? '' : acct.BillingCountry);
      json_gen.writeStringField('postalCode', acct.BillingPostalCode == null ? '' : acct.BillingPostalCode);
      if (acct.BillingLongitude == null)
        json_gen.writeNullField('longitude');
      else
        json_gen.writeNumberField('longitude', acct.BillingLongitude);

      if (acct.BillingLatitude == null)
        json_gen.writeNullField('latitude');
      else
        json_gen.writeNumberField('latitude', acct.BillingLatitude);

      json_gen.writeStringField('phone', acct.Phone == null ? '' : acct.Phone);
      json_gen.writeStringField('fax', acct.Fax == null ? '' : acct.Fax);
      json_gen.writeStringField('email', acct.AccountEmail__c == null ? '' : acct.AccountEmail__c);
      json_gen.writeEndObject();
    }
    json_gen.writeEndArray();
    return json_gen.getAsString();
  }
}
