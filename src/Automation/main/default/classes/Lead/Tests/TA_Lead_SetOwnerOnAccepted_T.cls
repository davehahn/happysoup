/**
 * Created by dave on 2022-07-25.
 */

@IsTest
private class TA_Lead_SetOwnerOnAccepted_T {
  @IsTest
  static void beforeUpdate_TA() {
    Lead oldLead = Factory_Lead.buildLead('LeadTest', 'UnitTesting');
    oldLead.Id = TestUtility.getFakeId(Lead.getSObjectType());
    Lead newLead = oldLead.clone(true, true, true, true);
    newLead.Status = Lead_Service.ACCEPTED_STATUS;

    List<Lead> newList = new List<Lead>{ newLead };
    List<Lead> oldList = new List<Lead>{ oldLead };

    Test.startTest();
    new TA_Lead_SetOwnerOnAccepted().beforeUpdate(newList, oldList);
    Test.stopTest();

    TA_Lead_TestHelper helper = TA_Lead_TestHelper.getInstance();
    System.assertEquals(oldList[0].OwnerId, helper.getQueue().Id);
    System.assertEquals(newList[0].OwnerId, UserInfo.getUserId());
  }

  @IsTest
  static void beforeUpdate_Trigger() {
    Lead l = Factory_Lead.buildLead('LeadTest', 'UnitTesting');
    insert l;
    l.Status = Lead_Service.ACCEPTED_STATUS;

    Test.startTest();
    update l;
    Test.stopTest();

    Lead updatedLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :l.Id];
    TA_Lead_TestHelper helper = TA_Lead_TestHelper.getInstance();
    System.assertEquals(l.OwnerId, helper.getQueue().Id);
    System.assertEquals(updatedLead.OwnerId, UserInfo.getUserId());
  }
}
