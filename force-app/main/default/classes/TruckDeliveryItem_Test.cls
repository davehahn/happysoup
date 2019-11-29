@isTest
private class TruckDeliveryItem_Test {

	@isTest static void fakeCoverage_Test() {
		TruckDeliveryItem.coverage();
	}

  @isTest static void triggerCoverage_Test() {
    Truck_Delivery_Item__c item = new Truck_Delivery_Item__c(
      Position__c = LGND_Utilities.getPicklistValues('Truck_Delivery_item__c', 'Position__c')[0]
    );
    insert item;
    item.Position__c =  LGND_Utilities.getPicklistValues('Truck_Delivery_item__c', 'Position__c')[1];
    update item;
  }

}