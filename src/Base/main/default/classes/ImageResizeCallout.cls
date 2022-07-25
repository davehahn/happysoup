public class ImageResizeCallout {
  @future(callout=true)
  public static void sendImageInfoToQueue(String fileName, String bucket) {
    HttpRequest req = new HttpRequest();
    HttpResponse res = new HttpResponse();
    Http http = new Http();

    Map<String, String> data = new Map<String, String>();
    data.put('filename', fileName);
    data.put('bucket', bucket);

    req.setEndpoint('http://imgr.legendboats.com/resize_image/');
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Accept', 'application/json');
    req.setBody(JSON.serialize(data));
    req.setCompressed(false);

    try {
      res = http.send(req);
    } catch (System.CalloutException e) {
      System.debug('Callout error: ' + e);
      System.debug(res.toString());
    }
  }

  // run WebServiceCallout.testMe(); from Execute Anonymous to test
  //public testMethod void testMe() {
  //    WebServiceCallout.sendNotification('My Test Customer','My City');
  //}
}
