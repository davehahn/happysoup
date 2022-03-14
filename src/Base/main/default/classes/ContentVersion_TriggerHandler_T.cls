/**
 * Created by dave on 2021-12-13.
 */

@IsTest
private class ContentVersion_TriggerHandler_T {
  private static final String FILE_NAME = 'TestFile';

  @IsTest
  static void insertPublic() {
    ContentVersion cv = new ContentVersion(
      Title = FILE_NAME,
      PathOnClient = '/' + FILE_NAME + '.jpg',
      VersionData = Blob.valueOf('version data blob'),
      Origin = 'C'
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
      Origin = 'C'
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
