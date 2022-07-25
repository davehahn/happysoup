/**
 * Created by dave on 2022-03-28.
 */

public without sharing class TA_Task_SetRelatedActivityFields implements TriggerAction.AfterInsert {
  private final Set<String> TASK_SUBTYPES = new Set<String>{ 'Email', 'Call' };
  private final Set<String> SOBJECT_TYPES_WITH_ACTIVITY_FIELDS = new Set<String>{ 'Case' };

  public void afterInsert(List<Task> newList) {
    List<Sobject> result = sortApplicableBySobjectType(newLIst);
    if (result.size() > 0) {
      update result;
    }
  }

  private List<SObject> sortApplicableBySobjectType(List<task> newList) {
    List<SObject> result = new List<SObject>();
    for (Task t : newList) {
      if (t.WhatId == null)
        continue;
      if (!TASK_SUBTYPES.contains(t.TaskSubtype))
        continue;
      String sObjectName = LGND_Utilities.sObjectNameFromId(t.WhatId);
      if (!SOBJECT_TYPES_WITH_ACTIVITY_FIELDS.contains(sObjectName))
        continue;
      SObject sobj = Schema.getGlobalDescribe().get(sObjectName).newSObject();
      sobj.put('Id', t.WhatId);
      sobj.put('Last_Activity_Date__c', t.CreatedDate);
      result.add(sobj);
    }
    return result;
  }
}
