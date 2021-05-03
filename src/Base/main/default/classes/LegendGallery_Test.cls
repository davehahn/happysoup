@isTest
private class LegendGallery_Test {

  static Product2 p;
  static String AWSbucket;
  static Date currentDate;

  private static void init() {

  //  //disable the Gimbal Trigger handler gtProduct.trigger
  //  //until Gimbals code gets deployed, this needs to be commented out for production
   // gcProduct.disableTrigger = true;
    BoatTestFactory factory = new BoatTestFactory();
    Organization org = [SELECT Id, isSandbox FROM Organization LIMIT 1];
    AWSbucket = org.isSandbox == true ? 'salesforce-image-gallery-sandbox' : 'salesforce-image-gallery';
    currentDate = Date.today();
    p = factory.insertTestProducts(1, 'Part')[0];// = new Product2( Name = 'Test Product');
    //insert p;
  }

	@isTest(seeAllData=true) static void passTest() {
    //PageReference pageRef = Page.ProductAWSImageGallery;
    //pageRef.getParameters().put('productId', p.Id);
    //Test.setCurrentPageReference(pageRef);
    Test.startTest();
    init();
    LegendGallery lg = new LegendGallery(p.Id);
    Test.stopTest();

    System.assertEquals('Product2', lg.objectType);
    System.assertEquals( p.Id, lg.objectId );
    System.assertEquals('Product2/' +currentDate.year() + '/' +currentDate.month(), lg.awsSettings.get('FileKey') );
    System.assertEquals(AWSbucket, lg.awsSettings.get('Bucket') );
    System.assertEquals('public-read', lg.awsSettings.get('Acl') );

	}

  @isTest(seeAllData=true) static void failTest()
  {
    AWS_S3_Object__c s3 = new AWS_S3_Object__c(File_Name__c = 'testImage.jpg',
                                               Bucket_Name__c = 'testBucket',
                                               Path__c = 'image_path');

    insert s3;
    try{
      LegendGallery lg = new LegendGallery(s3.Id);
    }
    catch(LegendGallery.GalleryException GalleryExcpt)
    {
      system.assert(GalleryExcpt.getTypeName().contains('LegendGallery.GalleryException') );
    }

  }

}