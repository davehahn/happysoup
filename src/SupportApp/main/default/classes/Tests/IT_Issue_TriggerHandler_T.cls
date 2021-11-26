/**
 * Created by dave on 2021-11-22.
 */

@IsTest
private class IT_Issue_TriggerHandler_T {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static IT_Issue__c requeryIssue(Id issueId) {
    return [SELECT Id, OwnerId, Status__c
    FROM IT_Issue__c WHERE Id = :issueId];
  }

  @IsTest
  static void insertAndUpdateOwner_Test() {
    Id cUser = UserInfo.getUserId();
    Id que = [
      SELECT Id
      FROM Group
      WHERE Type = 'Queue' AND Name = 'IT Issues'
      LIMIT 1
    ]
    .Id;
    IT_Issue__c theIssue = Factory_IT_Issue.buildIssue();
    insert theIssue;
    theIssue = requeryIssue(theIssue.Id);
    System.assertEquals(
      que,
      theIssue.OwnerId,
      'The Queue should own the issue'
    );

    theIssue.ownerId = cUser;
    update theIssue;
    theIssue = requeryIssue(theIssue.Id);
    System.assertEquals(
      cUser,
      theIssue.OwnerId,
      'The User should own the issue'
    );
    System.assertEquals( 'Accepted', theIssue.Status__c);
  }
}
