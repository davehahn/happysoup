/**
 * Created by dave on 2022-03-28.
 */

@IsTest
private class TA_Task_SetRelatedActivityFields_T {
  @IsTest
  static void afterInsert() {
    Case c = Factory_Case.insertCustomerCommunityCase();
    Task t = new Task(
      Description = 'Unit Test Email',
      Status = 'Completed',
      Subject = 'Email: Unit Test',
      TaskSubType = 'Email',
      WhatId = c.Id
    );
    TriggerBase.bypass('Task');
    insert t;
    TriggerBase.clearBypass('Task');

    List<Task> newList = Database.query(LGND_Utilities.getAllFieldsSOQL('Task'));

    Test.startTest();
    new TA_Task_SetRelatedActivityFields().afterInsert(newList);
    Test.stopTest();

    c = [SELECT Id, Last_Activity_Date__c FROM Case WHERE Id = :c.Id];
    System.assertEquals(newList[0].CreatedDate, c.Last_Activity_Date__c);
  }
}
