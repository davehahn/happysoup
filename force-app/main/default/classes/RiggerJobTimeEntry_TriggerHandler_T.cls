/**
 * Created by dave on 2019-11-22.
 */

@IsTest
private class RiggerJobTimeEntry_TriggerHandler_T
{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void TotalTimeShouldBeSetOnInsert_Test()
  {
    Rigger_Job__c rj = new Rigger_Job__c();
    insert rj;
    Rigger_Job_Time_Entry__c tj = new Rigger_Job_Time_Entry__c(
      Start_At__c = DateTime.now().addHours( -3 ),
      End_At__c = DateTime.now(),
      Rigger_Job__c = rj.Id
    );
    Test.startTest();
    insert tj;
    Test.stopTest();
    tj = [SELECT Id, Total_Time__c FROM Rigger_Job_Time_Entry__c WHERE Id = :tj.Id];
    System.assertEquals( 180, tj.Total_Time__c );
  }

  @IsTest
  static void TotalTimeShouldBeSetOnUpdate_Test()
  {
    Rigger_Job__c rj = new Rigger_Job__c();
    insert rj;
    Rigger_Job_Time_Entry__c tj = new Rigger_Job_Time_Entry__c(
      Start_At__c = DateTime.now().addHours( -3 ),
      Rigger_Job__c = rj.Id
    );
    insert tj;
    tj = [SELECT Id, Total_Time__c FROM Rigger_Job_Time_Entry__c WHERE Id = :tj.Id];
    System.assertEquals( null, tj.Total_Time__c );
    Test.startTest();
    tj.End_At__c = DateTime.now();
    update tj;
    Test.stopTest();
    tj = [SELECT Id, Total_Time__c FROM Rigger_Job_Time_Entry__c WHERE Id = :tj.Id];
    System.assertEquals( 180, tj.Total_Time__c );
  }
}