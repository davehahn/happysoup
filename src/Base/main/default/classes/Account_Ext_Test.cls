@isTest
private class Account_Ext_Test {
  static Account acct;

  static {
    acct = new Account(FirstName = 'Test', LastName = 'Account');
    insert acct;
  }

  @isTest
  static void constructor_Test() {
    Account_Ext ext = new Account_Ext(new ApexPages.StandardController(acct));

    System.assertEquals(acct.Id, ext.accountId);
    System.assertEquals('Account', ext.gallery.objectType);
  }

  @isTest
  static void createGalleryImage_Test() {
    String json =
      '{\"File_Name\":\"NIN1.jpg\",\"descriptions\":{\"english\":\"English Descriptions\",\"french\":\"French Descriptions\"},\"parentObjectId\":\"' +
      acct.Id +
      '\",\"AWS_Bucket\":\"salesforce-image-gallery-sandbox\",\"AWS_Key\":\"Product2\",\"imgWidth\":1024,\"imgHeight\":1024}';

    LegendGalleryRemoter.ImageWrapper image = Account_Ext.createGalleryImage(json);
    System.assertEquals('NIN1.jpg', image.GalleryImageName);
  }
}
