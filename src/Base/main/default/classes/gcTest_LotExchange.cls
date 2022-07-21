@isTest
private class gcTest_LotExchange {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static testMethod void coverage_Test() {
    gcLotExchange.coverage();
    gcLotExchange_Ext.coverage();
  }

  @isTest
  static void trigger_Test() {
    Product2 boat = Factory_Product.createSerializedProduct('Boat', 'Pontoon');
    Integer year = Date.today().year();
    Map<String, GMBLASERP__Lot__c> lotMap = new Map<String, GMBLASERP__Lot__c>();
    lotMap.put(
      'from_lot',
      new GMBLASERP__Lot__c(
        GMBLASERP__Product__c = boat.Id,
        Name = String.valueOf(year - 1),
        GMBLASERP__Uniquefier__c = boat.Id + '-' + String.valueOf(year - 1)
      )
    );

    lotMap.put(
      'to_lot',
      new GMBLASERP__Lot__c(
        GMBLASERP__Product__c = boat.Id,
        Name = String.valueOf(year),
        GMBLASERP__Uniquefier__c = boat.Id + '-' + String.valueOf(year)
      )
    );
    insert lotMap.values();
    insert new Lot_Exchange__c(
      Exchange_Date__c = Date.today(),
      Exchange_Type__c = 'Lot',
      Lot_From__c = lotMap.get('from_lot').Id,
      Lot_To__c = lotMap.get('to_lot').Id
    );
  }
}
