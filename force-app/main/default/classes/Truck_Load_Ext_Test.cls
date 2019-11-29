@isTest
private class Truck_Load_Ext_Test {

  @isTest static void tempTest()
  {
    Truck_Load_Ext.coverage();
    Truck_Load__c tl = new Truck_Load__c(
      Return_Date2__c = Date.today().addDays(10),
      Delivery_Date2__c = Date.today().addDays(5),
      Departure_Date2__c = Date.today(),
      Driver__c = LGND_Utilities.getPickListValues('Truck_Load__c', 'Driver__c')[0],
      Truck__c = LGND_Utilities.getPickListValues('Truck_Load__c', 'Truck__c')[0]
    );
    insert tl;
    TruckLoadLine__c tll = new TruckLoadLine__c(
      Truck_Load__c = tl.Id
    );
    insert tll;
    update [SELECT Id FROM TruckLoadLine__c LIMIT 1][0];
  }

}