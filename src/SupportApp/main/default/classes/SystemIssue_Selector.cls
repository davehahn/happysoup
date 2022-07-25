/**
 * Created by dave on 2021-10-26.
 */

public inherited sharing class SystemIssue_Selector extends Application_Selector {
  private final List<String> defaultFields = new List<String>{
    'Department__c',
    'Description__c',
    'Epic_Name__c',
    'Jira_Issue__c',
    'Jira_Project__c',
    'Parent_System_Issue__c',
    'Priority__c',
    'RecordTypeId',
    'Reported_By__c',
    'Sprint_Name__c',
    'Status__c',
    'Status_Category__c',
    'Steps_To_Reproduce__c',
    'Subject__c',
    'Name',
    'Time_Spent__c',
    'Type__c'
  };

  public SystemIssue_Selector() {
    this.sObjectName = 'System_Issue__c';
    this.fields = defaultFields;
  }

  public static List<System_Issue__c> allChildrenByParentId(Set<Id> ids) {
    return new SystemIssue_Selector().addWhereIdInField(ids, 'Parent_System_Issue__c').query();
  }
}
