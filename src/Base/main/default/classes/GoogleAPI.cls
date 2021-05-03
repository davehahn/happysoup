/**
 * Created by dave on 2019-10-31.
 */

public class GoogleAPI
{
  private static final String googleApiKey = LGND_Constants.googleMapsAPI_Key;

  public class GoogleDestinationsResult {
    public String[] destination_addresses;
    public String[] origin_addresses;
    public GoogleDestinationRow[] rows;
    public String status;

    public GoogleDestinationsResult(){}
  }

  public class GoogleDestinationRow {
    public GoogleDestinationElement[] elements;
    public GoogleDestinationRow(){}
  }

  public class GoogleDestinationElement {
    public Map<String,String> distance;
    public Map<String,String> duration;
    public String status;

    public GoogleDestinationElement(){}
  }

  public class DistanceMatrix
  {
    public String destinations;
    public String origin;


    public DistanceMatrix( String origin, String destinations )
    {
      this.destinations = destinations;
      this.origin = origin;
    }

    public GoogleDestinationsResult execute()
    {
      System.debug( googleApiKey );
      String url = 'https://maps.googleapis.com/maps/api/distancematrix/json?';
      url += 'origins='+EncodingUtil.urlEncode( this.origin, 'UTF-8')+',Canada';
      url += '&destinations=' + EncodingUtil.urlEncode( this.destinations, 'UTF-8');
      url += '&key=' + googleApiKey;
      String gResult = getHttp(url);
      System.debug( gResult );
      return (GoogleDestinationsResult)JSON.deserialize( gResult, GoogleDestinationsResult.class );
    }


  }

  private static String getHttp (String url) {
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    req.setMethod('GET');
    req.setEndpoint(url);
    HTTPResponse res = http.send(req);
    return res.getBody();
  }

}