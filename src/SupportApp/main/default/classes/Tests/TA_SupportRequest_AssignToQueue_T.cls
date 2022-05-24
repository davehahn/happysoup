/**
 * Created by dave on 2022-05-20.
 */

@IsTest
private class TA_SupportRequest_AssignToQueue_T {

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static Id que = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Support Queue' LIMIT 1].Id;

  @IsTest
  static void beforeInsert() {
    List<Support_Request__c> newList = new List<Support_Request__c>();
    newList.add(Factory_SupportRequest.buildSupportRequest());

    new TA_SupportRequest_AssignToQueue().beforeInsert(newList);

    System.assertEquals(que, newList[0].OwnerId);
  }

  @IsTest
  static void triggerTest(){
    Support_Request__c req = Factory_SupportRequest.buildSupportRequest();

    Test.startTest();
    insert req;
    Test.stopTest();

    req = [SELECT Id, OwnerId FROM Support_Request__c WHERE Id = :req.Id];

    System.assertEquals( que, req.OwnerId, 'Request should be Owned by the Queue');
  }
}
