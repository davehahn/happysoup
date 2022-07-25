@isTest
private class gcTest_InventoryMovement {
  static testMethod void test1() {
    gcInventoryMovementCube_Report.coverage();
  }
  /*static testMethod void gcTest3()
	{
		gcInventoryMovementCube_Report.inventoryDetail(new map<String,list<String>>());

		map<string,list<string>> mapFilters = new map<string,list<string>>();

		for(AggregateResult aggRes :
			[SELECT GMBLASERP__Inventory_Balance__c idBalance,
					GMBLASERP__Warehouse__c idWarehouse,
					GMBLASERP__Location__c idLocation,
					GMBLASERP__Product__c idProduct,
					GMBLASERP__Lot__c idLot,
					GMBLASERP__Serial_Number__c idSerial
			 FROM GMBLASERP__Inventory_Movement_Cube__c
			 WHERE GMBLASERP__Lot__c != null AND GMBLASERP__Serial_Number__c != null
			 GROUP BY GMBLASERP__Inventory_Balance__c, GMBLASERP__Warehouse__c, GMBLASERP__Location__c, GMBLASERP__Product__c, GMBLASERP__Lot__c, GMBLASERP__Serial_Number__c
			 HAVING sum(GMBLASERP__Quantity__c) > 0
			 LIMIT 1])
		{
			mapFilters.put('idBalance',new list<string>{(string)aggRes.get('idBalance')});
			mapFilters.put('idProduct',new list<string>{(string)aggRes.get('idProduct')});
			mapFilters.put('idWarehouse',new list<string>{(string)aggRes.get('idWarehouse')});
			mapFilters.put('idLocation',new list<string>{(string)aggRes.get('idLocation')});
			mapFilters.put('idLot',new list<string>{(string)aggRes.get('idLot')});
			mapFilters.put('idSerial',new list<string>{(string)aggRes.get('idSerial')});
			mapFilters.put('dateFrom',new list<string>{'1/1/2012'});
			mapFilters.put('dateThru',new list<string>{'1/1/2099'});
		}
		gcInventoryMovementCube_Report.inventoryDetail(mapFilters);

		gcInventoryMovementCube_Report c = new gcInventoryMovementCube_Report();
		String myString = gcInventoryMovementCube_Report.locale;
	}*/
}
