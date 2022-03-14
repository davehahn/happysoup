/**
 * Created by dave on 2020-12-09.
 */

public with sharing class WorkOrderInventorySummary_Controller
{

  public class InventorySummaryLine {

    @AuraEnabled public String productRequiredId;
    @AuraEnabled public String productName;
    @AuraEnabled public Decimal requiredQuantity;
    @AuraEnabled public Decimal warehouseQuantity;
    @AuraEnabled public Decimal pickAndPackQuantity;
    @AuraEnabled public List<ResourceInventoryLine> resourceLines;

    public InventorySummaryLine()
    {
      this.resourceLines = new List<ResourceInventoryLine>();
    }
  }

  public class ResourceInventoryLine {

    @AuraEnabled public String name;
    @AuraEnabled public Decimal quantity;

    public ResourceInventoryLine(){}
  }

  @AuraEnabled
  public static List<InventorySummaryLine> getInventory( Id workOrderId )
  {
    WorkOrder_Service woService = new WorkOrder_Service( workOrderId );
    List<ProductRequired> requiredProducts = woService.getRequiredProducts();
    Schema.Location warehouseLocation = woService.getLocation();
    Schema.Location pickAndPackLocation = woService.getPickAndPackLocation();
    List<AssignedResource> resources = woService.getAssignedResources();

    Set<Id> locationIds = new Set<Id>{
      warehouseLocation.Id,
      pickAndPackLocation.Id
    };

    Map<Id, String> resourceLocationNameByLocationId = new Map<Id, String>();
    for( AssignedResource ar : resources )
    {
      resourceLocationNameByLocationId.put( ar.ServiceResource.LocationId, ar.ServiceResource.FSL__GanttLabel__c );
    }
    locationIds.addAll( resourceLocationNameByLocationId.keySet() );

    Map<Id, ProductRequired> requiredProductsByProductId = new Map<Id, ProductRequired>();
    for( ProductRequired pr : requiredProducts )
    {
      requiredProductsByProductId.put( pr.Product2Id, pr );
    }

    Map<Id, List<ProductItem>> productItemListByProductId = new Map<id, List<ProductItem>>();
    List<ProductItem> pItems = ProductItem_Selector.allByProductAndLocation(
      requiredProductsByProductId.keySet(),
      locationIds
    );
    for( ProductItem pi : pItems )
    {
      if( !productItemListByProductId.containsKey(pi.Product2Id ) )
        productItemListByProductId.put( pi.Product2Id, new List<ProductItem>() );
      productItemListByProductId.get( pi.Product2Id ).add( pi );
    }

    List<InventorySummaryLine> result = new List<InventorySummaryLine>();
    for( ProductRequired pr : requiredProductsByProductId.values() )
    {
      InventorySummaryLine line = new InventorySummaryLine();
      line.productRequiredId = pr.Id;
      line.productName = pr.Product2.Name;
      line.requiredQuantity = pr.QuantityRequired;
      if( !productItemListByProductId.containsKey( pr.Product2Id ) )
      {
        line.warehouseQuantity = 0;
        line.pickAndPackQuantity = 0;
        for (Id resourceLocationId : resourceLocationNameByLocationId.keySet())
        {
          ResourceInventoryLine ril = new ResourceInventoryLine();
          ril.name = resourceLocationNameByLocationId.get(resourceLocationId);
          ril.quantity = 0;
          line.resourceLines.add(ril);
        }
      }
      else
      {
        for( ProductItem pi : productItemListByProductId.get( pr.Product2Id ) )
        {
          if (warehouseLocation.Id == pi.LocationId)
            line.warehouseQuantity = pi.QuantityOnHand;
          if (pickAndPackLocation.Id == pi.LocationId)
            line.pickAndPackQuantity = pi.QuantityOnHand;
          for (Id resourceLocationId : resourceLocationNameByLocationId.keySet())
          {
            if (resourceLocationId == pi.LocationId)
            {
              ResourceInventoryLine ril = new ResourceInventoryLine();
              ril.name = resourceLocationNameByLocationId.get(resourceLocationId);
              ril.quantity = pi.QuantityOnHand;
              line.resourceLines.add(ril);
            }
          }
        }
      }
      line.warehouseQuantity = line.warehouseQuantity == null ? 0 : line.warehouseQuantity;
      line.pickAndPackQuantity = line.pickAndPackQuantity == null ? 0 : line.pickAndPackQuantity;
      result.add( line );
    }
    return result;
  }

}