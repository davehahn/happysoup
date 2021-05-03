public with sharing class viewSurveyResultsComponentController {

  public String surveyId {get;set;}


  public String reportId {get;set;}
  public PageReference results;

  public viewSurveyResultsComponentController()
  {
     ReportFinderUtil rfu = new ReportFinderUtil();
     reportId = rfu.findReportId('Survey with Questions and Responses');
  }

  public List<SurveyTaker__c> getSurveysTaken(){
    return [SELECT Id,Contact__r.Name, Contact__c, User__c, User__r.Name, CreatedDate
            FROM SurveyTaker__c
            WHERE Survey__c = :surveyId
            ORDER BY CreatedDate DESC];
  }


  public pageReference getResults()
  {
    surveyId = surveyId.substring(0,15);
    return new PageReference('/' + reportId + '?pv0=' + surveyId);
  }

}