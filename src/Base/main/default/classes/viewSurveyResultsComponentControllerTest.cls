@isTest
private class viewSurveyResultsComponentControllerTest {
  @isTest
  static void testResultController() {
    Survey__c mySurvey = new Survey__c();
    mySurvey.Submit_Response__c = 'empty';
    insert mySurvey;

    viewSurveyResultsComponentController vsr = new viewSurveyResultsComponentController();
    vsr.surveyId = mySurvey.Id;
    vsr.getSurveysTaken();

    String mySurveyId = mySurvey.Id;
    PageReference pageRef = new PageReference('/' + vsr.reportId + '?pv0=' + mySurveyId.substring(0, 15));
    System.assertEquals(pageRef.getURL(), vsr.getResults().getURL());
  }
}
