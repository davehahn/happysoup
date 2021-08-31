@isTest
private class gcTest_OutboundInventoryMovement {

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

	static testMethod void coverage_Test()
	{
    gcOutboundInventoryMovement.coverage();
  }

  static testMethod void trigger_Test()
  {
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
    Id idWarehouse = gcConstants.idWarehouseMontreal;
    AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =:idWarehouse LIMIT 1];
    Id idBalance = GCR_InventoryBalance.findOrCreateBalance(part.Id,idWarehouse,loc.Id);
    AcctSeedERP__Outbound_Inventory_Movement__c movement = new AcctSeedERP__Outbound_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      AcctSeedERP__Type__c = 'Accounting',
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Debit_GL_Account__c = gcConstants.idGlClearingARAP,
      AcctSeedERP__Inventory_Balance__c = idBalance,
      AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
      GMBLASERP__Warehouse__c = idWarehouse
    );
    insert movement;
  }
}