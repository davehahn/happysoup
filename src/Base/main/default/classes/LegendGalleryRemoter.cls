global with sharing class LegendGalleryRemoter {
  global class ImageWrapper {
    public String Bucket_Name { get; set; }
    public String parentObjectId { get; set; }
    public String Path { get; set; }
    public String GalleryImageId { get; set; }
    public String GalleryImageName { get; set; }
    public String Id { get; set; }
    public String AWS_Link { get; set; }
    public String File_Name { get; set; }
    public Boolean isDefault { get; set; }
    public String URL_Gallery { get; set; }
    public String URL_500x500 { get; set; }
    public String URL_700w { get; set; }
    public String URL_1280w { get; set; }
    public String URL_Original { get; set; }
    public String ENG_Description { get; set; }
    public String FR_Description { get; set; }
    public Descriptions descriptions { get; set; }
    public Decimal Image_Height { get; set; }
    public Decimal Image_Width { get; set; }
    public List<Legend_Gallery_Image_Version__c> ImageVersions { get; set; }

    public ImageWrapper() {
    }

    public ImageWrapper(Legend_Gallery_Image__c lgi) {
      this.GalleryImageId = lgi.Id;
      this.GalleryImageName = lgi.Name;
      this.Bucket_Name = lgi.Active_S3_object__r.Bucket_Name__c;
      this.Path = lgi.Active_S3_object__r.Path__c;
      this.Id = lgi.Active_S3_object__r.Id;
      this.AWS_Link = lgi.Active_S3_object__r.AWS_Link__c;
      this.File_Name = lgi.Active_S3_object__r.File_Name__c;
      this.URL_Gallery = lgi.Active_S3_object__r.URL_Gallery__c;
      this.URL_500x500 = lgi.Active_S3_object__r.URL_500x500__c;
      this.URL_700w = lgi.Active_S3_object__r.URL_700w__c;
      this.URL_1280w = lgi.Active_S3_object__r.URL_1280w__c;
      this.URL_Original = lgi.Active_S3_object__r.URL_Original__c;
      this.ENG_Description = lgi.ENG_Description__c;
      this.FR_Description = lgi.FR_Description__c;
      this.Image_Height = lgi.Active_S3_Object__r.Image_Height__c;
      this.Image_Width = lgi.Active_S3_Object__r.Image_Width__c;
      this.descriptions = new Descriptions(lgi.ENG_Description__c, lgi.FR_Description__c);
      this.ImageVersions = lgi.Legend_Gallery_Image_Versions__r;
    }

    public AWS_S3_Object__c create_AWS_S3_Object() {
      return new AWS_S3_Object__c(
        Bucket_Name__c = this.Bucket_Name,
        Path__c = this.Path,
        File_Name__c = this.File_Name,
        Image_Height__c = Integer.valueOf(this.Image_Height),
        Image_Width__c = Integer.valueOf(this.Image_Width)
      );
    }
  }

  public class Descriptions {
    public String english;
    public String french;

    public Descriptions(String eng, String fr) {
      this.english = eng;
      this.french = fr;
    }
  }

  public class associatedParent {
    public String parentName { get; set; }
    public String parentId { get; set; }
    public String galleryImageId { get; set; }

    public associatedParent(sObject parentObject, Legend_Gallery_Image_Map__c lgim) {
      this.parentName = (String) parentObject.get('Name');
      this.parentId = (String) parentObject.get('Id');
      this.galleryImageId = lgim.Legend_Gallery_Image__c;
    }
  }

  @AuraEnabled
  global static String fetchAllAssociatedImages(String objId) {
    //List<AWS_S3_Object__c> s3Objects = new List<AWS_S3_Object__c>();
    System.debug('^^^^^^^ objId = ' + objId);
    ImageWrapper[] results = new List<ImageWrapper>();
    Set<Id> imageIds = findImageIds(objId);

    List<Legend_Gallery_Image__c> images = [
      SELECT
        Id,
        Name,
        ENG_Description__c,
        FR_Description__c,
        Active_S3_Object__c,
        Active_S3_object__r.Id,
        Active_S3_object__r.AWS_Link__c,
        Active_S3_object__r.File_Name__c,
        Active_S3_object__r.Path__c,
        Active_S3_object__r.Bucket_Name__c,
        Active_S3_Object__r.Image_Height__c,
        Active_S3_Object__r.Image_Width__c,
        Active_S3_Object__r.URL_Gallery__c,
        Active_S3_object__r.URL_500x500__c,
        Active_S3_object__r.URL_700w__c,
        Active_S3_object__r.URL_1280w__c,
        Active_S3_object__r.URL_Original__c,
        (
          SELECT
            Id,
            CreatedBy.Name,
            CreatedDate,
            Legend_Gallery_Image__c,
            Name,
            AWS_S3_Object__c,
            AWS_S3_object__r.Id,
            AWS_S3_object__r.AWS_Link__c,
            AWS_S3_object__r.File_Name__c,
            AWS_S3_object__r.Path__c,
            AWS_S3_object__r.Bucket_Name__c,
            AWS_S3_Object__r.Image_Height__c,
            AWS_S3_Object__r.Image_Width__c,
            AWS_S3_Object__r.URL_Gallery__c,
            AWS_S3_object__r.URL_500x500__c,
            AWS_S3_object__r.URL_700w__c,
            AWS_S3_object__r.URL_1280w__c,
            AWS_S3_object__r.URL_Original__c
          FROM Legend_Gallery_Image_Versions__r
          ORDER BY CreatedDate DESC
        )
      FROM Legend_Gallery_Image__c
      WHERE Id IN :imageIds
    ];
    for (Legend_Gallery_Image__c i : images) {
      //s3Objects.add(mi.AWS_S3_Object__r);
      results.add(new ImageWrapper(i));
    }
    //return s3Objects;
    return JSON.serialize(results);
  }

  @RemoteAction
  global static List<ImageWrapper> fetchAssociatedImages(Integer start_at, Integer resultSize, String objId) {
    //List<AWS_S3_Object__c> s3Objects = new List<AWS_S3_Object__c>();
    System.debug('^^^^^^^ objId = ' + objId);
    ImageWrapper[] results = new List<ImageWrapper>();
    Set<Id> imageIds = findImageIds(start_at, resultSize, objId);
    System.debug(imageIds);
    List<Legend_Gallery_Image__c> images = [
      SELECT
        Id,
        Name,
        ENG_Description__c,
        FR_Description__c,
        Active_S3_Object__c,
        Active_S3_object__r.Id,
        Active_S3_object__r.AWS_Link__c,
        Active_S3_object__r.File_Name__c,
        Active_S3_object__r.Path__c,
        Active_S3_object__r.Bucket_Name__c,
        Active_S3_Object__r.Image_Height__c,
        Active_S3_Object__r.Image_Width__c,
        Active_S3_Object__r.URL_Gallery__c,
        Active_S3_object__r.URL_500x500__c,
        Active_S3_object__r.URL_700w__c,
        Active_S3_object__r.URL_1280w__c,
        Active_S3_object__r.URL_Original__c,
        (
          SELECT
            Id,
            CreatedBy.Name,
            CreatedDate,
            Legend_Gallery_Image__c,
            Name,
            AWS_S3_Object__c,
            AWS_S3_object__r.Id,
            AWS_S3_object__r.AWS_Link__c,
            AWS_S3_object__r.File_Name__c,
            AWS_S3_object__r.Path__c,
            AWS_S3_object__r.Bucket_Name__c,
            AWS_S3_Object__r.Image_Height__c,
            AWS_S3_Object__r.Image_Width__c,
            AWS_S3_Object__r.URL_Gallery__c,
            AWS_S3_object__r.URL_500x500__c,
            AWS_S3_object__r.URL_700w__c,
            AWS_S3_object__r.URL_1280w__c,
            AWS_S3_object__r.URL_Original__c
          FROM Legend_Gallery_Image_Versions__r
          ORDER BY CreatedDate DESC
        )
      FROM Legend_Gallery_Image__c
      WHERE Id IN :imageIds
    ];
    for (Legend_Gallery_Image__c i : images) {
      //s3Objects.add(mi.AWS_S3_Object__r);
      results.add(new ImageWrapper(i));
    }
    //return s3Objects;
    return results;
  }

  @RemoteAction
  public static List<ImageWrapper> fetchAvailableImages(Integer start_at, Integer resultSize, String objId) {
    String objType = Id.valueOf(objId).getSObjectType().getDescribe().getName();
    List<ImageWrapper> result = new List<ImageWrapper>();
    Set<Id> imageIds = findImageIds(objId);

    Legend_Gallery_Image__c[] images = [
      SELECT
        Id,
        Name,
        ENG_Description__c,
        FR_Description__c,
        Active_S3_Object__c,
        Active_S3_object__r.Id,
        Active_S3_object__r.AWS_Link__c,
        Active_S3_object__r.File_Name__c,
        Active_S3_object__r.Path__c,
        Active_S3_object__r.Bucket_Name__c,
        Active_S3_Object__r.Image_Height__c,
        Active_S3_Object__r.Image_Width__c,
        Active_S3_Object__r.URL_Gallery__c,
        Active_S3_object__r.URL_500x500__c,
        Active_S3_object__r.URL_700w__c,
        Active_S3_object__r.URL_1280w__c,
        Active_S3_object__r.URL_Original__c
      FROM Legend_Gallery_Image__c
      WHERE Id NOT IN :imageIds AND Object_Type__c = :objType
      ORDER BY CreatedDate ASC
      LIMIT :resultSize
      OFFSET :start_at
    ];
    for (Legend_Gallery_Image__c i : images) {
      result.add(new ImageWrapper(i));
    }
    return result;
  }

  @RemoteAction
  global static ImageWrapper createRecord(String recordData) {
    return insertRecord(recordData);
  }

  public static ImageWrapper insertRecord(String recordData) {
    System.debug('in insert record');
    System.debug(recordData);
    ImageWrapper newImage = (ImageWrapper) JSON.deserialize(recordData, ImageWrapper.class);
    System.debug(newImage);
    String objType = Id.valueOf(newImage.parentObjectId).getSObjectType().getDescribe().getName();
    AWS_S3_Object__c s3 = newImage.create_AWS_S3_Object();

    try {
      insert s3;
      System.debug('inserted s3');
      System.debug(s3);
      Legend_Gallery_Image__c lgi = new Legend_Gallery_Image__c();
      System.debug(lgi);
      Legend_Gallery_Image_Version__c lgiv = new Legend_Gallery_Image_Version__c();
      System.debug(lgiv);
      Legend_Gallery_Image_Map__c lgim = new Legend_Gallery_Image_Map__c();
      System.debug(lgim);

      lgi.ENG_Description__c = newImage.descriptions.english;
      lgi.FR_Description__c = newImage.descriptions.french;
      lgi.Active_S3_Object__c = s3.Id;
      lgi.Object_Type__c = objType;
      lgi.Name = newImage.File_Name;
      insert lgi;
      System.debug('inserted lgi');
      System.debug(lgi);

      lgiv.AWS_S3_Object__c = s3.Id;
      lgiv.Legend_Gallery_Image__c = lgi.Id;
      insert lgiv;
      System.debug('inserted lgiv');
      System.debug(lgiv);

      lgim.Parent_Object_Id__c = newImage.parentObjectId;
      lgim.Legend_Gallery_Image__c = lgi.Id;
      insert lgim;
      System.debug('inserted lgim');
      System.debug(lgim);
      lgi = reloadImage(lgi.Id);

      if (!Test.isRunningTest()) {
        System.debug('sending to queue');
        ImageResizeCallout.sendImageInfoToQueue(
          lgi.Active_S3_Object__r.Path__c +
          '/' +
          lgi.Active_S3_Object__r.File_Name__c,
          lgi.Active_S3_Object__r.Bucket_Name__c
        );
      }
      return new ImageWrapper(lgi);
    } catch (Exception e) {
      System.debug('There was an Error creating a Marketing image - ' + e.getMessage());
      return null;
    }
  }

  public static Boolean insertRecords(String recordData) {
    System.debug('in insert records');
    System.debug(recordData);
    List<ImageWrapper> newImages = (List<ImageWrapper>) JSON.deserialize(recordData, List<ImageWrapper>.class);
    System.debug(newImages);
    Map<Integer, ImageWrapper> imageMap = new Map<Integer, ImageWrapper>();
    Map<Integer, AWS_S3_Object__c> s3Map = new Map<Integer, AWS_S3_Object__c>();
    for (Integer i = 0; i < newImages.size(); i++) {
      System.debug(newImages[i]);
      imageMap.put(i, newImages[i]);
      s3Map.put(i, newImages[i].create_AWS_S3_Object());
      System.debug(s3Map.get(i));
    }

    try {
      insert s3Map.values();
      Map<Id, Legend_Gallery_Image__c> galleryImages = new Map<Id, Legend_Gallery_Image__c>();
      Id s3Id_toSetAsDefaultImage;
      Id parentRecordId;
      for (Integer i : s3Map.keySet()) {
        Legend_Gallery_Image__c lgi = new Legend_Gallery_Image__c();
        ImageWrapper newImage = imageMap.get(i);
        if (newImage.isDefault) {
          s3Id_toSetAsDefaultImage = s3Map.get(i).Id;
          parentRecordId = newImage.parentObjectId;
        }
        String objType = Id.valueOf(newImage.parentObjectId).getSObjectType().getDescribe().getName();
        lgi.ENG_Description__c = newImage.descriptions.english;
        lgi.FR_Description__c = newImage.descriptions.french;
        lgi.Active_S3_Object__c = s3Map.get(i).Id;
        lgi.Object_Type__c = objType;
        lgi.Name = newImage.File_Name;
        galleryImages.put(s3Map.get(i).Id, lgi);
      }
      insert galleryImages.values();
      if (s3Id_toSetAsDefaultImage != null)
        setDefault(galleryImages.get(s3Id_toSetAsDefaultImage).Id, parentRecordId);

      List<Legend_Gallery_Image_Version__c> lgivs = new List<Legend_Gallery_Image_Version__c>();
      for (Id s3Id : galleryImages.keySet()) {
        lgivs.add(
          new Legend_Gallery_Image_Version__c(
            AWS_S3_Object__c = s3Id,
            Legend_Gallery_Image__c = galleryImages.get(s3Id).Id
          )
        );
      }
      insert lgivs;

      List<Legend_Gallery_Image_Map__c> lgims = new List<Legend_Gallery_Image_Map__c>();
      for (Integer i : imageMap.keySet()) {
        lgims.add(
          new Legend_Gallery_Image_Map__c(
            Parent_Object_Id__c = imageMap.get(i).parentObjectId,
            Legend_Gallery_Image__c = galleryImages.get(s3Map.get(i).Id).Id
          )
        );
      }
      insert lgims;
      Set<Id> lgiIds = new Set<Id>();
      for (Legend_Gallery_Image__c lgi : galleryImages.values()) {
        lgiIds.add(lgi.Id);
      }
      if (!Test.isRunningTest()) {
        for (Legend_Gallery_Image__c lgi : [
          SELECT Id, Active_S3_Object__r.Path__c, Active_S3_Object__r.File_Name__c, Active_S3_Object__r.Bucket_Name__c
          FROM Legend_Gallery_Image__c
          WHERE Id IN :lgiIds
        ]) {
          ImageResizeCallout.sendImageInfoToQueue(
            lgi.Active_S3_Object__r.Path__c +
            '/' +
            lgi.Active_S3_Object__r.File_Name__c,
            lgi.Active_S3_Object__r.Bucket_Name__c
          );
        }
      }
      return true;
    } catch (Exception e) {
      System.debug('There was an Error creating a Marketing image - ' + e.getMessage());
      return false;
    }
  }

  @RemoteAction
  global static Legend_Gallery_Image_Version__c addNewVersion(String recordData) {
    ImageWrapper newImage = (ImageWrapper) JSON.deserialize(recordData, ImageWrapper.class);
    Legend_Gallery_Image_Version__c lgiv = new Legend_Gallery_Image_Version__c();
    AWS_S3_Object__c s3 = newImage.create_AWS_S3_Object();

    try {
      insert s3;
      lgiv.AWS_S3_Object__c = s3.Id;
      lgiv.Legend_Gallery_Image__c = newImage.GalleryImageId;
      insert lgiv;
      //Marketing_Image__c mi = reloadMarketingImage( Id.valueOf( newMarketingImage.GalleryImageId ) );
      if (!Test.isRunningTest()) {
        ImageResizeCallout.sendImageInfoToQueue(s3.Path__c + '/' + s3.File_Name__c, s3.Bucket_Name__c);
      }
      return [
        SELECT
          Id,
          Legend_Gallery_Image__c,
          Name,
          CreatedBy.Name,
          CreatedDate,
          AWS_S3_Object__c,
          AWS_S3_object__r.Id,
          AWS_S3_object__r.AWS_Link__c,
          AWS_S3_object__r.File_Name__c,
          AWS_S3_object__r.Path__c,
          AWS_S3_object__r.Bucket_Name__c,
          AWS_S3_Object__r.Image_Height__c,
          AWS_S3_Object__r.Image_Width__c,
          AWS_S3_Object__r.URL_Gallery__c,
          AWS_S3_object__r.URL_500x500__c,
          AWS_S3_object__r.URL_700w__c,
          AWS_S3_object__r.URL_1280w__c,
          AWS_S3_object__r.URL_Original__c
        FROM Legend_Gallery_Image_Version__c
        WHERE Id = :lgiv.Id
      ];
    } catch (Exception e) {
      System.debug('There was an Error creating a Marketing image - ' + e.getMessage());
      return null;
    }
  }

  @RemoteAction
  global static ImageWrapper setActiveImage(String jsonData) {
    Legend_Gallery_Image__c image = (Legend_Gallery_Image__c) JSON.deserialize(jsonData, Legend_Gallery_Image__c.class);
    upsert image;
    return new ImageWrapper(reloadImage(image.Id));
  }

  @RemoteAction
  global static void deleteVersion(Id aws_s3_object_id) {
    Schema.sObjectType sOtype = aws_s3_object_id.getSObjectType();
    SObject obj = sOtype.newSObject(aws_s3_object_id);
    delete obj;
  }

  @RemoteAction
  global static Legend_Gallery_Image__c updateDescriptions(String imageId, String descriptions) {
    Legend_Gallery_Image__c lgi = [
      SELECT Id, ENG_Description__c, FR_Description__c
      FROM Legend_Gallery_Image__c
      WHERE Id = :imageId
    ];
    Map<String, String> descMap = (Map<String, String>) JSON.deserializeStrict(descriptions, Map<String, String>.class);

    lgi.ENG_Description__c = descMap.get('english');
    lgi.FR_Description__c = descMap.get('french');
    update lgi;
    return lgi;
  }

  @RemoteAction
  global static void deleteImage(String imageId) {
    Set<Id> awsIds = new Set<Id>();
    Legend_Gallery_Image__c lgi = [
      SELECT Id, (SELECT Id, AWS_S3_Object__c FROM Legend_Gallery_Image_Versions__r)
      FROM Legend_Gallery_Image__c
      WHERE Id = :imageId
    ];
    for (Legend_Gallery_Image_Version__c lgiv : lgi.Legend_Gallery_Image_Versions__r) {
      awsIds.add(lgiv.AWS_S3_Object__c);
    }
    List<AWS_S3_Object__c> s3Objects = [SELECT Id FROM AWS_S3_Object__c WHERE Id IN :awsIds];

    delete s3Objects;
    delete lgi;
  }

  @RemoteAction
  global static void deleteImageAssociation(String imageId, String objId) {
    try {
      Legend_Gallery_Image_Map__c lgim = [
        SELECT Id
        FROM Legend_Gallery_Image_map__c
        WHERE Parent_Object_id__c = :objId AND Legend_Gallery_Image__c = :imageId
      ];
      delete lgim;
    } catch (Exception e) {
      System.debug('&&&&&&&&&&&&&&&&&&&&& ' + e.getMessage());
    }
  }

  @RemoteAction
  public static List<associatedParent> associatedParents(Id lgiId, Id objId) {
    List<associatedParent> results = new List<associatedParent>();
    Schema.SObjectType token = Id.valueOf(objId).getSObjectType();
    Schema.DescribeSObjectResult dr = token.getDescribe();

    Map<String, Legend_Gallery_Image_Map__c> relatedParentMap = new Map<String, Legend_Gallery_Image_Map__c>();

    Legend_Gallery_Image_Map__c[] maps = [
      SELECT Id, Parent_Object_Id__c, Legend_Gallery_Image__c
      FROM Legend_Gallery_Image_Map__c
      WHERE Legend_Gallery_Image__c = :lgiId AND Parent_Object_Id__c != :objId
    ];
    for (Legend_Gallery_Image_Map__c m : maps) {
      relatedParentMap.put(m.Parent_Object_Id__c, m);
    }
    Set<String> parentIds = relatedParentMap.keySet();

    String queryString = 'SELECT Id, Name FROM ';
    queryString += dr.getName() + ' WHERE Id IN :parentIds';
    List<sObject> parentObjs = Database.query(queryString);

    for (sObject o : parentObjs) {
      results.add(new associatedParent(o, relatedParentMap.get((String) o.get('Id'))));
    }
    return results;
  }

  @RemoteAction
  public static PageReference createAssociations(String objId, List<String> imageIds) {
    List<Legend_Gallery_Image_Map__c> lgims = new List<Legend_Gallery_Image_Map__c>();

    for (String imgId : imageIds) {
      lgims.add(new Legend_Gallery_Image_Map__c(Parent_object_Id__c = objId, Legend_Gallery_Image__c = imgId));
    }
    try {
      insert lgims;
      return new PageReference('/apex/LegendImageGallery?id=' + objId);
    } catch (Exception e) {
      System.debug('An Error happend when creating a Marketing Image. It Said ' + e.getMessage());
      return null;
    }
  }

  @RemoteAction
  global static void setDefault(String imageId, String objectId) {
    Schema.SObjectType token = Id.valueOf(objectId).getSObjectType();
    Schema.DescribeSObjectResult dr = token.getDescribe();
    String queryString = 'SELECT Id, Legend_Gallery_Image__c FROM ';
    queryString += dr.getName() + ' WHERE Id = \'' + objectId + '\'';
    sObject obj = Database.query(queryString);

    //If this is already the default marketing image lets assume we want
    //to remove that relationship and set Product2.Default_marketing_Image__c to null
    //else we set it the the MArketing_Image__c Id
    if (obj.get('Legend_Gallery_Image__c') == imageId) {
      obj.put('Legend_Gallery_Image__c', null);
    } else {
      obj.put('Legend_Gallery_Image__c', imageId);
    }
    update obj;
  }

  /******************************************************************************************************************/

  private static Set<Id> findImageIds(Integer start_at, Integer resultSize, String objId) {
    String objType = Id.valueOf(objId).getSObjectType().getDescribe().getName();
    Set<Id> imageIds = new Set<Id>();
    List<Legend_Gallery_Image_Map__c> maps = [
      SELECT Id, Legend_Gallery_Image__c
      FROM Legend_Gallery_Image_Map__c
      WHERE Parent_Object_id__c = :objId AND Legend_Gallery_Image__c != NULL
      ORDER BY CreatedDate ASC
      LIMIT :resultSize
      OFFSET :start_at
    ];
    for (Legend_Gallery_Image_Map__c lgim : maps) {
      imageIds.add(lgim.Legend_Gallery_Image__c);
    }
    System.debug(' imageIds Line 497 = ' + imageIds);
    return imageIds;
  }

  private static Set<Id> findImageIds(String objId) {
    Set<Id> imageIds = new Set<Id>();
    List<Legend_Gallery_Image_Map__c> maps = [
      SELECT Id, Legend_Gallery_Image__c
      FROM Legend_Gallery_Image_Map__c
      WHERE Parent_Object_id__c = :objId AND Legend_Gallery_Image__c != NULL
      ORDER BY CreatedDate ASC
    ];
    for (Legend_Gallery_Image_Map__c m : maps) {
      imageIds.add(m.Legend_Gallery_Image__c);
    }
    return imageIds;
  }

  public static Legend_Gallery_Image__c reloadImage(Id imageId) {
    return [
      SELECT
        Id,
        Name,
        ENG_Description__c,
        FR_Description__c,
        Active_S3_Object__c,
        Active_S3_object__r.Id,
        Active_S3_object__r.AWS_Link__c,
        Active_S3_object__r.File_Name__c,
        Active_S3_object__r.Path__c,
        Active_S3_object__r.Bucket_Name__c,
        Active_S3_Object__r.Image_Height__c,
        Active_S3_Object__r.Image_Width__c,
        Active_S3_Object__r.URL_Gallery__c,
        Active_S3_object__r.URL_500x500__c,
        Active_S3_object__r.URL_700w__c,
        Active_S3_object__r.URL_1280w__c,
        Active_S3_object__r.URL_Original__c,
        (
          SELECT
            Id,
            Name,
            CreatedBy.Name,
            CreatedDate,
            AWS_S3_Object__c,
            AWS_S3_object__r.Id,
            AWS_S3_object__r.AWS_Link__c,
            AWS_S3_object__r.File_Name__c,
            AWS_S3_object__r.Path__c,
            AWS_S3_object__r.Bucket_Name__c,
            AWS_S3_Object__r.Image_Height__c,
            AWS_S3_Object__r.Image_Width__c,
            AWS_S3_Object__r.URL_Gallery__c,
            AWS_S3_object__r.URL_500x500__c,
            AWS_S3_object__r.URL_700w__c,
            AWS_S3_object__r.URL_1280w__c,
            AWS_S3_object__r.URL_Original__c
          FROM Legend_Gallery_Image_Versions__r
          ORDER BY CreatedDate DESC
        )
      FROM Legend_Gallery_Image__c
      WHERE Id = :imageId
      LIMIT 1
    ];
  }
}
