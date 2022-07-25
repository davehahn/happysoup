/**
 * Created by dave on 2020-11-11.
 */
@isTest
public class Factory_Location {
  public static Schema.Location buildSite(String siteName) {
    return new Schema.Location(
      LocationType = 'Site',
      Name = siteName + ' Site',
      Description = 'The Site container for ' + siteName
    );
  }

  public static Schema.Location buildWarehouse(AcctSeedERP__Warehouse__c acctSeedWH, Schema.Location site) {
    return new Schema.Location(
      LocationType = 'Warehouse',
      IsInventoryLocation = true,
      Name = acctSeedWH.Name + ' Warehouse',
      Description = acctSeedWH.Name + ' Warehouse',
      Warehouse__c = acctSeedWH.Id,
      ParentLocationId = site.Id
    );
  }

  public static Schema.Location buildPickAndPack(String name, Schema.Location site) {
    return new Schema.Location(
      LocationType = 'Pick and Pack',
      IsInventoryLocation = true,
      Name = name,
      Description = name,
      ParentLocationId = site.Id
    );
  }

  public static Schema.Location buildEmployee(String name, Schema.Location site) {
    return new Schema.Location(
      LocationType = 'Employee',
      IsInventoryLocation = true,
      IsMobile = true,
      Name = name,
      Description = name,
      ParentLocationId = site.Id
    );
  }

  public static List<Schema.Location> buildEmployees(String name, Schema.Location site, Integer count) {
    List<Schema.Location> result = new List<Schema.Location>();
    for (Integer i = 0; i < count; i++) {
      result.add(buildEmployee(name + ' Employee' + String.valueOf(i), site));
    }
    return result;
  }
}
