/**
 * Created by dave on 2021-03-29.
 */

public with sharing class ERP_CreatePartsBackOrder_Controller {
  @AuraEnabled(Cacheable=true)
  public static Map<String, Object> fetchMaterials(String recordId) {
    Map<String, Object> result = new Map<String, Object>();
    Application_RecordType appRT = new Application_RecordType();
    Application_RecordType.ProductRTs productRts = appRT.getProductRecordTypes();
    Application_RecordType.ERPOrderRTs erpRts = appRT.getERPOrderRecordTypes();

    Utility_Products__c utilityProducts = Utility_Products__c.getOrgDefaults();
    Set<String> ignoreFamilies = new Set<String>{ 'Labour', 'Premium Package', 'Service Package', 'Discount' };
    List<AcctSeedERP__Material__c> materials = new Material_Selector()
      .addWhere('AcctSeedERP__Project__c = \'' + recordId + '\'')
      .addWhereFieldNotIn('AcctSeedERP__Product__r.Family', ignoreFamilies, 'AND')
      .addWhereFieldNotIn('Material__r.AcctSeedERP__Product__r.Family', ignoreFamilies, 'AND')
      .addWhere('AcctSeedERP__Product__r.RecordTypeId = \'' + productRts.getPartId() + '\'', 'AND')
      .addWhere(
        '( Material__c = null OR Material__r.AcctSeedERP__Product__r.RecordTypeId = \'' +
        productRts.getPartId() +
        '\' )'
      )
      .query();
    AcctSeed__Project__c project = Project_Selector.allByIdsWithTasks(new Set<Id>{ Id.valueOf(recordId) })[0];
    if (project.RecordTypeId == erpRts.getRetailBoatSaleId()) {
      result.put('saleType', 'retail');
    }
    if (project.RecordTypeId == erpRts.getServiceWorkOrderId()) {
      result.put('saleType', 'service');
    }

    result.put('materials', materials);
    result.put('retailERP', project);
    result.put('creditProductId', utilityProducts.Back_Order_Credit__c);
    result.put('prepaidProductId', utilityProducts.Back_Order_Prepaid__c);
    result.put('kitContents', kitsFromMaterials(materials));
    return result;
  }

  @AuraEnabled
  public static List<Case> findPartsRequestCases(Id originalErpId, List<Id> materialIds) {
    List<Case> cases = Case_Selector.allByErpOrderIdIncludingCasePartsWithMaterial(
      originalErpId,
      new Set<Id>(materialIds)
    );
    for (Integer i = 0; i < cases.size(); i++) {
      if (cases[i].Case_Parts__r.size() == 0) {
        cases.remove(i);
      }
    }
    return cases;
  }

  @AuraEnabled
  public static Map<String, Object> buildBackOrderERP(
    Id originalErpId,
    String transferredQuantityByMaterialId,
    String taskCause
  ) {
    Map<Id, Map<String, String>> quantityMap = (Map<Id, Map<String, String>>) JSON.deserialize(
      transferredQuantityByMaterialId,
      Map<Id, Map<String, String>>.class
    );
    Map<String, Object> result = new Map<String, Object>();
    AcctSeed__Project__c originalERP = Project_Selector.allByIdWithMaterialsById(
      new Set<Id>{ originalErpId },
      quantityMap.keySet()
    )[0];

    result.put('erp', Project_Service.buildBackOrder(originalERP));
    result.put(
      'task',
      ProjectTask_Service.buildBackOrderTask(originalERP.RecordType.Name + ' - Back Order', taskCause)
    );
    result.put(
      'materials',
      Material_Service.buildForBackOrder(originalERP.AcctSeedERP__Project_Materials__r, quantityMap)
    );
    return result;
  }

  @AuraEnabled
  public static Map<String, Object> createBackOrderERP(
    AcctSeed__Project__c erp,
    AcctSeed__Project_Task__c task,
    List<AcctSeedERP__Material__c> materials,
    List<Id> caseIds
  ) {
    insert erp;

    task.AcctSeed__Project__c = erp.Id;
    insert task;

    for (AcctSeedERP__Material__c mat : materials) {
      mat.AcctSeedERP__Project__c = erp.Id;
      mat.AcctSeedERP__Project_Task__c = task.Id;
    }
    Boolean origState = gcMaterial.disableTaskLockCheck;
    gcMaterial.disableTaskLockCheck = true;
    insert materials;
    gcMaterial.disableTaskLockCheck = origState;

    if (caseIds.size() > 0) {
      List<Case> updateCases = new List<Case>();
      for (Id caseId : caseIds) {
        updateCases.add(new Case(Id = caseId, ERP_Order__c = erp.Id));
      }
      update updateCases;
    }

    Map<String, Object> result = new Map<String, Object>();
    result.put('erp', Project_Selector.allByIds(new Set<Id>{ erp.Id })[0]);
    result.put('task', task);
    result.put('materials', Material_Selector.selectAllByTaskId(new Set<Id>{ task.Id }));
    return result;
  }

  @AuraEnabled
  public static List<CommissionLineItem2__c> buildCommissionLines(List<AcctSeedERP__Material__c> materials) {
    List<CommissionLineItem2__c> result = new List<CommissionLineItem2__c>();
    Map<Id, List<AcctSeedERP__Material__c>> materialsByTaskId = new Map<Id, List<AcctSeedERP__Material__c>>();
    Set<Id> parentMatIds = new Set<Id>();
    Set<Id> allMatIds = new Set<Id>();
    for (AcctSeedERP__Material__c mat : materials) {
      allMatIds.add(mat.Id);
      if (mat.Material__c == null) {
        parentMatIds.add(mat.Id);
      }
    }
    Set<Id> productIds = new Set<Id>();
    for (AcctSeedERP__Material__c mat : materials) {
      if (mat.Material__c == null || (mat.Material__c != null && !parentMatIds.contains(mat.Material__c))) {
        productIds.add(mat.AcctSeedERP__Product__c);
        if (!materialsByTaskId.containsKey(mat.AcctSeedERP__Project_Task__c)) {
          materialsByTaskId.put(mat.AcctSeedERP__Project_Task__c, new List<AcctSeedERP__Material__c>());
        }
        materialsByTaskId.get(mat.AcctSeedERP__Project_Task__c).add(mat);
      }
    }
    Map<Id, CommissionLineItem2__c> commLineByMatId = new Map<Id, CommissionLineItem2__c>();
    for (CommissionLineItem2__c cli : CommissionLineItem2_Selector.allByMaterialIds(allMatIds)) {
      commLineByMatId.put(cli.Material__c, cli);
    }
    Map<Id, CommissionRecord2__c> comRecordIdByTaskId = new Map<Id, CommissionRecord2__c>();
    for (CommissionRecord2__c cr : CommissionRecord2_Selector.allByProjectTaskIds(materialsByTaskId.keySet())) {
      comRecordIdByTaskId.put(cr.Project_Task__c, cr);
    }
    Map<Id, PricebookEntry> pricebookEntryByProductId = new Map<Id, PricebookEntry>();
    for (PricebookEntry pbe : PricebookEntry_Selector.allFactoryEntriesByProductId(productIds)) {
      pricebookEntryByProductId.put(pbe.Product2Id, pbe);
    }

    for (String taskId : materialsByTaskId.keySet()) {
      Decimal cost = 0;
      Decimal sale = 0;
      Decimal labour = 0;
      for (AcctSeedERP__Material__c mat : materialsByTaskId.get(taskId)) {
        Decimal riggingTime;
        if (
          mat.Material__c == null // if Material__c != null, then it was part of a kit and the price is included in the kit so all should be zero
        ) {
          //try to get cost, sale, labour prices from original commission line item
          if (commLineByMatId.containsKey(mat.Id)) {
            CommissionLineItem2__c cli = commLineByMatId.get(mat.Id);
            cost += cli.Total_Cost__c;
            sale += cli.Total_Sale__c;
            labour += cli.Total_Labour__c;
          } else {
            if (pricebookEntryByProductId.containsKey(mat.AcctSeedERP__Product__c)) {
              riggingTime = pricebookEntryByProductId.get(mat.AcctSeedERP__Product__c).Product2.Rigging_Time__c;
              cost +=
                pricebookEntryByProductId.get(mat.AcctSeedERP__Product__c).UnitPrice *
                mat.AcctSeedERP__Quantity_Per_Unit__c;
            }
            sale += mat.GMBLASERP__Unit_Price__c * mat.AcctSeedERP__Quantity_Per_Unit__c;
            labour += riggingTime == null
              ? 0
              : riggingTime * mat.AcctSeedERP__Quantity_Per_Unit__c * LGND_Constants.retailLabourRate;
          }
        }
      }
      Decimal rate = comRecordIdByTaskId.get(taskId).Calculation_Method__c == 'Gross Margin'
        ? CommissionLineItem2_Service.grossMarginRate
        : CommissionLineItem2_Service.partsRate;
      result.add(
        new CommissionLineItem2__c(
          Comment__c = 'Parts Back Order Entry',
          CommissionRecord2__c = comRecordIdByTaskId.get(taskId).Id,
          CommissionRecord2__r = comRecordIdByTaskId.get(taskId),
          Cost__c = cost,
          Sale_Price__c = sale,
          Description__c = 'Parts Back Order Entry',
          Labour_Cost__c = labour,
          Quantity__c = 1,
          Commission_Rate__c = rate
        )
      );
    }
    return result;
  }

  @AuraEnabled
  public static void updateOriginalSale(
    String quantityTransferredByMatId,
    List<AcctSeedERP__Material__c> newMaterials,
    List<CommissionLineItem2__c> newCommissionLines
  ) {
    Boolean disableTaskLockCheck = gcMaterial.disableTaskLockCheck;
    Boolean disableProjectLockCheck = gcProject.disableLockedCheck;
    Boolean disableCommission = gcMaterial.disableCommission;
    gcMaterial.disableTaskLockCheck = true;
    gcProject.disableLockedCheck = true;
    gcMaterial.disableCommission = true;

    List<AcctSeedERP__Material__c> deleteMats = new List<AcctSeedERP__Material__c>();
    List<AcctSeedERP__Material__c> upsertMats = new List<AcctSeedERP__Material__c>();
    upsertMats.addAll(newMaterials);

    Map<Id, Decimal> qtyByMatId = (Map<Id, Decimal>) JSON.deserialize(
      quantityTransferredByMatId,
      Map<Id, Decimal>.class
    );
    if (qtyByMatId.size() > 0) {
      List<AcctSeedERP__Material__c> mats = Material_Selector.selectAllByIds(qtyByMatId.keySet());

      for (AcctSeedERP__Material__c mat : mats) {
        if (mat.AcctSeedERP__Quantity_Per_Unit__c == qtyByMatId.get(mat.Id)) {
          deleteMats.add(mat);
        } else {
          mat.AcctSeedERP__Quantity_Per_Unit__c = mat.AcctSeedERP__Quantity_Per_Unit__c - qtyByMatId.get(mat.Id);
          upsertMats.add(mat);
        }
      }
    }
    delete deleteMats;
    upsert upsertMats;
    insert newCommissionLines;
    gcMaterial.disableTaskLockCheck = disableTaskLockCheck;
    gcProject.disableLockedCheck = disableProjectLockCheck;
    gcMaterial.disableCommission = disableCommission;
  }

  private static Map<String, Object> kitsFromMaterials(List<AcctSeedERP__Material__c> mats) {
    Map<String, Object> result = new Map<String, Object>();
    Set<Id> prodIds = new Set<Id>();
    for (AcctSeedERP__Material__c m : mats) {
      prodIds.add(m.AcctSeedERP__Product__c);
    }
    for (Product2 kit : Product_Selector.allKitsWithKitPartsById(prodIds)) {
      Map<String, Decimal> kitParts = new Map<String, Decimal>();
      for (AcctSeed__Product_Part__c pp : kit.AcctSeed__Product_Parts__r) {
        kitParts.put(pp.AcctSeed__Product_Part__c, pp.AcctSeed__Quantity__c);
      }
      result.put(kit.Id, kitParts);
    }
    return result;
  }
}
