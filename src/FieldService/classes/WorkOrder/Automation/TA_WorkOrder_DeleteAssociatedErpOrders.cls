/**
 * Created by dave on 2021-06-03.
 */

public inherited sharing class TA_WorkOrder_DeleteAssociatedErpOrders implements TriggerAction.BeforeDelete
{

  public void beforeDelete(
    List<WorkOrder> oldList
  )
  {
    Project_ServiceFSL.deleteERPOrder( oldList );
  }
}