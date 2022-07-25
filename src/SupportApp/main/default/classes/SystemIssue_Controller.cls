/**
 * Created by dave on 2020-01-02.
 */

public with sharing class SystemIssue_Controller {
  public class SystemIssueFormOptions {
    @AuraEnabled
    public List<String> priorityOptions;
    @AuraEnabled
    public List<String> jiraProjectOptions;
    @AuraEnabled
    public List<String> departmentOptions;
    @AuraEnabled
    public Map<String, List<String>> issueTypesByProject;

    public SystemIssueFormOptions() {
      this.priorityOptions = LGND_Utilities.getPicklistValues('System_Issue__c', 'Priority__c');
      this.jiraProjectOptions = LGND_Utilities.getPicklistValues('System_Issue__c', 'Jira_Project__c');
      this.departmentOptions = LGND_Utilities.getPicklistValues('System_Issue__c', 'Department__c');
      this.issueTypesByProject = getTypeOptions();
    }

    private Map<String, List<String>> getTypeOptions() {
      Map<String, List<String>> result = new Map<String, List<String>>();
      Map<Id, Jira_Project_Type__mdt> jiraProjectById = new Map<Id, Jira_Project_Type__mdt>(
        Jira_Project_Type__mdt.getAll().values()
      );
      for (Jira_Issue_Type__mdt issue : Jira_Issue_Type__mdt.getAll().values()) {
        if (jiraProjectById.containsKey(issue.Jira_Project_Type__c)) {
          if (!result.containsKey(jiraProjectById.get(issue.Jira_Project_Type__c).MasterLabel)) {
            result.put(jiraProjectById.get(issue.Jira_Project_Type__c).MasterLabel, new List<String>());
          }
          result.get(jiraProjectById.get(issue.Jira_Project_Type__c).MasterLabel).add(issue.Type__c);
        }
      }
      for (String p : result.keySet()) {
        result.get(p).sort();
      }
      return result;
    }
  }

  @AuraEnabled
  public static String initForm() {
    return JSON.serialize(new SystemIssueFormOptions());
  }

  @AuraEnabled
  public static System_Issue__c createIssue(System_Issue__c issue) {
    insert issue;
    return issue;
  }
}
