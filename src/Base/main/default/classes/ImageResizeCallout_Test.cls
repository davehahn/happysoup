@isTest
private class ImageResizeCallout_Test {

	public class ResizeMock implements HttpCalloutMock {
    public  HTTPResponse respond(HTTPRequest req)
    {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      return res;
    }
  }

  @isTest
  static void sendImageInfoToQueue_Test()
  {
    Test.setMock( HttpCalloutMock.class, new ResizeMock() );
    Test.startTest();
    ImageResizeCallout.sendImageInfoToQueue('TestFile.jpg', 'TestBucketName');
    Test.stopTest();
  }

}