@isTest
public with sharing class LegendImageGalleryController_Test {
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
    p = factory.insertTestProducts(1, 'Part')[0];
    //p = new Product2( Name = 'Test Product');
    //insert p;
  }

  @isTest(seeAllData=true)
  static void passTest() {
    Test.startTest();
    init();
    PageReference pageRef = Page.LegendImageGallery;
    pageRef.getParameters().put('id', p.Id);
    Test.setCurrentPageReference(pageRef);
    LegendImageGalleryController ligs = new LegendImageGalleryController();
    Test.stopTest();

    System.assertEquals('Product2', ligs.lgndGallery.objectType);
    System.assertEquals(p.Id, ligs.lgndGallery.objectId);
    System.assertEquals(
      'Product2/' +
      currentDate.year() +
      '/' +
      currentDate.month(),
      ligs.lgndGallery.awsSettings.get('FileKey')
    );
    System.assertEquals(AWSbucket, ligs.lgndGallery.awsSettings.get('Bucket'));
    System.assertEquals('public-read', ligs.lgndGallery.awsSettings.get('Acl'));
    System.assertEquals(30, ligs.imageLimit);
  }

  @isTest(seeAllData=true)
  static void failTest() {
    AWS_S3_Object__c s3 = new AWS_S3_Object__c(
      File_Name__c = 'testImage.jpg',
      Bucket_Name__c = 'testBucket',
      Path__c = 'image_path'
    );

    insert s3;
    PageReference pageRef = Page.LegendImageGallery;
    pageRef.getParameters().put('id', s3.Id);

    Test.setCurrentPageReference(pageRef);
    try {
      LegendImageGalleryController ligs = new LegendImageGalleryController();
    } catch (LegendGallery.GalleryException GalleryExcpt) {
      system.assert(GalleryExcpt.getTypeName().contains('LegendGallery.GalleryException'));
    }
  }
}
