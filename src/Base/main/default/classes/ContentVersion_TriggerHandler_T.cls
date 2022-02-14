/**
 * Created by dave on 2021-12-13.
 */

@IsTest
private class ContentVersion_TriggerHandler_T {
  private static final String FILE_NAME = 'TestFile';

  @IsTest
  static void defaultPublicFiles_Test(){
    String fileName = ContentVersion_TriggerHandler.defaultPublicFileTitles[0] + '_UnitTest.pdf';
    ContentVersion cv = new ContentVersion(
      Title = fileName,
      PathOnClient = '/' + fileName,
      VersionData = Blob.valueOf('version data blob'),
      Origin = 'C'
    );

    Test.startTest();
    insert cv;
    Test.stopTest();

    cv = [SELECT Id, Visibility__C, SharingPrivacy FROM ContentVersion WHERE Id = :cv.Id];

    System.assertEquals( 'Public', cv.Visibility__c, 'Visibility should be Public');
    System.assertEquals(
      'N',
      cv.SharingPrivacy,
      'Should be visible to Everyone'
    );
  }

  @IsTest
  static void insertPublic() {
    ContentVersion cv = new ContentVersion(
      Title = FILE_NAME,
      PathOnClient = '/' + FILE_NAME + '.jpg',
      VersionData = Blob.valueOf('version data blob'),
      Origin = 'C',
      Visibility__c = 'public'
    );

    Test.startTest();
    insert cv;
    Test.stopTest();

    cv = [SELECT Id, SharingPrivacy FROM ContentVersion WHERE Id = :cv.Id];

    System.assertEquals(
      'N',
      cv.SharingPrivacy,
      'Should be visible to Everyone'
    );
  }

  @IsTest
  static void insertPrivate() {
    ContentVersion cv = new ContentVersion(
      Title = FILE_NAME,
      PathOnClient = '/' + FILE_NAME + '.jpg',
      VersionData = Blob.valueOf('version data blob'),
      Origin = 'C',
      Visibility__c = 'Private'
    );

    Test.startTest();
    insert cv;
    Test.stopTest();

    cv = [SELECT Id, SharingPrivacy FROM ContentVersion WHERE Id = :cv.Id];

    System.assertEquals(
      'P',
      cv.SharingPrivacy,
      'Should be Private'
    );
  }

  @IsTest
  static void changeVisibility() {

    ContentVersion cv = new ContentVersion(
      Title = FILE_NAME,
      PathOnClient = '/' + FILE_NAME + '.jpg',
      VersionData = Blob.valueOf('version data blob'),
      Origin = 'C',
      Visibility__c = 'public'
    );
    insert cv;
    cv = [SELECT Id, SharingPrivacy FROM ContentVersion WHERE Id = :cv.Id];
    System.assertEquals(
      'N',
      cv.SharingPrivacy,
      'Should be visible to Everyone'
    );

    cv.Visibility__c = 'Private';

    Test.startTest();
    update cv;
    Test.stopTest();

    cv = [SELECT Id, SharingPrivacy FROM ContentVersion WHERE Id = :cv.Id];

    System.assertEquals(
      'P',
      cv.SharingPrivacy,
      'Should be Private'
    );
  }
}
