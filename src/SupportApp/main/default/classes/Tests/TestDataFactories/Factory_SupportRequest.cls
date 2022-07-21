/**
 * Created by dave on 2022-05-20.
 */
@IsTest
public class Factory_SupportRequest {
  public static Support_Request__c buildSupportRequest() {
    String priority = LGND_Utilities.getPicklistValues('Support_Request__c', 'Priority__c')[0];
    String type = LGND_Utilities.getPicklistValues('Support_Request__c', 'Type__c')[0];

    return new Support_Request__c(
      Priority__c = priority,
      Type__c = type,
      Subject__c = 'Subject From Test Factory',
      Description__c = 'Description from test factory',
      Requested_Due_Date__c = Date.today().addDays(7),
      Location_GLV1__c = Test_Constants.idGlV1,
      Department_GLV2__c = Test_Constants.idGlV2
    );
  }
}
