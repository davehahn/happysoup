/**
 * Created by dave on 2019-08-11.
 */

public virtual class WorkOrderLineItem_Selector extends Application_Selector {

  private final List<String> defaultFields = new List<String>{
    'Id',
    'LineItemNumber',
    'Description',
    'Visible_to_Customer__c',
    'Is_From_Opportunity__c',
    'WorkTypeId',
    'WorkType.Name',
    'WorkOrderId',
    'WorkOrder.Opportunity__c',
    'WorkOrder.ERP_Order__c',
    'WorkOrder.WorkTypeId',
    'WorkOrder.RecordTypeId',
    'ERP_Order_Task__c'
  };

  public WorkOrderLineItem_Selector()
  {
    this.sObjectName = 'WorkOrderLineItem';
    this.fields = defaultFields;
  }

  public static WorkOrderLineItem selectById( Id theId )
  {
    WorkOrderLineItem_Selector selector = new WorkOrderLineItem_Selector();
    selector.addWhereIdIn( new Set<Id>{theId});
    return (WorkOrderLineItem)selector.query()[0];
  }

  public static Map<Id, WorkOrderLineItem> selectAllByWorkOrderId_AsMap( Id WorkOrderId )
  {
    WorkOrderLineItem_Selector selector = new WorkOrderLineItem_Selector();
    selector.addWhereIdInField( new Set<Id>{workOrderId}, 'WorkOrderId' );
    return new Map<Id, WorkOrderLineItem>( (List<WorkOrderLineItem>)selector.query() );
  }

  public static List<WorkOrderLineItem> selectAllWithoutERPTask_ByWorkOrderIds( Set<Id> WorkOrderIds )
  {
    WorkOrderLineItem_Selector selector = new WorkOrderLineItem_Selector();
    System.debug('Select WO ');
    selector.addWhereIdInField( WorkOrderIds, 'WorkOrderId' );
    selector.addWhere( 'ERP_Order_Task__c = null', 'AND');
    return (List<WorkOrderLineItem>)selector.query();
  }

  public static List<WorkOrderLineItem> selectAllById_includingWorkOrderWithERP( Set<Id> ids )
  {
    if( ids == null || ids.size() == 0 ) return new List<WorkOrderLineItem>();
    WorkOrderLineItem_Selector selector = new WorkOrderLineItem_Selector();
    selector.addWhereIdIn( ids );
    return selector.query();
  }

  public static List<WorkOrderLineItem> selectAllWithTaskById_includingWorkOrderWithERP( Set<Id> ids )
  {
    if( ids == null || ids.size() == 0 ) return new List<WorkOrderLineItem>();
    WorkOrderLineItem_Selector selector = new WorkOrderLineItem_Selector();
    selector.addWhereIdIn( ids )
    .addWhere( 'WorkOrder.ERP_Order__c <> null', 'AND')
    .addWhere( 'ERP_Order_Task__c <> null', 'AND');
    return selector.query();
  }

  public static List<WorkOrderLineItem> selectAllWithoutTaskById_includingWorkOrderWithERP( Set<Id> ids )
  {
    if( ids == null || ids.size() == 0 ) return new List<WorkOrderLineItem>();
    WorkOrderLineItem_Selector selector = new WorkOrderLineItem_Selector();
    selector.addWhereIdIn( ids )
      .addWhere( 'WorkOrder.ERP_Order__c <> null', 'AND')
      .addWhere( 'ERP_Order_Task__c = null', 'AND');
    return selector.query();
  }

//  public static List<WorkOrderLineItem> selectAllByWorkOrderId_includingProductsRequired( Id workOrderId )
//  {
//    WorkOrderLineItem_Selector selector = new WorkOrderLineItem_Selector();
//    selector.addChildQuery( new ProductRequired_Selector() )
//      .addWhere( 'WorkOrderId = \'' + workOrderId + '\'');
//    return selector.query();
//  }
//
//  public static List<WorkOrderLineItem> selectAllByWorkOrderId_includingProductsRequiredRequiringPickAndPack( Id workOrderId )
//  {
//    WorkOrderLineItem_Selector selector = new WorkOrderLineItem_Selector();
//    ProductRequired_Selector prSelector = new ProductRequired_Selector();
//    prSelector.addWhere('IsPickAndPackComplete__c <> true');
//    selector.addChildQuery( prSelector )
//      .addWhere( 'WorkOrderId = \'' + workOrderId + '\'');
//    return selector.query();
//  }

}