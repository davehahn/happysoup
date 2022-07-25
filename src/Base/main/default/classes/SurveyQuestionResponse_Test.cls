@isTest
private class SurveyQuestionResponse_Test {
  /*
    in the SurveyTestingUtil class questionIds[4] is the NPS question
    this was responded to with a score of 4 so...
    the SurveyQuestionResponse__c.NPS_Response should = 4
    the Contact.Current_NPS_Score__c should = 4
  */

  @isTest
  static void triggerHandler_Test() {
    SurveyTestingUtil stu = new SurveyTestingUtil();
    Contact c = [SELECT Id, Current_NPS_Score__c FROM Contact WHERE Id = :stu.contactId];
    SurveyQuestionResponse__c response = [
      SELECT Id, NPS_Response__c, Response__c
      FROM SurveyQuestionResponse__c
      WHERE Survey_Question__c = :stu.questionIds[4] AND SurveyTaker__c = :stu.surveyTakerId
      LIMIT 1
    ];

    System.assertEquals(4, c.Current_NPS_Score__c);
    System.assertEquals(4, response.NPS_response__c);
    System.assertEquals('4', response.Response__c);
  }
}
