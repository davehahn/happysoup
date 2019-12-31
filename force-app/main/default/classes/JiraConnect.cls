/**
 * Created by dave on 2019-12-23.
 */

public with sharing class JiraConnect
{
  private Id salesforceCaseRtId = LGND_Utilities.recordTypeIdFromName('Case', 'Salesforce');

//  private Map<Id, String> caseRecordTypeToJiraProjectMap = new Map<Id, String>
//  {
//    salesforceCaseRtId => '10403'
//  };

//  private Map<String, String> caseTypeToJiraIssueMap = new Map<String, String>{
//    'Bug' => '10004',
//    'New Feature' => '10101'
//  };

  public static  Map<String, JiraProject> jiraProjectMap{
    get {
      if( jiraProjectMap == null )
      {
        jiraProjectMap = new Map<String, JiraProject>();
        for( Jira_Project_Type__mdt jpt : [ SELECT MasterLabel,
                                                   Jira_Project_Id__c,
                                            ( SELECT Case_Reason__c,
                                                     Jira_Issue_Id__c
                                              FROM Jira_Issue_Types__r)
                                            FROM Jira_Project_Type__mdt ] )
        {
          jiraProjectMap.put( jpt.MasterLabel, new JiraProject( jpt ) );
        }
      }
      return jiraProjectMap;
    }
    set{}
  }


  public class JiraProject {
    public String name;
    public String jiraId;
    public Map<String, String> issueMap;

    public JiraProject( Jira_Project_Type__mdt jpt )
    {
      this.name = jpt.MasterLabel;
      this.jiraId = jpt.Jira_Project_Id__c;
      this.issueMap = new Map<String, String>();
      for( Jira_Issue_Type__mdt it : jpt.Jira_Issue_Types__r )
      {
        this.issueMap.put( it.Case_Reason__c, it.Jira_Issue_Id__c );
      }
    }
  }

  private SObject[] newRecords;
  private SObject[] oldRecords;
  private Map<Id, SObject> oldMap;
  private String recordSobjectType;

  public JiraConnect( SObject[] newRecords, Map<Id,SObject> oldMap )
  {
    this.newRecords = newRecords;
    this.oldMap = oldMap;
    this.oldRecords = oldMap == null ? null : oldMap.values();
    this.recordSobjectType = newRecords[0].getSObjectType().getDescribe().getName();
  }

  public void createIssues()
  {
    switch on this.recordSobjectType
    {
      when 'Case'
      {
       createIssuesFromCases();
      }
    }
  }

  public void updateIssues()
  {
    switch on this.recordSobjectType
    {
      when 'Case'
      {
        updateIssuesFromCases();
      }
      when 'ContentDocumentLink'
      {
        updatePushFilesToJira();
      }
    }
  }

  private void createIssuesFromCases()
  {
    Map<String, Map<String,List<Case>>> toCreateIssuesMap = new Map<String, Map<String, List<Case>>>();
    for( Case c : (List<Case>)this.newRecords )
    {
      if(  c.RecordTypeId == salesforceCaseRtId &&
           c.Jira_Project_Name__c != null &&
           jiraProjectMap.containsKey( c.Jira_Project_Name__c ) )
      {
        JiraProject jiraPro = jiraProjectMap.get( c.Jira_Project_Name__c );
        if( !toCreateIssuesMap.containsKey( jiraPro.jiraId ) )
        {
          toCreateIssuesMap.put( jiraPro.jiraId,
                                 new Map<String, List<Case>>() );
        }
        if( jiraPro.issueMap.containsKey( c.Reason ) )
        {
          if( !toCreateIssuesMap.get( jiraPro.jiraId ).containsKey( jiraPro.issueMap.get( c.Reason ) ) )
          {
            toCreateIssuesMap.get( jiraPro.jiraId ).put( jiraPro.issueMap.get( c.Reason ), new List<Case>() );
          }
          toCreateIssuesMap.get( jiraPro.jiraId )
            .get( jiraPro.issueMap.get( c.Reason ) )
            .add( c );
        }
      }
    }
    for( String projId : toCreateIssuesMap.keySet() )
    {
      for( String issueId : toCreateIssuesMap.get( projId ).keySet() )
      {
        System.debug('creating JIRA issue for project ' + projId + ' issue type ' + issueId );
        JCFS.API.createJiraIssue(
          projId,
          issueId,
          toCreateIssuesMap.get( projId ).get( issueId ),
          (List<Case>)oldRecords );
      }
    }
  }

  private void updateIssuesFromCases()
  {
    doUpdateFromCases( (List<Case>)this.newRecords, (List<Case>)this.oldRecords );
  }

  private void doUpdateFromCases( List<Case> newRecords, List<Case> oldRecords )
  {
    List<Case> toUpdate = new List<Case>();
    for( Case c : newRecords )
    {
      if( c.RecordTypeId == salesforceCaseRtId )
      {
        toUpdate.add( c );
      }
    }
    if( toUpdate.size() > 0 )
    {
      JCFS.API.pushUpdatesToJira( toUpdate, oldRecords );
    }
  }

  private void updatePushFilesToJira()
  {
    Set<Id> caseIds = new Set<Id>();
    for( ContentDocumentLink cdl : (List<ContentDocumentLink>)this.newRecords )
    {
      if( String.valueOf( cdl.LinkedEntityId.getSobjectType() ) == 'Case' )
      {
        caseIds.add( cdl.LinkedEntityId );
      }
    }
    if( caseIds.size() > 0 )
    {
      List<Case> cases = [SELECT Id, RecordTypeId FROm Case WHERE Id IN :caseIds];
      doUpdateFromCases( cases, null );
    }
  }
}