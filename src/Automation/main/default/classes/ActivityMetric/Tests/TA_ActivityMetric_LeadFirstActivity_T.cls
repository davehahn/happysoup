/**
 * Created by dave on 2022-07-05.
 */

@IsTest
private class TA_ActivityMetric_LeadFirstActivity_T
{

  static Lead theLead;
  static DateTime timeStamp;

  private static void init() {
    theLead= Factory_Lead.buildLead( true );
    TriggerBase.bypass('Lead');
    insert theLead;
    TriggerBase.clearBypass('Lead');
    timeStamp = DateTime.now();
  }

  @IsTest
  static void afterInsert(){
    init();

    ActivityMetric am = new ActivityMetric(
      BaseId = theLEad.Id,
      LastEmailDateTime = timeStamp,
      LastActivityDateTime = timeStamp
    );
    Test.startTest();
    insert am;
    Test.stopTest();

    theLead = [SELECT Id, First_Activity_Date__c FROM Lead WHERE Id = : theLead.Id];
    System.assertEquals( timeStamp, theLEad.First_Activity_Date__c );

  }

  @IsTest
  static void afterUpdate(){
    init();

    ActivityMetric am = new ActivityMetric(
      BaseId = theLead.Id
    );
    TriggerBase.bypass('ActivityMetric');
    insert am;
    TriggerBase.clearBypass('ActivityMetric');

    am.LastEmailDateTime = timeStamp;
    am.LastActivityDateTime = timeStamp;
    Test.startTest();
    update am;
    Test.stopTest();

    theLead = [SELECT Id, First_Activity_Date__c FROM Lead WHERE Id = : theLead.Id];
    System.assertEquals( timeStamp, theLEad.First_Activity_Date__c );

  }

}