/**
 * Created by dave on 2020-01-02.
 */

public without sharing class SystemIssue_TriggerHandler extends TriggerHandler {
  public class SystemIssue_Exception extends Exception {
  }

  public static Map<String, String> statusCategoriesMap = new Map<String, String>{
    'New' => 'To Do',
    'Accepted' => 'To Do',
    'Scheduled' => 'To Do',
    'In Progress' => 'In Progress',
    'Awaiting Deployment' => 'Done',
    'Deployed' => 'Done',
    'Done' => 'Done',
    'Denied' => 'Done'
  };

  public Id devQueueId {
    get {
      if (devQueueId == null) {
        try {
          devQueueId = [
            SELECT Id
            FROM Group
            WHERE Type = 'Queue' AND Name = 'Development'
            LIMIT 1
          ]
          .Id;
        } catch (Exception e) {
          throw new SystemIssue_Exception(
            'Development Queue not found.  Please contact your administrator with the error'
          );
        }
      }
      return devQueueId;
    }
    set;
  }

  private Application_RecordType.SystemIssueRTs recordTypes {
    get {
      if (recordTypes == null) {
        recordTypes = new Application_RecordType().getSystemIssueRecordTypes();
      }
      return recordTypes;
    }
    set;
  }
  //  protected override void bulkBefore()
  //  {
  //  }

  //  protected override void bulkAfter()
  //  {
  //  }

  protected override void beforeInsert() {
    for (System_Issue__c si : (List<System_Issue__c>) Trigger.new) {
      si.OwnerId = devQueueId;
      si.RecordTypeId = getRecordTypeIdByType(si.Type__c);
      si.Status_Category__c = setStatusCategory(si.Status__c);
    }
  }

  protected override void beforeUpdate() {
    for (System_Issue__c si : (List<System_Issue__c>) Trigger.new) {
      System_Issue__c oldIssue = (System_Issue__c) Trigger.oldMap.get(si.Id);
      if (si.Type__c != oldIssue.Type__c) {
        si.RecordTypeId = getRecordTypeIdByType(si.Type__c);
      }
      if (si.Status__c != oldIssue.Status__c) {
        si.Status_Category__c = setStatusCategory(si.Status__c);
      }
    }
  }

  //  protected override void beforeDelete()
  //  {
  //  }

  protected override void afterInsert() {
    new JiraConnect(Trigger.new, Trigger.oldMap).createIssues();
    setPercentageCompleteOnEpics((List<System_Issue__c>) Trigger.new);
  }

  protected override void afterUpdate() {
    new JiraConnect(Trigger.new, Trigger.oldMap).updateIssues();
    setPercentageCompleteOnEpics((List<System_Issue__c>) Trigger.new);
  }

  //  protected override void afterDelete()
  //  {
  //  }

  //  protected override void afterUndelete()
  //  {
  //  }

  //  protected override void finalActions()
  //  {
  //  }

  private Id getRecordTypeIdByType(String issueType) {
    return issueType == 'Epic'
      ? recordTypes.getEpicId()
      : recordTYpes.getStandardId();
  }

  private static String setStatusCategory(String status) {
    try {
      return statusCategoriesMap.get(status);
    } catch (Exception e) {
      return null;
    }
  }

  private static void setPercentageCompleteOnEpics(
    List<System_Issue__c> newList
  ) {
    Set<Id> parentEpics = new Set<Id>();
    for (System_Issue__c si : newList) {
      if (si.Parent_System_Issue__c != null) {
        parentEpics.add(si.Parent_System_Issue__c);
      }
    }
    if (parentEpics.size() > 0) {
      doPercentCalc(parentEpics);
    }
  }

  private static void doPercentCalc(Set<Id> parentEpicIds) {
    Map<Id, List<System_Issue__c>> issuesByParentRecordId = groupChildIssuesByParent(
      parentEpicIds
    );
    List<System_Issue__c> parentIssues = new List<System_Issue__c>();
    for (Id parentId : issuesByParentRecordId.keySet()) {
      Decimal doneCount = 0;
      Decimal inProgressCount = 0;
      Decimal toDoCount = 0;
      for (System_Issue__c si : issuesByParentRecordId.get(parentId)) {
        switch on si.Status_Category__c {
          when 'To Do' {
            toDoCount++;
          }
          when 'In Progress' {
            inProgressCount++;
          }
          when 'Done' {
            doneCount++;
          }
        }
      }
      System_Issue__c si = new System_Issue__c(
        Id = parentId,
        Story_Count_Done__c = doneCount ,
        Story_Count_To_Do__c = toDoCount ,
        Story_Count_In_Progress__c = inProgressCount ,
        Story_Count__c = issuesByParentRecordId.get(parentId).size()
      );
      parentIssues.add(
        si
      );
    }
    update parentIssues;
  }

  private static Map<Id, List<System_Issue__c>> groupChildIssuesByParent(
    Set<Id> parentEpicIds
  ) {
    Map<Id, List<System_Issue__c>> result = new Map<Id, List<System_Issue__c>>();
    for (
      System_Issue__c si : SystemIssue_Selector.allChildrenByParentId(
        parentEpicIds
      )
    ) {
      if (!result.containsKey(si.Parent_System_Issue__c)) {
        result.put(si.Parent_System_Issue__c, new List<System_Issue__c>());
      }
      result.get(si.Parent_System_Issue__c).add(si);
    }
    return result;
  }
}
