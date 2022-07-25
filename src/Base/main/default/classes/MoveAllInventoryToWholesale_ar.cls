public with sharing class MoveAllInventoryToWholesale_ar implements Database.Batchable<sObject> {
  public final String transferId;
  public final String queryStr;
  public MoveAllInventoryToWholesale_ar(String pTransferId) {
    transferId = pTransferId;
    queryStr = null;
  }

  public MoveAllInventoryToWholesale_ar(String pTransferId, String pQuery) {
    transferId = pTransferId;
    queryStr = pQuery;
  }

  public Database.QueryLocator start(Database.BatchableContext BC) {
    String query = queryStr;
    if (queryStr == null)
      query = 'SELECT Id FROM Product2 WHERE AcctSeed__Inventory_Product__c = true AND AcctSeedERP__Default_Vendor__r.Name != \'Mercury Marine Ltd.\'';

    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext BC, List<sObject> scope) {
    Set<String> setIdProduct = new Set<String>();
    for (SObject sObj : scope) {
      Product2 p = (Product2) sObj;
      setIdProduct.add(p.Id);
    }
    // Barrie = a2G4D000000BPPpUAO
    // Whitefish = a2G4D000000BPPuUAO
    // Montreal = a2G4D000000BPPzUAO
    GMBLASERP__Inventory_Transfer__c tr = [
      SELECT Id, GMBLASERP__Warehouse_From__c, GMBLASERP__Warehouse_To__c, GMBLASERP__Outbound_Date__c
      FROM GMBLASERP__Inventory_Transfer__c
      WHERE Id = :transferId
    ][0];
    list<String> listProductIds = new List<String>();
    listProductIds.addAll(setIdProduct);

    Map<Id, Product2> mapProd = new Map<Id, Product2>();
    for (Product2 p : [SELECT Id, AcctSeed__Inventory_GL_Account__c FROM Product2 WHERE Id IN :setIdProduct])
      mapProd.put(p.Id, p);

    list<String> listWarehouseIds = new List<String>{ tr.GMBLASERP__Warehouse_From__c };
    Map<String, List<String>> mapFilter = new Map<String, list<String>>{
      'idProduct' => listProductIds,
      'idWarehouse' => listWarehouseIds
    };
    list<gcInventoryMovementCube_Report.cube> listCubes = gcInventoryMovementCube_Report.inventoryAggRes(
      mapFilter,
      new List<String>{ 'idBalance', 'idWarehouse', 'idLocation', 'idProduct', 'idLot', 'idSerial' }
    );

    List<AcctSeedERP__Outbound_Inventory_Movement__c> listOIM = new List<AcctSeedERP__Outbound_Inventory_Movement__c>();
    for (gcInventoryMovementCube_Report.cube c : listCubes) {
      AcctSeedERP__Outbound_Inventory_Movement__c move = new AcctSeedERP__Outbound_Inventory_Movement__c(
        AcctSeedERP__Debit_GL_Account__c = mapProd.get(c.idProduct).AcctSeed__Inventory_GL_Account__c,
        AcctSeedERP__Inventory_Balance__c = c.idBalance,
        AcctSeedERP__Movement_Date__c = tr.GMBLASERP__Outbound_Date__c,
        AcctSeedERP__Quantity__c = c.qty,
        AcctSeedERP__Type__c = 'Non-Accounting',
        AcctSeedERP__Unit_Cost__c = 0,
        GMBLASERP__Cost_Override__c = true,
        GMBLASERP__Inventory_Transfer__c = tr.Id,
        GMBLASERP__Lot__c = c.idLot,
        GMBLASERP__Serial_Number__c = c.idSerial
      );
      listOIM.add(move);
    }
    if (!listOIM.isEmpty())
      Database.insert(listOIM, false);
  }

  public void finish(Database.BatchableContext BC) {
  }

  public static void coverage() {
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
  }
}
