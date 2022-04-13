/**
 * Created by dave on 2022-04-04.
 */

@IsTest
private class RetailBoatSaleFundedEvent_T {
  static Id boatSaleId;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void afterInsert() {
    boatSaleId = RetailBoatSaleFunded_TestHelper.testDataCreate();
    AcctSeed__Project__c boatSale = [
      SELECT Id, Name, AcctSeed__Account__c
      FROM AcctSeed__Project__c
      WHERE Id = :boatSaleId
    ];

    List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :boatSaleId];
    Integer beforeTaskCount = tasks.size();

    Retail_Boat_Sale_Funded_Event__e evt = new Retail_Boat_Sale_Funded_Event__e(ProjectId__c = boatSaleId);

    Test.startTest();
    TriggerBase.bypass('AcctSeed__Project__c');
    TriggerBase.bypass('AcctSeed__Project_Task__c');
    TriggerBase.bypass('AcctSeedERP__Material__c');
    Database.SaveResult sr = EventBus.publish(evt);
    TriggerBase.clearAllBypasses();
    Test.stopTest();

    tasks = [SELECT Id FROM Task WHERE WhatId = :boatSaleId];

    List<AcctSeed__Project__c> accountERPs = [
      SELECT Id
      FROM AcctSeed__Project__c
      WHERE AcctSeed__Account__c = :boatSale.AcctSeed__Account__c
    ];

    System.assertEquals(true, sr.isSuccess());
    System.assertEquals(2, tasks.size() - beforeTaskCount);
    System.assertEquals(2, accountERPs.size());
  }
}
