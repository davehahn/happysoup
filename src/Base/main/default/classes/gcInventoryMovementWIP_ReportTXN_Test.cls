@isTest(SeeAllData=true)
private class gcInventoryMovementWIP_ReportTXN_Test {
  static testMethod void test1() {
    gcInventoryMovementWIP_ReportTXN.coverage();
  }

  //   static testMethod void test2()
  //	  {
  //   	map<String,list<String>> mapFilters = new map<String,list<String>>();
  //   	List<String> listIdProducts = new List<String>();
  //   	for(Product2 p : [SELECT Id FROM Product2 WHERE RecordType.Name = 'Boat' AND AcctSeed__Inventory_Product__c = true limit 10])
  //   		listIdProducts.add(p.Id);
  //   	mapFilters.put('idProduct',listIdProducts);
  //   	gcInventoryMovementWIP_ReportTXN.inventoryDetail(mapFilters);
  //   }
}
