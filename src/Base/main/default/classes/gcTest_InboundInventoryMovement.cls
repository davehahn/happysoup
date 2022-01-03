@isTest
private class gcTest_InboundInventoryMovement{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

	static testMethod void coverage_Test()
	{
    gcInboundInventoryMovement.coverage();
  }

  @isTest
  static void trigger_Test()
  {
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    Id idWarehouse = gcConstants.idWarehouseMontreal;
    AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =:idWarehouse LIMIT 1];
    Id idBalance = GCR_InventoryBalance.findOrCreateBalance(part.Id,idWarehouse,loc.Id);
    AcctSeedERP__Inbound_Inventory_Movement__c movement = new AcctSeedERP__Inbound_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      AcctSeedERP__Type__c = 'Accounting',
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Credit_GL_Account__c = gcConstants.idGlClearingARAP,
      AcctSeedERP__Inventory_Balance__c = idBalance,
      AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
      GMBLASERP__Warehouse__c = idWarehouse
    );
    insert movement;
  }


}