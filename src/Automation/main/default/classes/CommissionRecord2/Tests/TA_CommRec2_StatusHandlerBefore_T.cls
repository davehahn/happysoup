/**
 * Created by dave on 2022-01-12.
 */

@IsTest
private class TA_CommRec2_StatusHandlerBefore_T {
  private static User u;

  private static List<CommissionRecord2__c> newList;
  private static List<CommissionRecord2__c> oldList;

  @testSetup
  static void dataSetup() {
    TA_CommRec2_TestHelper.testDataSetup();
  }

  private static void buildUser() {
    u = Factory_User.newUser('TestFirst', 'TestLast', 'System Administrator', null);
    insert u;
  }

  private static void init(String startStatus, String newStatus) {
    buildUser();
    TA_CommRec2_TestHelper helper = new TA_CommRec2_TestHelper();
    helper.commRec.Id = TestUtility.getFakeId(CommissionRecord2__c.SObjectType);
    helper.commRec.Status__c = startStatus;
    if (startStatus == 'Reviewed') {
      helper.commRec.Reviewed_By__c = u.Id;
    }
    if (startStatus == 'Approved') {
      helper.commRec.Reviewed_By__c = u.Id;
      helper.commRec.Approved_By__c = u.Id;
      helper.commRec.Approved_On__c = DateTime.now();
    }

    newList = helper.getNewList();
    oldList = helper.getOldList();

    newList[0].Status__c = newStatus;
  }

  @IsTest
  static void TA_BeforeUpdate_toReviewed() {
    init('New', 'Reviewed');

    System.runAs(U) {
      Test.startTest();
      new TA_CommRec2_StatusHandlerBefore().beforeUpdate(newList, oldList);
      Test.stopTest();

      System.assertEquals(u.Id, newList[0].Reviewed_By__c);
    }
  }

  @IsTest
  static void TA_BeforeUpdate_toApproved() {
    init('New', 'Approved');

    System.runAs(U) {
      Test.startTest();
      new TA_CommRec2_StatusHandlerBefore().beforeUpdate(newList, oldList);
      Test.stopTest();

      System.assertEquals(u.Id, newList[0].Approved_By__c);
      System.assert(newList[0].Approved_On__c != null);
    }
  }

  @IsTest
  static void TA_BeforeUpdate_ApprovedtoNew() {
    init('Reviewed', 'New');

    System.runAs(U) {
      Test.startTest();
      new TA_CommRec2_StatusHandlerBefore().beforeUpdate(newList, oldList);
      Test.stopTest();

      System.assert(newList[0].Reviewed_By__c == null);
    }
  }

  @IsTest
  static void TA_BeforeUpdate_toDisputed() {
    init('Approved', 'Disputed');

    System.runAs(U) {
      Test.startTest();
      new TA_CommRec2_StatusHandlerBefore().beforeUpdate(newList, oldList);
      Test.stopTest();

      System.assert(newList[0].Reviewed_By__c != null);
      System.assert(newList[0].Approved_By__c == null);
      System.assert(newList[0].Approved_On__c == null);
      System.assert(newList[0].Previously_Approved_On__c != null);
    }
  }
}
