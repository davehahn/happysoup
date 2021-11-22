/**
 * Created by dave on 2021-11-25.
 */

@IsTest
private class JiraConnect_T
{

//  @testSetup static void dataSetup()
//  {
//    new Factory_TestData();
//    Factory_CustomSettings.setupInventorySettings();
//  }

  private static void setMock() {
    Test.setMock(
      HttpCalloutMock.class,
      new Factory_SystemIssue.JiraSuccessCalloutMock()
    );
  }

  @IsTest
  static void  jiraProjectMap_Test()
  {
    List<Jira_Project_Type__mdt> projectTypes = Jira_Project_Type__mdt.getAll().values();
    Test.startTest();
    Map<String, JiraConnect.JiraProject> result = JiraConnect.jiraProjectMap;
    Test.stopTest();

    System.assertEquals( projectTypes.size(), result.keySet().size() );
  }

  @IsTest
  static void constructorTest(){
    setMock();
    TriggerHandler.bypass('SystemIssue_TriggerHandler');
    System_Issue__c si = Factory_SystemIssue.buildIssue();
    insert si;
    TriggerHandler.clearBypass('SystemIssue_TriggerHandler');
    List<System_Issue__c> newRecords = new List<System_Issue__c>{ si };

    Test.startTest();
    JiraConnect jc = new JiraConnect( newRecords, null );
    Test.stopTest();

    System.assertEquals( 1, jc.newRecords.size() );
    System.assertEquals( null, jc.oldRecords );
    System.assertEquals('System_Issue__c', jc.recordSobjectType );
  }

  @IsTest
  static void createIssues_Test(){
    setMock();
    TriggerHandler.bypass('SystemIssue_TriggerHandler');
    System_Issue__c si = Factory_SystemIssue.buildIssue();
    insert si;
    TriggerHandler.clearBypass('SystemIssue_TriggerHandler');
    List<System_Issue__c> newRecords = new List<System_Issue__c>{ si };

    Test.startTest();
    new JiraConnect( newRecords, null ).createIssues();
    Test.stopTest();

  }

  @IsTest
  static void updateIssues_SystemIssue_Test(){
    setMock();
    TriggerHandler.bypass('SystemIssue_TriggerHandler');
    System_Issue__c si = Factory_SystemIssue.buildIssue();
    insert si;
    TriggerHandler.clearBypass('SystemIssue_TriggerHandler');
    System_Issue__c oldRecord = si.clone(true, true, true, true);
    si.Description__c = 'Changed description in Unit Test';
    List<System_Issue__c> newRecords = new List<System_Issue__c>{ si };
    Map<Id, System_Issue__c> oldRecordMap = new Map<Id, System_Issue__c>{ oldRecord.Id => oldRecord};

    Test.startTest();
    new JiraConnect( newRecords, oldRecordMap ).updateIssues();
    Test.stopTest();

  }

  @IsTest
  static void updateIssue_ContentDocumentLink_Test(){
    setMock();
    TriggerHandler.bypass('SystemIssue_TriggerHandler');
    System_Issue__c si = Factory_SystemIssue.buildIssue();
    insert si;
    TriggerHandler.clearBypass('SystemIssue_TriggerHandler');
    ContentVersion contentVersion = new ContentVersion(PathOnClient = 'PathOnClient', VersionData = Blob.valueOf('Test'));
    insert contentVersion;
    ContentVersion createdContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
    TriggerHandler.bypass('ContentDocumentLink_TriggerHandler');
    ContentDocumentLink randomContentDocumentLink =
      new ContentDocumentLink(
        ContentDocumentId = createdContentVersion.ContentDocumentId,
        LinkedEntityId = si.Id,
        ShareType = 'V'
      );
    insert randomContentDocumentLink;
    TriggerHandler.clearBypass('ContentDocumentLink_TriggerHandler');

    List<ContentDocumentLink> newRecords = new List<ContentDocumentLink>{ randomContentDocumentLink };
    Test.startTest();
    new JiraConnect( newRecords, null ).updateIssues();
    Test.stopTest();
  }
}