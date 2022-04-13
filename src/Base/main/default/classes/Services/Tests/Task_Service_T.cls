/**
 * Created by dave on 2022-04-01.
 */

@IsTest
private class Task_Service_T {

  static Id boatSaleId;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void createRetailSaleFundedTasks() {
    boatSaleId = RetailBoatSaleFunded_TestHelper.testDataCreate();

    List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :boatSaleId];
    Integer beforeTaskCount = tasks.size();

    Test.startTest();
    Task_Service.createRetailSaleFundedTasks( new Set<Id>{boatSaleId} );
    Test.stopTest();

    tasks = [SELECT Id FROM Task WHERE WhatId = :boatSaleId];

    System.assertEquals( 2, tasks.size() - beforeTaskCount );
  }
}
