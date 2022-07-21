/**
 * Created by dave on 2019-08-08.
 */

public virtual class WorkOrder_Selector extends Application_Selector {
  private final List<String> defaultFields = new List<String>{
    'Id',
    'AccountId',
    'Account.Name',
    'Opportunity__c',
    'Pricebook2Id',
    'Subject',
    'RecordTypeId',
    'Status',
    'WorkOrderNumber',
    'LocationId',
    'WorkTypeId',
    'Location.Id',
    'Location.Name',
    'Location.LocationType',
    'Location.ParentLocationId',
    'Location.ParentLocation.Name',
    'Location.RootLocation.Name',
    'Location.RootLocationId',
    'Location.Warehouse__c',
    'Serial_Number__c',
    'ERP_Warehouse_ID__c',
    'Serial_Name__c',
    'ERP_Warehouse_Name__c',
    'Manufacturing_Product_Id__c',
    'ERP_Order__c',
    'Warehouse_Name__c'
  };

  public WorkOrder_Selector() {
    this.sObjectName = 'WorkOrder';
    this.fields = defaultFields;
  }

  public static WorkOrder getById(Id workOrderId) {
    WorkOrder_Selector selector = new WorkOrder_Selector();
    selector.addWhereIdIn(new Set<Id>{ workOrderId });
    return (WorkOrder) selector.query()[0];
  }

  public static WorkOrder getEverythingById(Id workOrderId) {
    WorkOrder_Selector selector = new WorkOrder_Selector();
    WorkOrderLineItem_Selector woli_selector = new WorkOrderLineItem_Selector();
    ServiceAppointment_Selector sa_selector = new ServiceAppointment_Selector();
    selector.addChildQuery(woli_selector);
    selector.addChildQuery(sa_selector);
    selector.addWhereIdIn(new Set<Id>{ workOrderId });
    return (WorkOrder) selector.query()[0];
  }

  public static List<WorkOrder> selectAllWithOutERPOrders_ByIds(Set<Id> workOrderIds) {
    System.debug('No ERP WorkOrder_Selector.workOrderIds = ' + workOrderIds);
    WorkOrder_Selector selector = new WorkOrder_Selector();
    selector.addWhereIdIn(workOrderIds).addWhere('ERP_Order__c = null');
    return selector.query();
  }
}
