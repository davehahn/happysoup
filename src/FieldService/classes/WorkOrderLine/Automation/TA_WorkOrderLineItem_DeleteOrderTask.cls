/**
 * Created by dave on 2021-06-04.
 */

public inherited sharing class TA_WorkOrderLineItem_DeleteOrderTask implements TriggerAction.BeforeDelete {
  public void beforeDelete(List<WorkOrderLineItem> oldList) {
    ProjectTask_ServiceFSL.deleteERPOrderTask(oldList);
  }
}
