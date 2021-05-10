@isTest
private class S3_Test {

  public class S3WebServiceMockImpl implements WebServiceMock{
    public void doInvoke(Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType)
    {
      if(request instanceof S3.DeleteBucket_element)
      {
          S3.DeleteBucketResponse_element r = new S3.DeleteBucketResponse_element();
          r.DeleteBucketResponse = new S3.Status();
          response.put('response_x', r);
      }
      else if(request instanceof S3.DeleteObject_element)
      {
          S3.DeleteObjectResponse_element r = new S3.DeleteObjectResponse_element();
          r.DeleteObjectResponse = new S3.Status();
          response.put('response_x', r);

      }
     else if(request instanceof S3.ListBucket_element)
      {
          S3.ListBucketResponse_element r = new S3.ListBucketResponse_element();
          r.ListBucketResponse = new S3.ListBucketResult();
          response.put('response_x', r);

      }
        else if(request instanceof S3.ListAllMyBuckets_element)
      {
          S3.ListAllMyBucketsResponse_element r = new S3.ListAllMyBucketsResponse_element();
          r.ListAllMyBucketsResponse= new S3.ListAllMyBucketsResult();
          response.put('response_x', r);

      }
      else if(request instanceof S3.CreateBucket_element)
      {
          S3.CreateBucketResponse_element r = new S3.CreateBucketResponse_element();
          r.CreateBucketResponse= new S3.CreateBucketResult();
          response.put('response_x', r);

      }
    }
  }


	public static testmethod void test1() {
    Test.setMock(WebServiceMock.class, new S3WebServiceMockImpl());
      s3.ListBucketResponse_element lbre = new s3.ListBucketResponse_element();
      s3.ListBucketResult lbr = new s3.ListBucketResult();
      s3.ListAllMyBucketsList lambl = new s3.ListAllMyBucketsList();
      s3.metadataEntry me = new s3.metadataEntry();
      s3.ListAllMyBucketsEntry lambe = new s3.ListAllMyBucketsEntry();
      s3.ListAllMyBucketsResult lambr = new s3.ListAllMyBucketsResult();
      s3.CreateBucketResult cbr = new s3.CreateBucketResult();
      s3.listEntry le = new s3.listEntry();
      s3.DeleteObject_element  doe = new s3.DeleteObject_element();
      s3.CanonicalUser co = new s3.CanonicalUser();
      s3.DeleteBucketResponse_element dbr = new s3.DeleteBucketResponse_element();
      s3.PrefixEntry pe = new s3.PrefixEntry();
      s3.status status = new s3.status();
      s3.ListAllMyBucketsResponse_element labre = new s3.ListAllMyBucketsResponse_element();
      s3.CreateBucketResponse_element cbre = new s3.CreateBucketResponse_element();

      S3.AmazonS3 sss = new S3.AmazonS3();

      sss.DeleteObject( '','','',system.now(),'','');

   }

    public static testmethod void test2() {
      Test.setMock(WebServiceMock.class, new S3WebServiceMockImpl());
      S3.AmazonS3 sss = new S3.AmazonS3();
      sss.secret = '42';
      system.assert( sss.signature('encode',system.now() ) != null);
      sss.ListBucket( '','','', 3,'','key',system.now(),'sig','cred');
    }

    public static testmethod void test3() {
      Test.setMock(WebServiceMock.class, new S3WebServiceMockImpl());
      S3.AmazonS3 S3 = new S3.AmazonS3();
      S3.secret = '42';
      system.assert( S3.signature('encode',system.now() ) != null);
      S3.ListAllMyBuckets('key',system.now(),'sig');
    }

    public static testmethod void test4() {
      Test.setMock(WebServiceMock.class, new S3WebServiceMockImpl());
      S3.AmazonS3 S3 = new S3.AmazonS3();
      S3.secret = '42';
      system.assert( S3.signature('encode',system.now() ) != null);
      s3.AccessControlList acl = new s3.AccessControlList();
      S3.CreateBucket('bucket',acl,'key',system.now(),'sig');
    }

    public static testmethod void test5() {
      Test.setMock(WebServiceMock.class, new S3WebServiceMockImpl());
      S3.AmazonS3 S3 = new S3.AmazonS3();
      S3.secret = '42';
      system.assert( S3.signature('encode',system.now() ) != null);
      S3.DeleteBucket('bucket','key',system.now(),'sig','cred');
    }

    public static testmethod void test6(){
       S3.AmazonS3 S3 = new S3.AmazonS3();
       S3.PutObjectInline_element putObjectElem = new S3.PutObjectInline_element();
       putObjectElem.Bucket='test';
       putObjectElem.Key = 'testKey';
       putObjectElem.Metadata = null;
       putObjectElem.Data= 'a';
       putObjectElem.ContentLength = 1;
       putObjectElem.AccessControlList = null;
       putObjectElem.StorageClass='classname';
       putObjectElem.AWSAccessKeyId='asdf';
       putObjectElem.Timestamp = Datetime.now();
       putObjectElem.Signature='test';
       putObjectElem.Credential='test';
    }

    public static testmethod void test7(){

      S3.AmazonS3 S3 = new S3.AmazonS3();
      S3.secret = '42';
      system.assert( S3.signature('encode',system.now() ) != null);
      try{
      S3.PutObjectInline_ACL('bucket','key',null,'datatesting',6,'public-read','keyid',System.now(),'sig','cred', 'ownerid') ;
      }catch(Exception ex){
      }
    }


}