/**
 * Created by dave on 2022-07-19.
 */

@IsTest
private class TA_Lead_ValidateStatus_T {
  @IsTest
  static void beforeInsert_TA() {
    TA_Lead_TestHelper helper = TA_Lead_TestHelper.getInstance();
    Lead newLead = Factory_Lead.buildLead(true);
    newLead.Id = TestUtility.getFakeId(Lead.SObjectType);
    newLead.OwnerId = helper.getQueue().Id;
    newLead.Status = 'New';

    List<Lead> newList = new List<Lead>{ newLead };

    new TA_Lead_ValidateStatus().beforeInsert(newList);
    List<Database.Error> errors = newList[0].getErrors();
    System.assertEquals(0, errors.size(), 'There should be no errors');

    newList[0].Status = 'Accepted';
    new TA_Lead_ValidateStatus().beforeInsert(newList);
    errors = newList[0].getErrors();

    System.assertEquals(1, errors.size(), 'There should be 1 error');
    System.assertEquals( errors.get(0).getMessage(), 'A Lead owned by a Queue can only have a Status of "New"');
  }

  @IsTest
  static void beforeUpdate_TA() {
    TA_Lead_TestHelper helper = TA_Lead_TestHelper.getInstance();
    Lead oldLead = Factory_Lead.buildLead(true);
    oldLead.Id = TestUtility.getFakeId(Lead.SObjectType);
    oldLead.OwnerId = helper.getQueue().Id;
    oldLead.Status = 'New';
    Lead newLead = oldLead.clone(true, true, true, true);
    newLead.OwnerId = helper.getUser().Id;
    newLead.Status = 'Accepted';

    List<Lead> oldList = new List<Lead>{ oldLead };
    List<Lead> newList = new List<Lead>{ newLead };

    new TA_Lead_ValidateStatus().beforeUpdate(newList, oldList);
    List<Database.Error> errors = newList[0].getErrors();
    System.assertEquals(0, errors.size(), 'There should be no errors');

    newList[0].Status = 'New';
    new TA_Lead_ValidateStatus().beforeUpdate(newList, oldList);
    errors = newList[0].getErrors();

    System.assertEquals(1, errors.size(), 'There should be 1 error');
    System.assertEquals( errors.get(0).getMessage(), 'Only Leads owned by a Queue can have a Status of "New"');

    newList[0].Status = 'Accepted';
    newLIst[0].OwnerId = helper.getQueue().Id;
    new TA_Lead_ValidateStatus().beforeUpdate(newList, oldList);
    errors = newList[0].getErrors();

    System.assertEquals(1, errors.size(), 'There should be 1 error');
    System.assertEquals( errors.get(0).getMessage(), 'A Lead owned by a Queue can only have a Status of "New"');
  }
}
