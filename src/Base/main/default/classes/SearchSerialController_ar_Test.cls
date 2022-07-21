@isTest
private class SearchSerialController_ar_Test {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static testMethod void class_Test() {
    AcctSeedERP__Warehouse__c wh = [SELECT Id, Name FROM AcctSeedERP__Warehouse__c LIMIT 1];
    AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(Name = 'Test Loc', AcctSeedERP__Warehouse__c = wh.Id);
    insert loc;
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
      AcctSeedERP__Location__c = loc.Id,
      AcctSeedERP__Warehouse__c = wh.Id,
      AcctSeedERP__Product__c = part.Id
    );
    insert balance;

    GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', '0987654321');
    SearchSerialController_ar.searchSerials('0987654321');
  }
}
