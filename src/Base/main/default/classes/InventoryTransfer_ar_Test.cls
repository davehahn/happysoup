@isTest
private class InventoryTransfer_ar_Test {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static testMethod void coverage_Test() {
    InventoryTransfer_ar.coverage();
  }

  static testMethod void trigger_Test() {
    AcctSeedERP__Warehouse__c[] whs = [SELECT Id FROM AcctSeedERP__Warehouse__c];
    GMBLASERP.gcInventoryTransfer.disableTrigger = true;
    insert new GMBLASERP__Inventory_Transfer__c(
      GMBLASERP__Warehouse_From__c = whs[0].Id,
      GMBLASERP__Warehouse_To__c = whs[1].Id,
      Comments__c = 'Test Comment'
    );
  }
}
