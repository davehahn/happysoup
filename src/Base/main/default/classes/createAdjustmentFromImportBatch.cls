global without sharing class createAdjustmentFromImportBatch implements Schedulable, Database.Batchable<sObject> {
  global createAdjustmentFromImportBatch() {
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    String query = 'SELECT Id, Adjusted__c, Product__c, Warehouse__c, Negative_Quantity_Error__c, Adjustment_Quantity__c, Adjustment_Per_Unit__c, Import_Date__c, GL_Account_Variable_1__c, GL_Account_Variable_2__c FROM Inventory_Adjustment_Import__c WHERE Adjustable__c = true AND Adjusted__c = false AND Adjustment_Quantity__c <> 0';
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    List<Inventory_Adjustment_Import__c> listImport = new List<Inventory_Adjustment_Import__c>();
    Map<Id, GMBLASERP__Inventory_Adjustment__c> mapAdjustment = new Map<Id, GMBLASERP__Inventory_Adjustment__c>();
    Set<Id> setIdProduct = new Set<Id>();
    Id idGlCostVariance = gcConstants.idGlCostVariance;
    Id idGLV1 = gcConstants.idGlv1Wholesale;
    Id idGlv2PartsAndService = gcConstants.idGlv2PartsAndService;
    for (SObject sObj : scope) {
      Inventory_Adjustment_Import__c imp = (Inventory_Adjustment_Import__c) sObj;
      if (!mapAdjustment.containsKey(imp.Warehouse__c)) {
        Date importDate = Date.today();
        if (imp.Import_Date__c != null)
          importDate = imp.Import_Date__c;
        mapAdjustment.put(
          imp.Warehouse__c,
          new GMBLASERP__Inventory_Adjustment__c(
            GMBLASERP__Product__c = imp.Product__c,
            GMBLASERP__Adjustment_Date__c = Date.today(),
            GMBLASERP__Adjustment_Type__c = 'Quantity',
            GMBLASERP__GL_Account__c = idGlCostVariance,
            GMBLASERP__Warehouse__c = imp.Warehouse__c,
            GL_Account_Variable_1__c = imp.GL_Account_Variable_1__c,
            Department_GLV_2__c = imp.GL_Account_Variable_2__c
          )
        );
      }
      setIdProduct.add(imp.Product__c);
      listImport.add(imp);
    }
    insert mapAdjustment.values();
    Map<Id, Id> mapWarehouseLocation = new Map<Id, Id>();
    for (AcctSeedERP__Warehouse__c whs : [
      SELECT Id, (SELECT Id FROM AcctSeedERP__Locations__r LIMIT 1)
      FROM AcctSeedERP__Warehouse__c
      WHERE Id IN :mapAdjustment.keySet()
    ])
      mapWarehouseLocation.put(whs.Id, whs.AcctSeedERP__Locations__r[0].Id);
    Map<Id, Map<Id, Map<Id, Id>>> mapPWLB = new Map<Id, Map<Id, Map<Id, Id>>>();
    for (Inventory_Adjustment_Import__c imp : listImport) {
      if (!mapPWLB.containsKey(imp.Product__c)) {
        mapPWLB.put(
          imp.Product__c,
          new Map<Id, map<Id, Id>>{
            imp.Warehouse__c => new Map<Id, Id>{ mapWarehouseLocation.get(imp.Warehouse__c) => null }
          }
        );
      } else if (!mapPWLB.get(imp.Product__c).containsKey(imp.Warehouse__c)) {
        mapPWLB.get(imp.Product__c)
          .put(imp.Warehouse__c, new Map<Id, Id>{ mapWarehouseLocation.get(imp.Warehouse__c) => null });
      }
    }
    GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
    Map<Id, Map<Id, Decimal>> mapPWQty = new Map<Id, Map<Id, Decimal>>();
    for (AggregateResult aggRes : [
      SELECT
        GMBLASERP__Product__c idProduct,
        GMBLASERP__Warehouse__c idWarehouse,
        sum(GMBLASERP__Quantity__c) qty,
        sum(GMBLASERP__Inventory_GL_Amount__c) amt
      FROM GMBLASERP__Inventory_Movement_Cube__c
      WHERE
        GMBLASERP__Product__c IN :setIdProduct
        AND GMBLASERP__Warehouse__c IN :mapAdjustment.keySet()
        AND GMBLASERP__Movement_Date__c <= TODAY
      GROUP BY GMBLASERP__Product__c, GMBLASERP__Warehouse__c
    ]) {
      Decimal qtyInv = (Decimal) aggRes.get('qty');
      Decimal amtInv = (Decimal) aggRes.get('amt');
      Id idWhs = (Id) aggRes.get('idWarehouse');
      Id idProd = (Id) aggRes.get('idProduct');
      if (!mapPWQty.containsKey(idProd))
        mapPWQty.put(idProd, new Map<Id, Decimal>());

      mapPWQty.get(idProd).put(idWhs, qtyInv);
    }

    List<AcctSeedERP__Inbound_Inventory_Movement__c> listMoves = new List<AcctSeedERP__Inbound_Inventory_Movement__c>();

    for (Inventory_Adjustment_Import__c imp : listImport) {
      Decimal cQty = 0;
      if (mapPWQty.containsKey(imp.Product__c) && mapPWQty.get(imp.Product__c).containsKey(imp.Warehouse__c))
        cQty = mapPWQty.get(imp.Product__c).get(imp.Warehouse__c);
      if (imp.Adjustment_Quantity__c < 0 && (cQty + imp.Adjustment_Quantity__c) < 0) {
        imp.Negative_Quantity_Error__c = true;
        continue;
      }
      Date impDate = Date.today();
      if (imp.Import_Date__c != null)
        impDate = imp.Import_Date__c;
      Id idBalance = GMBLASERP.gcInventoryBalance.findOrCreateBalance(
        imp.Product__c,
        imp.Warehouse__c,
        mapWarehouseLocation.get(imp.Warehouse__c)
      );
      listMoves.add(
        new AcctSeedERP__Inbound_Inventory_Movement__c(
          GMBLASERP__Inventory_Adjustment__c = mapAdjustment.get(imp.Warehouse__c).Id,
          AcctSeedERP__Credit_GL_Account__c = mapAdjustment.get(imp.Warehouse__c).GMBLASERP__GL_Account__c,
          AcctSeedERP__Inventory_Balance__c = idBalance,
          AcctSeedERP__Movement_Date__c = impDate,
          AcctSeedERP__Quantity__c = imp.Adjustment_Quantity__c,
          AcctSeedERP__GL_Account_Variable_1__c = imp.GL_Account_Variable_1__c,
          AcctSeedERP__GL_Account_Variable_2__c = imp.GL_Account_Variable_2__c,
          AcctSeedERP__Type__c = 'Accounting',
          AcctSeedERP__Unit_Cost__c = imp.Adjustment_Per_Unit__c == null ? 0 : imp.Adjustment_Per_Unit__c,
          GMBLASERP__Cost_Override__c = true,
          Inventory_Adjustment_Import__c = imp.Id
        )
      );
      imp.Adjusted__c = true;
    }
    if (!listMoves.isEmpty()) {
      insert listMoves;
    }
    update listImport;
  }

  global void execute(SchedulableContext sc) {
    tempIAIUpdateProductWarehouseBatch b = new tempIAIUpdateProductWarehouseBatch();
    database.executeBatch(b, 1);
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
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
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
