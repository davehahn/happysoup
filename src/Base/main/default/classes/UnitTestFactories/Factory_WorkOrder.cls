/**
 * Created by dave on 2019-08-06.
 */
@IsTest
public with sharing class Factory_WorkOrder {

  public static WorkOrder buildNew( Id acctId, Id pbId )
  {
    return new WorkOrder(
      AccountId = acctId,
      Pricebook2Id = pbId,
      Status = 'New',
      Subject = 'Test Factory Created'
    );
  }

  public static List<WorkOrder> buildNew( Id acctId, Id pbId, Integer count )
  {
    List<WorkOrder> result = new List<WorkOrder>();
    for( Integer i=0; i<count; i++ )
    {
      result.add( buildNew( acctId, pbId ) );
    }
    return result;
  }

  public static WorkOrder createNew( Id acctId, Id pbId )
  {
    WorkOrder wo = buildNew( acctId, pbId );
    insert wo;
    return wo;
  }

  public static List<WorkOrderLineItem> createLineItems( Id workOrderId, Integer count )
  {
    List<WorkOrderLineItem> result = new List<WorkOrderLineItem>();
    for( Integer i=0; i < count; i++ )
    {
      result.add( new WorkOrderLineItem(
        WorkOrderId = workOrderId,
        Description = 'Test Line ' + String.valueOf( i )
      ));
    }
    insert result;
    return result;
  }
}