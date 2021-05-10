/**
 * Created by dave on 2020-01-03.
 */

@IsTest
private class SystemIssue_TriggerHandler_T
{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void insertAndUpdate_Test()
  {
    Id cUser = UserInfo.getUserId();
    Id que =  [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Development' LIMIT 1].Id;
    Test.setMock(HttpCalloutMock.class, new Factory_SystemIssue.JiraSuccessCalloutMock());
    System_Issue__c si = Factory_SystemIssue.buildIssue();
    insert si;
    si = [SELECT Id, OwnerId FROM System_Issue__c WHERE Id = :si.Id ];
    System.assertEquals( que, si.OwnerId );
    si.OwnerId = cUser;
    update si;
    si = [SELECT Id, OwnerId FROM System_Issue__c WHERE Id = :si.Id ];
    System.assertEquals( cUser, si.OwnerId );
  }
}