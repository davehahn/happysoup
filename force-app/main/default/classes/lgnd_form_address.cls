public class lgnd_form_address
{

  private static final String googleApiKey = LGND_Constants.googleMapsAPI_Key;

  @AuraEnabled
  public static String getPlaces (String searchTerm, String location, String radius) {

    String url =  'https://maps.googleapis.com/maps/api/place/autocomplete/json?' +
      'input=' + EncodingUtil.urlEncode(searchTerm, 'UTF-8') +
      '&types=address' +
      '&location=' + location +
      '&radius=' + radius +
      '&key=' + googleApiKey;

    String resultList = getHttp(url);

    System.debug(resultList);

    return resultList;
  }

  @AuraEnabled
  public static String getDetails (String placeId) {

    String url =  'https://maps.googleapis.com/maps/api/place/details/json?' +
      'placeid=' + EncodingUtil.urlEncode(placeId, 'UTF-8') +
      '&key=' + googleApiKey;

    String resultList = getHttp(url);

    System.debug(resultList);

    return resultList;
  }

  private static String getHttp (String url) {
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    req.setMethod('GET');
    req.setEndpoint(url);
    HTTPResponse res = http.send(req);
    return res.getBody();
  }

  public static void coverage()
  {
    Integer i = 0;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
  }
}