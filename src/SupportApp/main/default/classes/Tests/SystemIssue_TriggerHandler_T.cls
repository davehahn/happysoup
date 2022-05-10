/**
 * Created by dave on 2020-01-03.
 */

@IsTest
private class SystemIssue_TriggerHandler_T {
  static Map<String, Integer> countByCategory;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void setMock() {
    Test.setMock(
      HttpCalloutMock.class,
      new Factory_SystemIssue.JiraSuccessCalloutMock()
    );
  }

  private static void initCategoryCounter(){
    countByCategory = new Map<String, Integer>();
    for (
      String cat : LGND_Utilities.getPicklistValues(
      'System_Issue__c',
      'Status_Category__c'
    )
    ) {
      countByCategory.put(cat, 0);
    }
  }

  @IsTest
  static void insertAndUpdate_Owner_Test() {
    Id cUser = UserInfo.getUserId();
    Id que = [
      SELECT Id
      FROM Group
      WHERE Type = 'Queue' AND Name = 'Development'
      LIMIT 1
    ]
    .Id;
    setMock();
    System_Issue__c si = Factory_SystemIssue.buildIssue();
    insert si;
    si = [SELECT Id, OwnerId FROM System_Issue__c WHERE Id = :si.Id];
    System.assertEquals(que, si.OwnerId);
    si.OwnerId = cUser;
    update si;
    si = [SELECT Id, OwnerId FROM System_Issue__c WHERE Id = :si.Id];
    System.assertEquals(cUser, si.OwnerId);
  }

  @IsTest
  static void insert_RecordType_Standard_Test() {
    setMock();
    System_Issue__c si = Factory_SystemIssue.buildIssueWithType('Bug');
    si.Type__c = 'Bug';
    Test.startTest();
    insert si;
    Test.stopTest();
    si = [SELECT Id, RecordTypeId FROM System_Issue__c WHERE Id = :si.Id];

    System.assertEquals(
      si.RecordTypeId,
      new Application_RecordType().getSystemIssueRecordTypes().getStandardId(),
      'Should have a Standard RecordType'
    );
  }

  @IsTest
  static void insert_RecordType_Epic_Test() {
    setMock();
    System_Issue__c si = Factory_SystemIssue.buildIssueWithType('Epic');
    Test.startTest();
    insert si;
    Test.stopTest();
    si = [SELECT Id, RecordTypeId FROM System_Issue__c WHERE Id = :si.Id];

    System.assertEquals(
      si.RecordTypeId,
      new Application_RecordType().getSystemIssueRecordTypes().getEpicId(),
      'Should have an Epic RecordType'
    );
  }

  @IsTest
  static void insert_StatusCategory_Test() {
    setMock();
    initCategoryCounter();
    List<System_Issue__c> issues = Factory_SystemIssue.buildOneOfEachStatus();
    Test.startTest();
    insert issues;
    Test.stopTest();
    issues = [SELECT Id, Status__c, Status_Category__c FROM System_Issue__c];
    for (System_Issue__c si : issues) {
      countByCategory.put(
        si.Status_Category__c,
        countByCategory.get(si.Status_Category__c) + 1
      );
    }

    System.assertEquals(
      3,
      countByCategory.get('To Do'),
      'There should be 3 To Do\'s'
    );
    System.assertEquals(
      1,
      countByCategory.get('In Progress'),
      'The should be 1 In Progress'
    );
    System.assertEquals(
      5,
      countByCategory.get('Done'),
      'There should be 5 Done'
    );
  }

  @IsTest
  static void update_StatusCategory_Test() {
    setMock();
    initCategoryCounter();
    List<System_Issue__c> issues = Factory_SystemIssue.buildOneOfEachStatus();
    insert issues;
    for( System_Issue__c si : issues ){
      if( si.Status__c == 'In Progress') {
        si.Status__c = 'Done';
      }
    }
    Test.startTest();
    update issues;
    Test.stopTest();
    issues = [SELECT Id, Status__c, Status_Category__c FROM System_Issue__c];
    for (System_Issue__c si : issues) {
      countByCategory.put(
        si.Status_Category__c,
        countByCategory.get(si.Status_Category__c) + 1
      );
    }

    System.assertEquals(
      3,
      countByCategory.get('To Do'),
      'There should be 3 To Do\'s'
    );
    System.assertEquals(
      0,
      countByCategory.get('In Progress'),
      'The should be 0 In Progress'
    );
    System.assertEquals(
      6,
      countByCategory.get('Done'),
      'There should be 6 Done'
    );
  }

  @IsTest
  static void percentageCalculation_Test(){
    setMock();
    System_Issue__c epic = Factory_SystemIssue.buildIssueWithType('Epic');
    insert epic;
    List<System_Issue__c> stories = Factory_SystemIssue.buildChildIssues( epic.Id, 10 );
    insert stories;

    stories[0].Status__c = 'Done';
    stories[1].Status__c = 'Done';
    stories[2].Status__c = 'Done';
    stories[3].Status__c = 'In Progress';
    stories[4].Status__c = 'In Progress';
    update stories;

    epic = [SELECT Id, Story_Count_Done__c, Story_Count_In_Progress__c, Story_Count_To_Do__c FROM System_Issue__c WHERE Id = :epic.Id];
    System.assertEquals( 3, epic.Story_Count_Done__c, 'Should be 3 complete');
    System.assertEquals( 2, epic.Story_Count_In_Progress__c, 'Should be 2 in Progress');
    System.assertEquals( 5, epic.Story_Count_To_Do__c, 'Should be 5 To Do');

  }

}
