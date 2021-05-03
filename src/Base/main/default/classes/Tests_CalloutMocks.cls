/**
 * Created by dave on 2019-10-31.
 */

@IsTest
public class Tests_CalloutMocks
{

  public class GoogleDestinationsMatrixMock implements HttpCalloutMock {
    private final String jsonResponse = '{' +
      '\"destination_addresses\": [ ' +
      '\"2375 Industrial Park Rd, ON, L9S 3W1, Canada\",' +
      '\"139 Fittons Rd East, ON, L3V 2G9, Canada\" ],' +
      '\"origin_addresses\": [ ' +
      '\"Orillia, On, Canada\" ],' +
      '\"rows\": [  { '+
      '\"elements\": [ { ' +
      '\"distance\": { \"text\": \"52.6 km\", \"value\": 52604 },' +
      '\"duration\": { \"text\": \"36 mins\", \"value\": 2147 },' +
      '\"status\": \"OK\"' +
      '}, { '+
      '\"distance\": { \"text\": \"3.0 km\", \"value\": 2977 },' +
      '\"duration\": { \"text\": \"6 mins\", \"value\": 340 },' +
      '\"status\": \"OK\"' +
      '} ] } ],' +
      '\"status\": \"OK\" }';

    public HttpResponse respond( HttpRequest req )
    {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody( jsonResponse );
      res.setStatusCode(200);
      return res;
    }
  }

  public class GoogleDestinationsMatrixMock_NoOrigin implements HttpCalloutMock {
    private final String jsonResponse = '{' +
      '\"destination_addresses\": [],' +
      '\"origin_addresses\": [],' +
      '\"rows\": [],' +
      '\"status\": \"OK\" }';

    public HttpResponse respond( HttpRequest req )
    {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody( jsonResponse );
      res.setStatusCode(200);
      return res;
    }
  }
}