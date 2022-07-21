/**
 * Created by dave on 2020-01-03.
 */

@IsTest
private class SystemIssue_Controller_T {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void initForm_Test() {
    String resultJSON = SystemIssue_Controller.initForm();
    SystemIssue_Controller.SystemIssueFormOptions result = (SystemIssue_Controller.SystemIssueFormOptions) JSON.deserialize(
      resultJSON,
      SystemIssue_Controller.SystemIssueFormOptions.class
    );
    Integer priorityCount = LGND_Utilities.getPicklistValues('System_Issue__c', 'Priority__c').size();
    Integer projectOptsCount = LGND_Utilities.getPicklistValues('System_Issue__c', 'Jira_Project__c').size();
    Integer deptOptsCount = LGND_Utilities.getPicklistValues('System_Issue__c', 'Department__c').size();

    System.assertEquals(priorityCount, result.priorityOptions.size());
    System.assertEquals(projectOptsCount, result.jiraProjectOptions.size());
    System.assertEquals(deptOptsCount, result.departmentOptions.size());
  }

  @IsTest
  static void createIssue_Test() {
    Test.setMock(HttpCalloutMock.class, new Factory_SystemIssue.JiraSuccessCalloutMock());
    System_Issue__c si = Factory_SystemIssue.buildIssue();
    si = SystemIssue_Controller.createIssue(si);
    System.assert(si.Id != null, 'Id should be set');
  }
}
