/**
 * Created by dave on 2022-04-04.
 */

@IsTest
private class TA_Project_RetailBoatSaleFunded_T {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void afterUpdate() {
    Id boatSaleId = RetailBoatSaleFunded_TestHelper.testDataCreate();

    List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :boatSaleId];
    Integer beforeTaskCount = tasks.size();

    AcctSeed__Project__c sale = new AcctSeed__Project__c(
      Id = boatSaleId,
      Payment_Method__c = 'Finance',
      Business_Office_Status__c = TA_Project_RetailBoatSaleFunded.FUNDED_STATUS
    );
    System.debug('here');
    Test.startTest();
    MetadataTriggerHandler.bypass('TA_Project_Legacy');
    update sale;
    MetadataTriggerHandler.clearBypass('TA_Project_Legacy');
    Test.stopTest();

    tasks = [SELECT Id, CreatedDate, ActivityDate FROM Task WHERE WhatId = :boatSaleId];
    System.debug(tasks);
    DateTime created = tasks[1].CreatedDate.addDays(Task_Service.DUEDATE_OFFSET);
    Date expected = Date.newInstance(created.year(), created.month(), created.day());

    System.assertEquals(2, tasks.size() - beforeTaskCount);
    System.assertEquals(expected, tasks[1].ActivityDate);
  }
}
