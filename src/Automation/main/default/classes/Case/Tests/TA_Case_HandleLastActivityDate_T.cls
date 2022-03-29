/**
 * Created by dave on 2022-03-29.
 */

@IsTest
private class TA_Case_HandleLastActivityDate_T
{

  @IsTest
  static void beforeUpdate()
  {
    DateTime dt = DateTime.now();
    Case c = Factory_Case.insertCustomerCommunityCase();
    Case newRecord = c.clone(true, true, true, true );
    newRecord.Last_Activity_Date__c = dt;

    List<Case> oldList = new List<Case>{c};
    List<Case> newList = new List<Case>{newRecord};


    Test.startTest();
    new TA_Case_HandleLastActivityDate().beforeUpdate( newList, oldList );
    Test.stopTest();

    System.assertEquals( dt, newList[0].First_Activity_Date__c);
  }
}