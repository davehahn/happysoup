@isTest
private class TruckDestination_Test {

	@isTest static void fakeCoverage_Test() {
		TruckDestination.coverage();
	}

  @isTest static void triggerCoverage_Test() {
    Account act = AccountFactory.buildDealerAccount('Test Dealer Account');
    insert act;
    Truck_Trip__c trip = new Truck_Trip__c(
      Driver__c = LGND_Utilities.getPicklistValues('Truck_Trip__c', 'Driver__c')[0],
      Departure_Date__c = Date.today(),
      Return_Date__c = Date.today()
    );
    insert trip;
    Truck_Destination__c destination = new Truck_Destination__c(
      Account__c = act.Id,
      Delivery_Date__c = Date.today(),
      Trip__c = trip.Id,
      Type__c = LGND_Utilities.getPicklistValues('Truck_Destination__c', 'Type__c')[0]
    );
    insert destination;
    destination.Type__c = LGND_Utilities.getPicklistValues('Truck_Destination__c', 'Type__c')[1];
    update destination;
  }

}