/**
 * Created by dave on 2019-12-23.
 */

public with sharing class JiraConnect {
  public static Map<String, JiraProject> jiraProjectMap {
    get {
      if (jiraProjectMap == null) {
        jiraProjectMap = new Map<String, JiraProject>();
        for (Jira_Project_Type__mdt jpt : [
          SELECT
            MasterLabel,
            Jira_Project_Id__c,
            (SELECT Type__c, Jira_Issue_Id__c FROM Jira_Issue_Types__r)
          FROM Jira_Project_Type__mdt
        ]) {
          jiraProjectMap.put(jpt.MasterLabel, new JiraProject(jpt));
        }
      }
      return jiraProjectMap;
    }
    set {
    }
  }

  public class JiraProject {
    public String name;
    public String jiraId;
    public Map<String, String> issueMap;

    public JiraProject(Jira_Project_Type__mdt jpt) {
      this.name = jpt.MasterLabel;
      this.jiraId = jpt.Jira_Project_Id__c;
      this.issueMap = new Map<String, String>();
      for (Jira_Issue_Type__mdt it : jpt.Jira_Issue_Types__r) {
        this.issueMap.put(it.Type__c, it.Jira_Issue_Id__c);
      }
    }
  }

  @TestVisible
  private SObject[] newRecords;
  @TestVisible
  private SObject[] oldRecords;
  private Map<Id, SObject> oldMap;
  @TestVisible
  private String recordSobjectType;

  public JiraConnect(SObject[] newRecords, Map<Id, SObject> oldMap) {
    this.newRecords = newRecords;
    this.oldMap = oldMap;
    this.oldRecords = oldMap == null ? null : oldMap.values();
    this.recordSobjectType = newRecords[0]
      .getSObjectType()
      .getDescribe()
      .getName();
  }

  public void createIssues() {
    switch on this.recordSobjectType {
      when 'System_Issue__c' {
        createJiraIssue();
      }
    }
  }

  public void updateIssues() {
    switch on this.recordSobjectType {
      when 'System_Issue__c' {
        updateJiraIssues();
      }
      when 'ContentDocumentLink' {
        updatePushFilesToJira();
      }
    }
  }


  private void createJiraIssue() {
    Map<String, Map<String, List<System_Issue__c>>> toCreateIssuesMap = new Map<String, Map<String, List<System_Issue__c>>>();
    for (System_Issue__c si : (List<System_Issue__c>) this.newRecords) {
      if (
        si.Jira_Project__c != null &&
        jiraProjectMap.containsKey(si.Jira_Project__c)
      ) {
        JiraProject jiraPro = jiraProjectMap.get(si.Jira_Project__c);
        if (!toCreateIssuesMap.containsKey(jiraPro.jiraId)) {
          toCreateIssuesMap.put(
            jiraPro.jiraId,
            new Map<String, List<System_Issue__c>>()
          );
        }
        if (jiraPro.issueMap.containsKey(si.Type__c)) {
          if (
            !toCreateIssuesMap.get(jiraPro.jiraId)
              .containsKey(jiraPro.issueMap.get(si.Type__c))
          ) {
            toCreateIssuesMap.get(jiraPro.jiraId)
              .put(
                jiraPro.issueMap.get(si.Type__c),
                new List<System_Issue__c>()
              );
          }
          toCreateIssuesMap.get(jiraPro.jiraId)
            .get(jiraPro.issueMap.get(si.Type__c))
            .add(si);
        }
      }
    }
    for (String projId : toCreateIssuesMap.keySet()) {
      for (String issueId : toCreateIssuesMap.get(projId).keySet()) {
        System.debug(
          'creating JIRA issue for project ' +
          projId +
          ' issue type ' +
          issueId
        );
        JCFS.API.createJiraIssue(
          projId,
          issueId,
          toCreateIssuesMap.get(projId).get(issueId),
          (List<System_Issue__c>) this.oldRecords
        );
      }
    }
  }


  private void updateJiraIssues() {
    doJiraIssueUpdate(this.newRecords, this.oldRecords);
  }

  private void doJiraIssueUpdate(
    List<SObject> newRecords,
    List<SObject> oldRecords
  ) {
    JCFS.API.pushUpdatesToJira(newRecords, oldRecords);
  }

  private void updatePushFilesToJira() {
    Set<Id> systemIssueIds = new Set<Id>();
    Set<Id> itIssueIds = new Set<Id>();
    for (
      ContentDocumentLink cdl : (List<ContentDocumentLink>) this.newRecords
    ) {
      switch on cdl.LinkedEntityId.getSobjectType().getDescribe().getName(){
        when 'System_Issue__c' {
          systemIssueIds.add(cdl.LinkedEntityId);
        }
        when 'IT_Issue__c' {
          itIssueIds.add(cdl.LinkedEntityId);
        }
      }
    }
    if (systemIssueIds.size() > 0) {
      List<System_Issue__c> systemIssues = [
        SELECT Id
        FROM System_Issue__c
        WHERE Id IN :systemIssueIds
      ];
      doJiraIssueUpdate(systemIssues, null);
    }
    if (itIssueIds.size() > 0) {
      List<IT_Issue__c> itIssues = [
        SELECT Id
        FROM IT_Issue__c
        WHERE Id IN :itIssueIds
      ];
      doJiraIssueUpdate(itIssues, null);
    }
  }
}
