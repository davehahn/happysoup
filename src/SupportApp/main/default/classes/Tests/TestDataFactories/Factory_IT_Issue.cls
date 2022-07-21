/**
 * Created by dave on 2021-11-23.
 */
@IsTest
public class Factory_IT_Issue {
  public class JiraSuccessCalloutMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse response = new HttpResponse();
      response.setStatusCode(200);
      return response;
    }
  }

  public static IT_Issue__c buildIssue() {
    String priority = LGND_Utilities.getPicklistValues('IT_Issue__c', 'Priority__c')[0];
    String category = LGND_Utilities.getPicklistValues('IT_Issue__c', 'Category__c')[0];
    return new IT_Issue__c(
      Priority__c = priority,
      Category__c = category,
      Description__c = 'Description from Test Factory',
      Due_Date__c = Date.today().addDays(7),
      Subject__c = 'Subject from Test Factory',
      Status__c = 'New'
    );
  }
}
