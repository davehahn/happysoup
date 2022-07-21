/**
 * Created by dave on 2021-07-27.
 */

public inherited sharing class TA_POL_DeleteWorkOrder implements TriggerAction.AfterDelete {
  public void afterDelete(List<AcctSeedERP__Purchase_Order_Line__c> oldList) {
    List<WorkOrder> toDelete = new List<WorkOrder>();
    for (AcctSeedERP__Purchase_Order_Line__c pol : oldList) {
      if (pol.Work_Order__c != null) {
        toDelete.add(new WorkOrder(Id = pol.Work_Order__c));
      }
    }
    delete toDelete;
  }
}
