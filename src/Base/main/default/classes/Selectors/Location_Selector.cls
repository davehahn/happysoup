/**
 * Created by dave on 2020-11-06.
 */

public virtual class Location_Selector extends Application_Selector {
  private final List<String> defaultFields = new List<String>{
    'Id',
    'Name',
    'LocationType',
    'ParentLocationId',
    'ParentLocation.Name',
    'ParentLocation.LocationType',
    'RootLocationId',
    'RootLocation.Name',
    'Warehouse__c',
    'Warehouse__r.Name',
    'IsInventoryLocation',
    'Work_Order__c'
  };

  public Location_Selector() {
    this.sObjectName = 'Location';
    this.fields = defaultFields;
  }

  public static Schema.Location getById(Id locationId) {
    Location_Selector selector = new Location_Selector();
    selector.addWhereIdIn(new Set<Id>{ locationId });
    return (Schema.Location) selector.query()[0];
  }

  public static Schema.Location getSiteLocationByWarehouseName(String warehouseName) {
    Location_Selector selector = new Location_Selector();
    if (warehouseName == null) {
      selector.throwError(
        'Current User does not have a Warehouse set on User record, Please contact your Administrator to get this rectified'
      );
      return null;
    }
    selector.addWhere('Name LIKE \'%' + warehouseName + '%\'').addWhere('LocationType = \'Site\'', 'AND');
    List<Schema.Location> locations = selector.query();
    if (locations.size() == 0) {
      selector.throwError('No Site found for ' + warehouseName + '! Contact you administrator with this error');
      return null;
    }
    return locations[0];
  }

  public static List<Schema.Location> allChildLocations(Id parentLocationId) {
    Location_Selector selector = new Location_Selector();
    selector.addWhere('ParentLocationId = \'' + parentLocationId + '\'').addWhere('IsInventoryLocation = true', 'AND');
    return selector.query();
  }

  public static List<Schema.Location> getSitePickAndPack(Id siteLocationId) {
    Location_Selector selector = new Location_Selector();
    selector.addWhere('ParentLocationId = \'' + siteLocationId + '\'').addWhere('LocationType = \'Pick and Pack\'');
    return selector.query();
  }

  public static List<Schema.Location> getWorkOrderPickandPack(Id workOrderId, Id locationId) {
    Location_Selector selector = new Location_Selector();
    selector.addWhere('ParentLocationId = \'' + locationId + '\'')
      .addWhere('Work_Order__c = \'' + workOrderId + '\'', 'AND');
    return selector.query();
  }
}
