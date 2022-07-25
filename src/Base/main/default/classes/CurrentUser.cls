/**
 * Created by dave on 2020-11-06.
 */

public virtual class CurrentUser {
  private static User record {
    get {
      if (record == null) {
        System.debug('QUERYING FOR USER');
        record = User_Selector.getCurrentUser();
      }
      return record;
    }
    private set;
  }

  private static Schema.Location baseLocation {
    get {
      if (baseLocation == null) {
        System.debug('QUERYING FOR LOCATION');
        baseLocation = Location_Selector.getSiteLocationByWarehouseName(record.Warehouse__c);
      }
      return baseLocation;
    }
    private set;
  }

  private static List<Schema.Location> fslInventoryLocations {
    get {
      if (fslInventoryLocations == null) {
        fslInventoryLocations = Location_Selector.allChildLocations(baseLocation.Id);
      }
      return fslInventoryLocations;
    }
    private set;
  }

  public static String getWarehouseName() {
    return record.Warehouse__c;
  }

  public static String getFullName() {
    return record.FirstName + ' ' + record.LastName;
  }

  public static Schema.Location getBaseLocation() {
    return baseLocation;
  }

  public static Id getBaseLocationId() {
    return baseLocation.Id;
  }

  public static List<Schema.Location> getFslInventoryLocations() {
    return fslInventoryLocations;
  }
}
