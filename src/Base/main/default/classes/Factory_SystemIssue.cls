/**
 * Created by dave on 2020-01-03.
 */
@IsTest
public class Factory_SystemIssue
{

  public class JiraSuccessCalloutMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse response = new HttpResponse();
      response.setStatusCode(200);
      return response;
    }
  }

  public static System_Issue__c buildIssue()
  {
    String priority = LGND_Utilities.getPicklistValues('System_Issue__c', 'Priority__c')[0];
    String type = LGND_Utilities.getPicklistValues('System_Issue__c', 'Type__c')[0];
    String jiraProject = LGND_Utilities.getPicklistValues('System_Issue__c', 'Jira_Project__c')[0];
    String department = LGND_Utilities.getPicklistValues('System_Issue__c', 'Department__c')[0];
    return new System_Issue__c(
      Priority__c = priority,
      Department__c = department,
      Jira_Project__c = jiraProject,
      Type__c = type,
      Subject__c = 'Unit Test Issue',
      Description__c = 'Unit Test Description'
    );
  }
}