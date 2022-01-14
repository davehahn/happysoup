/**
 * Created by dave on 2022-01-13.
 */
@IsTest
private class TA_CommRec2_StatusHandlerAfter_T
{
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
    //buildUser();
    TA_CommRec2_TestHelper helper = new TA_CommRec2_TestHelper();
    helper.commRec.Id = TestUtility.getFakeId(CommissionRecord2__c.SObjectType);
    helper.commRec.Status__c = startStatus;

    newList = helper.getNewList();
    oldList = helper.getOldList();

    newList[0].Status__c = newStatus;
  }

  @IsTest
  static void TA_AfterUpdate_ReviewedToApproved(){
    init('Reviewed', 'Approved');

    Test.startTest();
    new TA_CommRec2_StatusHandlerAfter().afterUpdate( newLIst, OldList);
    Test.stopTest();
  }

  @IsTest
  static void TA_AfterUpdateApprovedToReviewed(){
    init('Approved', 'Reviewed');

    Test.startTest();
    new TA_CommRec2_StatusHandlerAfter().afterUpdate( newLIst, OldList);
    Test.stopTest();
  }

  @IsTest
  static void TA_AfterUpdate_DisputedToApproved(){
    init('Disputed', 'Approved');

    Test.startTest();
    new TA_CommRec2_StatusHandlerAfter().afterUpdate( newLIst, OldList);
    Test.stopTest();
  }

  @IsTest
  static void TA_AfterUpdate_ReviewedToNew(){
    init('Reviewed', 'New');

    Test.startTest();
    new TA_CommRec2_StatusHandlerAfter().afterUpdate( newLIst, OldList);
    Test.stopTest();
  }

  @IsTest
  static void TA_AfterUpdateApprovedToNew(){
    init('Approved', 'New');

    Test.startTest();
    new TA_CommRec2_StatusHandlerAfter().afterUpdate( newLIst, OldList);
    Test.stopTest();
  }

}