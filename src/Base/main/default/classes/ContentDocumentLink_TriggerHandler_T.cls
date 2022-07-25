/**
 * Created by dave on 2019-12-31.
 */

@IsTest
private class ContentDocumentLink_TriggerHandler_T {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void systemIssueAfterInsert_Test() {
    System_Issue__c issue = Factory_SystemIssue.buildIssue();
    insert issue;
    ContentVersion contentVersion = new ContentVersion(
      PathOnClient = 'PathOnClient',
      VersionData = Blob.valueOf('Test'),
      Visibility__c = 'Public'
    );
    insert contentVersion;
    ContentVersion createdContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
    ContentDocumentLink randomContentDocumentLink = new ContentDocumentLink(
      ContentDocumentId = createdContentVersion.ContentDocumentId,
      LinkedEntityId = issue.Id,
      ShareType = 'V'
    );
    JCFS.JiraTriggerTestHelper.testAfterInsert(randomContentDocumentLink);
  }
}
