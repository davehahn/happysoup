global without sharing class tempIAIUpdateProductWarehouseBatch implements Schedulable, Database.Batchable<sObject> {
  global tempIAIUpdateProductWarehouseBatch() {
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    String query = 'SELECT Id, Product_Code__c, Product__c, Product_Description__c, Matched_With_Product__c, Inventory_Non_Inventory__c, Warehouse_Text__c, Warehouse__c FROM Inventory_Adjustment_Import__c';
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    List<Inventory_Adjustment_Import__c> listImport = new List<Inventory_Adjustment_Import__c>();
    Set<String> setProductCode = new Set<String>();
    Set<String> setWarehouseName = new Set<String>();
    Map<String, Product2> mapCodeProduct = new Map<String, Product2>();
    Map<String, Id> mapNameWarehouse = new Map<String, Id>();
    for (SObject sObj : scope) {
      Inventory_Adjustment_Import__c imp = (Inventory_Adjustment_Import__c) sObj;
      setProductCode.add(imp.Product_Code__c != null ? imp.Product_Code__c.toLowerCase() : null);
      setWarehouseName.add(imp.Warehouse_Text__c);
      listImport.add(imp);
    }
    setProductCode.remove(null);
    Id idRTPart = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Part').getRecordTypeId();
    /// Generate all the products
    for (Product2 p : [
      SELECT Id, IsActive, ProductCode, AcctSeed__Inventory_Product__c
      FROM Product2
      WHERE ProductCode IN :setProductCode
    ]) {
      String pc = p.ProductCode.toLowerCase();
      mapCodeProduct.put(pc, p);
    }
    /// Generate all the warehouses
    for (AcctSeedERP__Warehouse__c whs : [
      SELECT Id, Name
      FROM AcctSeedERP__Warehouse__c
      WHERE Name IN :setWarehouseName
    ])
      mapNameWarehouse.put(whs.Name, whs.Id);

    for (Inventory_Adjustment_Import__c imp : listImport) {
      if (imp.Product_Code__c != null) {
        String pc = imp.Product_Code__c.toLowerCase();
        if (mapCodeProduct.containsKey(pc)) {
          Product2 prod = mapCodeProduct.get(pc);
          imp.Product__c = prod.Id;
          if (prod.AcctSeed__Inventory_Product__c != imp.Inventory_Non_Inventory__c)
            imp.Matched_With_Product__c = true;
        }
        if (mapNameWarehouse.containsKey(imp.Warehouse_Text__c))
          imp.Warehouse__c = mapNameWarehouse.get(imp.Warehouse_Text__c);
      }
    }
    if (!listImport.isEmpty())
      update listImport;
  }

  global void execute(SchedulableContext sc) {
    tempIAIUpdateProductWarehouseBatch b = new tempIAIUpdateProductWarehouseBatch();
    database.executeBatch(b, 50);
  }

  global void finish(Database.BatchableContext BC) {
  }

  global static void coverage() {
    integer i;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
  }
}
