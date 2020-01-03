/**
 * Created by dave on 2020-01-02.
 */

public with sharing class SystemIssue_Controller
{

  @AuraEnabled
  public static String initForm()
  {
    Map<String, List<String>> result = new Map<String, List<String>>{
      'typeOptions' => LGND_Utilities.getPicklistValues('System_Issue__c', 'Type__c'),
      'priorityOptions' => LGND_Utilities.getPicklistValues('System_Issue__c', 'Priority__c'),
      'jiraProjectOptions' => LGND_Utilities.getPicklistValues('System_Issue__c', 'Jira_Project__c'),
      'departmentOptions' => LGND_Utilities.getPicklistValues('System_Issue__c', 'Department__c')
    };
    return JSON.serialize( result );
  }

  @AuraEnabled
  public static System_Issue__c createIssue( System_Issue__c issue )
  {
    insert issue;
    return issue;
  }

}