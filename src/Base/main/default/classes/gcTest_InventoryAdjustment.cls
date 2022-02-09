@isTest
private class gcTest_InventoryAdjustment{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static testMethod void coverage_Test()
  {
    //gcInventoryAdjustment.coverage();
  }

  @IsTest
  static void testAdjustment(){
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    Id idWarehouse = gcConstants.idWarehouseMontreal;
    Id idGL = gcConstants.idGlClearingARAP;
    GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c(
            Description__c = 'Test run',
            GMBLASERP__Adjustment_Type__c = 'Quantity',
            GMBLASERP__Adjustment_Date__c = Date.today(),
            GMBLASERP__Product__c = part.Id,
            GMBLASERP__Warehouse__c = idWarehouse,
            GMBLASERP__GL_Account__c = idGL
    );
    insert adj;
    AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =:idWarehouse LIMIT 1];
    Id idBalance = GCR_InventoryBalance.findOrCreateBalance(part.Id,idWarehouse,loc.Id);
    AcctSeedERP__Inbound_Inventory_Movement__c moveIn = new AcctSeedERP__Inbound_Inventory_Movement__c(
            GMBLASERP__Inventory_Adjustment__c = adj.Id,
            AcctSeedERP__Credit_GL_Account__c = idGL,
            AcctSeedERP__Inventory_Balance__c = idBalance,
            AcctSeedERP__Movement_Date__c = adj.GMBLASERP__Adjustment_Date__c,
            AcctSeedERP__Quantity__c = 1,
            AcctSeedERP__Type__c = 'Accounting',
            AcctSeedERP__Unit_Cost__c = 0,
            GMBLASERP__Cost_Override__c = false,
            AcctSeedERP__Ledger__c = gcConstants.idActualLedger
    );
    Test.startTest();
    insert moveIn;
    /// There should be a Movement Cube
    Decimal qty = 0;
    for(GMBLASERP__Inventory_Movement_Cube__c imc : [SELECT Id, GMBLASERP__Quantity__c FROM GMBLASERP__Inventory_Movement_Cube__c WHERE GMBLASERP__Product__c = :part.Id AND GMBLASERP__Inventory_Balance__c = :idBalance]){
      qty = imc.GMBLASERP__Quantity__c;
    }
    System.assertEquals(qty,1);
  }

  @IsTest
  static void testValueAdjustment(){
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    Id idWarehouse = gcConstants.idWarehouseMontreal;
    Id idGL = gcConstants.idGlClearingARAP;
    GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c(
            Description__c = 'Test run',
            GMBLASERP__Adjustment_Type__c = 'Value',
            GMBLASERP__Adjustment_Date__c = Date.today(),
            GMBLASERP__Product__c = part.Id,
            GMBLASERP__GL_Account__c = idGL
    );
    insert adj;
    AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =:idWarehouse LIMIT 1];
    Id idBalance = GCR_InventoryBalance.findOrCreateBalance(part.Id,idWarehouse,loc.Id);
    AcctSeedERP__Inbound_Inventory_Movement__c moveIn = new AcctSeedERP__Inbound_Inventory_Movement__c(
            GMBLASERP__Inventory_Adjustment__c = adj.Id,
            AcctSeedERP__Credit_GL_Account__c = idGL,
            AcctSeedERP__Inventory_Balance__c = idBalance,
            AcctSeedERP__Movement_Date__c = adj.GMBLASERP__Adjustment_Date__c,
            AcctSeedERP__Quantity__c = 0,
            AcctSeedERP__Type__c = 'Accounting',
            AcctSeedERP__Unit_Cost__c = 0,
            GMBLASERP__Cost_Override__c = true,
            AcctSeedERP__Ledger__c = gcConstants.idActualLedger
    );
    insert moveIn;
    AcctSeedERP__Outbound_Inventory_Movement__c moveOut = new AcctSeedERP__Outbound_Inventory_Movement__c(
            AcctSeedERP__Debit_GL_Account__c = adj.GMBLASERP__GL_Account__c,
            AcctSeedERP__Inventory_Balance__c = idBalance,
            AcctSeedERP__Movement_Date__c = adj.GMBLASERP__Adjustment_Date__c,
            AcctSeedERP__Quantity__c = 0,
            AcctSeedERP__Type__c = 'Accounting',
            AcctSeedERP__Unit_Cost__c = 0,
            GMBLASERP__Cost_Override__c = true,
            AcctSeedERP__Inbound_Inventory_Movement__c = moveIn.Id,
            AcctSeedERP__Ledger__c = gcConstants.idActualLedger
    );
    insert moveOut;
    Test.startTest();
    moveIn.AcctSeedERP__Quantity__c = 1;
    moveIn.AcctSeedERP__Unit_Cost__c = 100;
    update moveIn;
    Test.stopTest();
  }

  @IsTest
  static void testDeleteAdjustment(){
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    Id idWarehouse = gcConstants.idWarehouseMontreal;
    Id idGL = gcConstants.idGlClearingARAP;
    GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c(
            Description__c = 'Test run',
            GMBLASERP__Adjustment_Type__c = 'Value',
            GMBLASERP__Adjustment_Date__c = Date.today(),
            GMBLASERP__Product__c = part.Id,
            GMBLASERP__GL_Account__c = idGL
    );
    insert adj;
    AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =:idWarehouse LIMIT 1];
    Id idBalance = GCR_InventoryBalance.findOrCreateBalance(part.Id,idWarehouse,loc.Id);
    AcctSeedERP__Inbound_Inventory_Movement__c moveIn = new AcctSeedERP__Inbound_Inventory_Movement__c(
            GMBLASERP__Inventory_Adjustment__c = adj.Id,
            AcctSeedERP__Credit_GL_Account__c = idGL,
            AcctSeedERP__Inventory_Balance__c = idBalance,
            AcctSeedERP__Movement_Date__c = adj.GMBLASERP__Adjustment_Date__c,
            AcctSeedERP__Quantity__c = 0,
            AcctSeedERP__Type__c = 'Accounting',
            AcctSeedERP__Unit_Cost__c = 0,
            GMBLASERP__Cost_Override__c = true,
            AcctSeedERP__Ledger__c = gcConstants.idActualLedger
    );
    insert moveIn;
    AcctSeedERP__Outbound_Inventory_Movement__c moveOut = new AcctSeedERP__Outbound_Inventory_Movement__c(
            AcctSeedERP__Debit_GL_Account__c = adj.GMBLASERP__GL_Account__c,
            AcctSeedERP__Inventory_Balance__c = idBalance,
            AcctSeedERP__Movement_Date__c = adj.GMBLASERP__Adjustment_Date__c,
            AcctSeedERP__Quantity__c = 0,
            AcctSeedERP__Type__c = 'Accounting',
            AcctSeedERP__Unit_Cost__c = 0,
            GMBLASERP__Cost_Override__c = true,
            AcctSeedERP__Inbound_Inventory_Movement__c = moveIn.Id,
            AcctSeedERP__Ledger__c = gcConstants.idActualLedger
    );
    insert moveOut;
    moveIn.AcctSeedERP__Quantity__c = 1;
    moveIn.AcctSeedERP__Unit_Cost__c = 100;
    update moveIn;
    Test.startTest();
    delete moveIn;
    Test.stopTest();
    Decimal qty = 0;
    for(GMBLASERP__Inventory_Movement_Cube__c imc : [SELECT Id, GMBLASERP__Quantity__c FROM GMBLASERP__Inventory_Movement_Cube__c WHERE GMBLASERP__Product__c = :part.Id AND GMBLASERP__Inventory_Balance__c = :idBalance]){
      qty = imc.GMBLASERP__Quantity__c;
    }
    System.assertEquals(qty,0);
  }

}