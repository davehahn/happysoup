/**
 * Created by dave on 2020-11-18.
 */

public with sharing class ProductRequests
{

  public static ProductRequest createNewPickupForWorkOrder(
    Id workOrderId,
    Id sourceLocationId,
    Id destinationLocationId
  )
  {
    ProductRequest pr = new ProductRequest(
      DestinationLocationId = destinationLocationId,
      SourceLocationId = sourceLocationId,
      WorkOrderId = workOrderId,
      ShipmentType = 'Pick up',
      Status = 'Submitted'
    );
    insert pr;
    return pr;
  }

}