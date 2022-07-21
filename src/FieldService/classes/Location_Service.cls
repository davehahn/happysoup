/**
 * Created by dave on 2020-11-20.
 */

public with sharing class Location_Service {
  public static Schema.Location getWorkOrderPickAndPackLocation(Id workOrderId, Id locationId) {
    List<Schema.Location> ppLoc = Location_Selector.getWorkOrderPickAndPack(workOrderId, locationId);

    if (ppLoc.size() > 0)
      return ppLoc[0];

    WorkOrder wo = WorkOrder_Selector.getById(workOrderId);

    Schema.Location l = new Schema.Location(
      Name = 'PickAndPack-' + wo.WorkOrderNumber,
      ParentLocationId = locationId,
      Work_Order__c = workOrderId,
      IsInventoryLocation = true,
      LocationType = 'Work Order Holding'
    );
    insert l;
    return l;
  }
}
