/**
 * Created by dave on 2020-01-03.
 */
@IsTest
public class Factory_SystemIssue {
  public class JiraSuccessCalloutMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse response = new HttpResponse();
      response.setStatusCode(200);
      return response;
    }
  }

  public static System_Issue__c buildIssue() {
    String priority = LGND_Utilities.getPicklistValues(
      'System_Issue__c',
      'Priority__c'
    )[0];
    String type = LGND_Utilities.getPicklistValues(
      'System_Issue__c',
      'Type__c'
    )[0];
    String jiraProject = LGND_Utilities.getPicklistValues(
      'System_Issue__c',
      'Jira_Project__c'
    )[0];
    String department = LGND_Utilities.getPicklistValues(
      'System_Issue__c',
      'Department__c'
    )[0];
    return new System_Issue__c(
      Priority__c = priority,
      Department__c = department,
      Jira_Project__c = jiraProject,
      Type__c = type,
      Subject__c = 'Unit Test Issue',
      Description__c = 'Unit Test Description'
    );
  }

  public static System_Issue__c buildIssueWithType(String issueType) {
    System_Issue__c result = buildIssue();
    result.Type__c = issueType;
    return result;
  }

  public static System_Issue__c buildChildIssueWithTypeAndStatus(Id parentId, String issueType, String status) {
    System_Issue__c result = buildIssue();
    result.Type__c = issueType;
    result.Parent_System_Issue__c = parentId;
    result.Status__c = status;
    return result;
  }

  public static System_Issue__c buildIssueWithStatus(String status) {
    System_Issue__c result = buildIssue();
    result.Status__c = status;
    return result;
  }

  public static LIst<System_Issue__c> buildOneOfEachStatus() {
    List<System_Issue__c> issues = new List<System_Issue__c>();
    for (
      String status : LGND_Utilities.getPicklistValues(
        'System_Issue__c',
        'Status__c'
      )
    ) {
      issues.add(Factory_SystemIssue.buildIssueWithStatus(status));
    }
    return issues;
  }

  public static List<System_Issue__c> buildChildIssues( Id parentId, Integer count){
    List<System_Issue__c> children = new LIst<System_Issue__c>();
    for( Integer i=0; i<count; i++ ){
      children.add( buildChildIssueWithTypeAndStatus( parentId, 'Story', 'New' ) );
    }
    return children;
  }
}
