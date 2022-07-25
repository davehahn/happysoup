/**
 * Created by dave on 2021-10-28.
 */

@IsTest
private class SystemIssue_Selector_T {
  //
  //  @testSetup static void dataSetup()
  //  {
  //    new Factory_TestData();
  //    Factory_CustomSettings.setupInventorySettings();
  //  }

  @IsTest
  static void allChildrenByParent_Test() {
    TriggerHandler.bypass('SystemIssue_TriggerHandler');
    Id epicRtId = new Application_RecordType().getSystemIssueRecordTypes().getEpicId();
    System_Issue__c epic = Factory_SystemIssue.buildIssueWithType('Epic');
    epic.RecordTYpeId = epicRtId;
    insert epic;
    List<System_Issue__c> stories = Factory_SystemIssue.buildChildIssues(epic.Id, 10);
    insert stories;
    TriggerHandler.clearBypass('SystemIssue_TriggerHandler');

    Test.startTest();
    List<System_Issue__c> result = SystemIssue_Selector.allChildrenByParentId(new Set<Id>{ epic.Id });
    Test.stopTest();

    System.assertEquals(10, result.size(), 'there should be 10 child record');
  }
}
