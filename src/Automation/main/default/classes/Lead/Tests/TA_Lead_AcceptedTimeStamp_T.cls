/**
 * Created by dave on 2022-06-21.
 */

@IsTest
private class TA_Lead_AcceptedTimeStamp_T {
  @testSetup
  static void dataSetup() {
    //TA_Lead_TestHelper.dataSetup();
  }


  @IsTest
  static void beforeUpdate_accepted_TA() {
    Group queue = new Group(
      Type = 'Queue',
      DeveloperName = 'Lead_UnitTest_Queue',
      Name = 'Lead UnitTest Queue'
    );
    User u = Factory_User.createUser('Lead', 'UnitTester', 'System Administrator');
    insert queue;
    Lead oldLead = Factory_Lead.buildLead( true );
    oldLead.Id = TestUtility.getFakeId(Lead.SObjectType);
    oldLead.OwnerId = queue.Id;
    Lead newLead = oldLead.clone( true, true, true, true );
    newLead.OwnerId = u.Id;

    List<Lead> newList = new List<Lead>{newLead};
    List<Lead> oldList = new List<Lead>{oldLead};

    Test.startTest();
    new TA_Lead_AcceptedTimeStamp().beforeUpdate( newList, oldList );
    Test.stopTest();

    System.assert( oldList[0].Accepted_On__c == null );
    System.assert( newList[0].Accepted_On__c != null );
  }

  @IsTest
  static void beforeUpdate_unaccepted_TA() {
    Group queue = new Group(
      Type = 'Queue',
      DeveloperName = 'Lead_UnitTest_Queue',
      Name = 'Lead UnitTest Queue'
    );
    User u = Factory_User.createUser('Lead', 'UnitTester', 'System Administrator');
    insert queue;
    Lead oldLead = Factory_Lead.buildLead( true );
    oldLead.Id = TestUtility.getFakeId(Lead.SObjectType);
    oldLead.OwnerId = u.Id;
    oldLead.Accepted_On__c = DateTime.now();
    Lead newLead = oldLead.clone( true, true, true, true );
    newLead.OwnerId = queue.Id;

    List<Lead> newList = new List<Lead>{newLead};
    List<Lead> oldList = new List<Lead>{oldLead};

    Test.startTest();
    new TA_Lead_AcceptedTimeStamp().beforeUpdate( newList, oldList );
    Test.stopTest();

    System.assert( oldList[0].Accepted_On__c != null );
    System.assert( newList[0].Accepted_On__c == null );
  }
}
