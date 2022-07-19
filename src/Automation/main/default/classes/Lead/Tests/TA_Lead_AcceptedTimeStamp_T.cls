/**
 * Created by dave on 2022-06-21.
 */

@IsTest
private class TA_Lead_AcceptedTimeStamp_T {
  @IsTest
  static void beforeUpdate_accepted_TA() {
    TA_Lead_TestHelper helper =  TA_Lead_TestHelper.getInstance();
    Lead oldLead = Factory_Lead.buildLead(true);
    oldLead.Id = TestUtility.getFakeId(Lead.SObjectType);
    Lead newLead = oldLead.clone(true, true, true, true);
    newLead.OwnerId = helper.getUser().Id;

    List<Lead> newList = new List<Lead>{ newLead };
    List<Lead> oldList = new List<Lead>{ oldLead };

    Test.startTest();
    new TA_Lead_AcceptedTimeStamp().beforeUpdate(newList, oldList);
    Test.stopTest();

    System.assert(oldList[0].Accepted_On__c == null);
    System.assert(newList[0].Accepted_On__c != null);
    System.assert(oldList[0].Status == 'New');
    System.assert(newList[0].Status == 'Accepted');
  }

  @IsTest
  static void beforeUpdate_unaccepted_TA() {
    TA_Lead_TestHelper helper = TA_Lead_TestHelper.getInstance();
    Lead oldLead = Factory_Lead.buildLead(true);
    oldLead.Id = TestUtility.getFakeId(Lead.SObjectType);
    oldLead.OwnerId = helper.getUser().Id;
    oldLead.Accepted_On__c = DateTime.now();
    oldLead.Status = 'Accepted';
    Lead newLead = oldLead.clone(true, true, true, true);
    newLead.OwnerId = helper.getQueue().Id;

    List<Lead> newList = new List<Lead>{ newLead };
    List<Lead> oldList = new List<Lead>{ oldLead };

    Test.startTest();
    new TA_Lead_AcceptedTimeStamp().beforeUpdate(newList, oldList);
    Test.stopTest();

    System.assert(oldList[0].Accepted_On__c != null);
    System.assert(newList[0].Accepted_On__c == null);
    System.assert(oldList[0].Status == 'Accepted');
    System.assert(newList[0].Status == 'New');
  }
}
