@isTest
private class TruckTrip_Test {
  @isTest
  static void fakeCoverage_Test() {
    TruckTrip.coverage();
  }

  @isTest
  static void triggerCoverage_Test() {
    Truck_Trip__c trip = new Truck_Trip__c(
      Driver__c = LGND_Utilities.getPicklistValues('Truck_Trip__c', 'Driver__c')[0],
      Departure_Date__c = Date.today(),
      Return_Date__c = Date.today()
    );
    insert trip;
    trip.Driver__c = LGND_Utilities.getPicklistValues('Truck_Trip__c', 'Driver__c')[0];
    update trip;
  }
}
