@isTest
private class LegendGalleryRemoter_Test {
  static List<Product2> products;
  static List<AWS_S3_Object__c> s3Objects;
  static List<Legend_Gallery_Image_Version__c> image_versions;
  static List<Legend_Gallery_Image_Map__c> product_marketing_images;
  static List<Legend_Gallery_Image__c> marketing_images;

  private static void init() {
    /* disable the Gimbal Trigger handler gtProduct.trigger
     until Gimbals code gets deployed, this needs to be commented out for production */
    gcProduct.disableTrigger = true;
    //factory = new BoatTestFactory();
    //products = factory.insertTestProducts(15, 'Part', null);
    products = new List<Product2>();
    AcctSeed__GL_Account__c revenueAccount;
    AcctSeed__GL_Account__c expenseAccount;
    AcctSeed__GL_Account__c inventoryAccount;
    List<AcctSeed__GL_Account__c> glAccts = new List<AcctSeed__GL_Account__c>();
    revenueAccount = new AcctSeed__GL_Account__c(
      Name = 'Test Revenue Account',
      AcctSeed__Active__c = true,
      AcctSeed__Type__c = 'Revenue'
    );
    expenseAccount = new AcctSeed__GL_Account__c(
      Name = 'Test Expense Account',
      AcctSeed__Active__c = true,
      AcctSeed__Type__c = 'Expense'
    );
    inventoryAccount = new AcctSeed__GL_Account__c(
      Name = 'Test Inventory Account',
      AcctSeed__Active__c = true,
      AcctSeed__Sub_Type_1__c = 'Assets',
      AcctSeed__Type__c = 'Balance Sheet'
    );
    glAccts.add(revenueAccount);
    glAccts.add(expenseAccount);
    glAccts.add(inventoryAccount);

    insert glAccts;

    s3Objects = new List<AWS_S3_Object__c>();
    image_versions = new List<Legend_Gallery_Image_Version__c>();
    product_marketing_images = new List<Legend_Gallery_Image_Map__c>();
    marketing_images = new List<Legend_Gallery_Image__c>();

    for (Integer i = 0; i < 15; i++) {
      products.add(
        new Product2(
          Name = 'Test Product ' + i,
          AcctSeed__Accounting_Type__c = 'Taxable_Product',
          AcctSeed__Expense_GL_Account__c = expenseAccount.Id,
          AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id,
          AcctSeed__Revenue_GL_Account__c = revenueAccount.Id,
          AcctSeed__Unit_Cost__c = 100.00,
          isActive = true
        )
      );
      s3Objects.add(
        new AWS_S3_Object__c(
          File_Name__c = 'testImage' + i + '.jpg',
          Bucket_Name__c = 'testBucket',
          Path__c = 'image_path'
        )
      );
    }
    insert products;
    insert s3Objects;

    for (AWS_S3_Object__c obj : s3Objects) {
      marketing_images.add(
        new Legend_Gallery_Image__c(
          Active_S3_Object__c = obj.Id,
          ENG_Description__c = 'English Description',
          FR_Description__c = 'French Description',
          Object_Type__c = 'Product2'
        )
      );
    }
    insert marketing_images;

    for (Legend_Gallery_Image__c mi : marketing_images) {
      image_versions.add(
        new Legend_Gallery_Image_Version__c(AWS_S3_Object__c = mi.Active_S3_Object__c, Legend_Gallery_Image__c = mi.Id)
      );
      product_marketing_images.add(
        new Legend_Gallery_Image_Map__c(Parent_Object_Id__c = products[0].Id, Legend_Gallery_Image__c = mi.Id)
      );
      product_marketing_images.add(
        new Legend_Gallery_Image_Map__c(Parent_Object_Id__c = products[1].Id, Legend_Gallery_Image__c = mi.Id)
      );
    }
    insert image_versions;
    insert product_marketing_images;
  }

  @isTest
  static void fetchAssociatedImages_Test() {
    Test.startTest();
    init();
    List<LegendGalleryRemoter.ImageWrapper> p0_images = LegendGalleryRemoter.fetchAssociatedImages(
      0,
      10,
      products[0].Id
    );
    List<LegendGalleryRemoter.ImageWrapper> p5_images = LegendGalleryRemoter.fetchAssociatedImages(
      0,
      10,
      products[5].Id
    );
    Test.stopTest();

    System.assertEquals(10, p0_images.size());
    System.assertEquals(0, p5_images.size());
  }

  @isTest
  static void fetchAvailableImages_Test() {
    Test.startTest();
    init();
    List<LegendGalleryRemoter.ImageWrapper> p0_images = LegendGalleryRemoter.fetchAvailableImages(
      0,
      10,
      products[0].Id
    );
    List<LegendGalleryRemoter.ImageWrapper> p5_images = LegendGalleryRemoter.fetchAvailableImages(
      0,
      10,
      products[5].Id
    );
    Test.stopTest();

    System.assertEquals(0, p0_images.size());
    System.assertEquals(10, p5_images.size());
  }

  @isTest
  static void createRecord_Test() {
    Test.startTest();
    init();
    String json =
      '{\"File_Name\":\"NIN1.jpg\",\"descriptions\":{\"english\":\"English Descriptions\",\"french\":\"French Descriptions\"},\"parentObjectId\":\"' +
      products[0].Id +
      '\",\"AWS_Bucket\":\"salesforce-image-gallery-sandbox\",\"AWS_Key\":\"Product2\",\"imgWidth\":1024,\"imgHeight\":1024}';
    LegendGalleryRemoter.ImageWrapper image = LegendGalleryRemoter.createRecord(json);
    List<Legend_Gallery_Image_Map__c> pmis = [
      SELECT Id
      FROM Legend_Gallery_Image_MAp__c
      WHERE Parent_Object_Id__c = :products[0].Id
    ];
    Test.stopTest();
    System.assertEquals('NIN1.jpg', image.GalleryImageName);
    System.assertEquals(16, pmis.size());
  }

  @isTest
  static void createRecordsAsDefault_Test() {
    Test.startTest();
    init();
    Product2 p_before = [SELECT Id, Legend_Gallery_Image__c FROM Product2 WHERE Id = :products[0].Id];
    String json =
      '[{\"File_Name\":\"NIN1.jpg\",\"isDefault\":true,\"descriptions\":{\"english\":\"English Descriptions\",\"french\":\"French Descriptions\"},\"parentObjectId\":\"' +
      products[0].Id +
      '\",\"AWS_Bucket\":\"salesforce-image-gallery-sandbox\",\"AWS_Key\":\"Product2\",\"imgWidth\":1024,\"imgHeight\":1024}]';
    LegendGalleryRemoter.insertRecords(json);
    Product2 p_after = [SELECT Id, Legend_Gallery_Image__c FROM Product2 WHERE Id = :products[0].Id];
    Test.stopTest();
    System.assert(p_before.Legend_Gallery_Image__c == null);
    System.assert(p_after.Legend_Gallery_Image__c != null);
  }

  @isTest
  static void add_delete_change_Version_Test() {
    Test.startTest();
    init();
    String json =
      '{\"File_Name\":\"NIN1.jpg\",\"GalleryImageId\":\"' +
      marketing_images[0].Id +
      '\",\"AWS_Bucket\":\"salesforce-image-gallery-sandbox\",\"AWS_Key\":\"Product2\",\"imgWidth\":1024,\"imgHeight\":1024}';
    Legend_Gallery_Image_Version__c miv = LegendGalleryRemoter.addNewVersion(json);
    List<Legend_Gallery_Image_Version__c> mivs_a = [
      SELECT Id, AWS_S3_Object__c
      FROM Legend_Gallery_Image_Version__c
      WHERE Legend_Gallery_Image__c = :marketing_images[0].Id
    ];

    Legend_Gallery_Image__c mi_a = [
      SELECT Id, Active_S3_Object__c
      FROM Legend_Gallery_Image__c
      WHERE Id = :marketing_images[0].Id
    ];
    String active_json =
      '{\"Id\":\"' +
      marketing_images[0].Id +
      '\",\"Active_S3_Object__c\":\"' +
      mivs_a[1].AWS_S3_Object__c +
      '\"}';
    LegendGalleryRemoter.ImageWrapper iw = LegendGalleryRemoter.setActiveImage(active_json);
    Legend_Gallery_Image__c mi_b = [
      SELECT Id, Active_S3_Object__c
      FROM Legend_Gallery_Image__c
      WHERE Id = :marketing_images[0].Id
    ];

    LegendGalleryRemoter.deleteVersion(miv.AWS_S3_Object__c);
    List<Legend_Gallery_Image_Version__c> mivs_b = [
      SELECT Id
      FROM Legend_Gallery_Image_Version__c
      WHERE Legend_Gallery_Image__c = :marketing_images[0].Id
    ];
    Test.stopTest();
    System.assertEquals(2, mivs_a.size());
    System.assertEquals(mi_a.Active_S3_Object__c, mivs_a[0].AWS_S3_Object__c);
    System.assertEquals(mi_b.Active_S3_Object__c, mivs_a[1].AWS_S3_Object__c);
    System.assertEquals(1, mivs_b.size());
  }

  @isTest
  static void updateDescriptions_Test() {
    Test.startTest();

    init();
    Legend_Gallery_Image__c mi = marketing_images[0];
    Map<String, String> descriptions = new Map<String, String>();
    descriptions.put('english', 'This is the english description');
    descriptions.put('french', 'This is the French description');
    Legend_Gallery_Image__c updated_mi = LegendGalleryRemoter.updateDescriptions(mi.Id, JSON.serialize(descriptions));

    Test.stopTest();

    System.assertEquals('English Description', mi.ENG_Description__c);
    System.assertEquals('French Description', mi.FR_Description__c);
    System.assertEquals('This is the english description', updated_mi.ENG_Description__c);
    System.assertEquals('This is the French description', updated_mi.FR_Description__c);
  }

  @isTest
  static void deleteImage_Test() {
    Test.startTest();
    init();
    List<AWS_S3_Object__c> objects = [SELECT Id FROM AWS_S3_Object__c];
    List<Legend_Gallery_Image__c> mis = [SELECT Id FROM Legend_Gallery_Image__c];

    LegendGalleryRemoter.deleteImage(mis[0].Id);

    List<AWS_S3_Object__c> objects_after = [SELECT Id FROM AWS_S3_Object__c];
    List<Legend_Gallery_Image__c> mis_after = [SELECT Id FROM Legend_Gallery_Image__c];
    Test.stopTest();

    System.assertEquals(mis.size() - 1, mis_after.size());
    System.assertEquals(objects.size() - 1, objects_after.size());
  }

  @isTest
  static void deleteImageAssociation() {
    Test.startTest();
    init();

    List<Legend_Gallery_Image_Map__c> pmis_a = [
      SELECT Id, Parent_Object_Id__c, Legend_Gallery_Image__c
      FROM Legend_Gallery_Image_Map__c
      WHERE Parent_Object_Id__c = :products[0].Id
    ];

    LegendGalleryRemoter.deleteImageAssociation(pmis_a[0].Legend_Gallery_Image__c, pmis_a[0].Parent_Object_Id__c);

    List<Legend_Gallery_Image_Map__c> pmis_b = [
      SELECT Id
      FROM Legend_Gallery_Image_Map__c
      WHERE Parent_Object_Id__c = :products[0].Id
    ];
    Test.stopTest();

    System.assertEquals(15, pmis_a.size());
    System.assertEquals(14, pmis_b.size());
  }

  @isTest
  static void associatedParents_Test() {
    Test.startTest();
    init();

    List<LegendGalleryRemoter.associatedParent> pmis = LegendGalleryRemoter.associatedParents(
      marketing_images[0].Id,
      products[0].Id
    );
    System.assertEquals(1, pmis.size());
  }

  @isTest
  static void createAssociations_Test() {
    Test.startTest();
    init();
    List<Legend_Gallery_Image_Map__c> pmis = [
      SELECT Id
      FROM Legend_Gallery_Image_Map__c
      WHERE Parent_Object_Id__c = :products[4].Id
    ];

    List<String> miIds = new List<String>{ marketing_images[0].Id, marketing_images[1].Id };

    LegendGalleryRemoter.createAssociations(products[4].Id, miIds);

    List<Legend_Gallery_Image_Map__c> pmis_aft = [
      SELECT Id
      FROM Legend_Gallery_Image_Map__c
      WHERE Parent_Object_Id__c = :products[4].Id
    ];
    Test.stopTest();

    System.assertEquals(0, pmis.size());
    System.assertEquals(2, pmis_aft.size());
  }

  @isTest
  static void setDefault_Test() {
    Test.startTest();
    init();
    //should have no default image
    Product2 p_a = [SELECT Id, Legend_Gallery_Image__c FROM Product2 WHERE Id = :products[0].Id];

    //set default image
    LegendGalleryRemoter.setDefault(marketing_images[0].Id, products[0].Id);
    Product2 p_b = [SELECT Id, Legend_Gallery_Image__c FROM Product2 WHERE Id = :products[0].Id];

    //sending the same Marketing_Image__c Id and Product Id should remove the default
    LegendGalleryRemoter.setDefault(marketing_images[0].Id, products[0].id);
    Product2 p_c = [SELECT Id, Legend_Gallery_Image__c FROM Product2 WHERE Id = :products[0].Id];
    Test.stopTest();

    System.assertEquals(null, p_a.Legend_Gallery_Image__c);
    System.assertEquals(marketing_images[0].Id, p_b.Legend_Gallery_Image__c);
    System.assertEquals(null, p_c.Legend_Gallery_Image__c);
  }
}
