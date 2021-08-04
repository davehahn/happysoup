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

  public class GooglePlacesSearch {
    public GooglePlaceCandidates[] candidates;
    public String status;
    public GooglePlacesSearch(){}
  }

  public class GooglePlaceCandidates {
    @AuraEnabled public String place_id;
    public GooglePlaceCandidates(){}
  }

  public class PlacesMatrix
  {
    public String input;
    public String inputType;
    public String fields;

    public PlacesMatrix(String input, String inputType, String fields){
      this.input = input;
      this.inputType = inputType;
      this.fields = fields;
    }

    public GooglePlacesSearch execute(){
      System.debug( 'Google Places Key: ' + googleApiKey );
      String url = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?';
      url += 'input=' + EncodingUtil.urlEncode(this.input, 'UTF-8');
      url += '&inputtype=' + EncodingUtil.urlEncode(this.inputType, 'UTF-8');
      url += '&fields=' + EncodingUtil.urlEncode(this.fields, 'UTF-8');
      url += '&key=' + googleApiKey;
      String gResult = getHttp(url);
      System.debug( gResult );
      return (GooglePlacesSearch)JSON.deserialize( gResult, GooglePlacesSearch.class );
    }
  }

  public class GooglePlacesDetails{
    @AuraEnabled public GooglePlacesDetailsResult result;

    public GooglePlacesDetails(){}
  }

  public class GooglePlacesDetailsResult{
    @AuraEnabled public GoogleAddressComponents[] address_components;
    @AuraEnabled public String formatted_phone_number;
    @AuraEnabled public String international_phone_number;
    @AuraEnabled public String name;
    @AuraEnabled public GoogleOpeningHours opening_hours;
    @AuraEnabled public GooglePlacesGeometry geometry;
    @AuraEnabled public String rating;

    public GooglePlacesDetailsResult(){}
  }

  public class GoogleAddressComponents{
    @AuraEnabled public String long_name;
    @AuraEnabled public String short_name;
    @AuraEnabled public List<String> types;
    public GoogleAddressComponents(){}
  }

  public class GoogleOpeningHours{
    @AuraEnabled public Boolean open_now;
    @AuraEnabled public GoogleOpeningPeriods[] periods;
    @AuraEnabled public List<String> weekday_text;
    public GoogleOpeningHours(){}
  }

  public class GoogleOpeningPeriods{
    @AuraEnabled public Map<String,String> close;
    @AuraEnabled public Map<String,String> open;
    public GoogleOpeningPeriods(){}
  }

  public class GooglePlacesGeometry {
    @AuraEnabled public Map<String,String> location;
    public GooglePlacesGeometry(){}
  }

  public class PlacesDetailsMatrix
  {
    public String place_id;

    public PlacesDetailsMatrix(String place_id){
      this.place_id = place_id;
    }

    public GooglePlacesDetails execute(){
      System.debug( 'Google Places Key: ' + googleApiKey );
      String url = 'https://maps.googleapis.com/maps/api/place/details/json?';
      url += 'place_id=' + EncodingUtil.urlEncode(this.place_id, 'UTF-8');
      url += '&key=' + googleApiKey;
      String gResult = getHttp(url);
      System.debug( gResult );
      return (GooglePlacesDetails)JSON.deserialize( gResult, GooglePlacesDetails.class );
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