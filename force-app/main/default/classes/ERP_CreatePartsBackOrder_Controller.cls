/**
 * Created by dave on 2021-03-29.
 */

public with sharing class ERP_CreatePartsBackOrder_Controller
{
  @AuraEnabled(Cacheable=true)
  public static Map<String, Object> fetchMaterials( String recordId )
  {
    Map<String, Object> result = new Map<String, Object>();
    Application_RecordType appRT = new Application_RecordType();
    Application_RecordType.ProductRTs productRts = appRT.getProductRecordTypes();
    Application_RecordType.ERPOrderRTs erpRts = appRT.getERPOrderRecordTypes();

    Utility_Products__c utilityProducts = Utility_Products__c.getOrgDefaults();
    Set<String> ignoreFamilies = new Set<String>{
      'Labour',
      'Premium Package',
      'Service Package',
      'Discount'
    };
    List<AcctSeedERP__Material__c> materials = new Material_Selector()
      .addWhere( 'AcctSeedERP__Project__c = \'' + recordId + '\'')
      .addWhereFieldNotIn( 'AcctSeedERP__Product__r.Family', ignoreFamilies, 'AND' )
      .addWhere( 'AcctSeedERP__Product__r.RecordTypeId = \'' + productRts.getPartId() + '\'' )
      .query();
    AcctSeed__Project__c project = Project_Selector.allByIdsWithTasks( new Set<Id>{Id.valueOf(recordId)} )[0];
    if( project.RecordTypeId == erpRts.getRetailBoatSaleId() )
    {
      result.put('saleType', 'retail');
    }
    if( project.RecordTypeId == erpRts.getServiceWorkOrderId() )
    {
      result.put('saleType', 'service');
    }

    result.put( 'materials', materials );
    result.put(
      'retailERP',
      project
    );
    result.put(
      'creditProductId',
      utilityProducts.Back_Order_Credit__c
    );
    result.put(
      'prepaidProductId',
      utilityProducts.Back_Order_Prepaid__c
    );
    return result;
  }

  @AuraEnabled
  public static List<Case> findPartsRequestCases(
    Id originalErpId,
    List<Id> materialIds )
  {
    List<Case> cases = Case_Selector.allByErpOrderIdIncludingCasePartsWithMaterial(
      originalErpId,
      new Set<Id>(materialIds) );
    for( Integer i=0; i<cases.size(); i++  )
    {
      if( cases[i].Case_Parts__r.size() == 0 )
      {
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
  )
  {
    Map<Id,Decimal> quantityMap = (Map<Id,Decimal>)JSON.deserialize(
      transferredQuantityByMaterialId,
      Map<Id,Decimal>.class
    );
    Map<String, Object> result = new Map<String, Object>();
    AcctSeed__Project__c originalERP = Project_Selector.allByIdWithMaterialsById(
      new Set<Id>{ originalErpId },
      quantityMap.keySet()
    )[0];

    result.put('erp', Project_Service.buildBackOrder( originalERP ) );
    result.put('task', ProjectTask_Service.buildBackOrderTask(
      originalERP.RecordType.Name + ' - Back Order',
      taskCause
    ));
    result.put('materials', Material_Service.buildForBackOrder(
      originalERP.AcctSeedERP__Project_Materials__r,
      quantityMap
    ));
    return result;
  }

  @AuraEnabled
  public static Map<String, Object> createBackOrderERP(
    AcctSeed__Project__c erp,
    AcctSeed__Project_Task__c task,
    List<AcctSeedERP__Material__c> materials,
    List<Id> caseIds
  )
  {
    insert erp;

    task.AcctSeed__Project__c = erp.Id;
    insert task;

    for( AcctSeedERP__Material__c mat : materials )
    {
      mat.AcctSeedERP__Project__c = erp.Id;
      mat.AcctSeedERP__Project_Task__c = task.Id;
    }
    Boolean origState = gcMaterial.disableTaskLockCheck;
    gcMaterial.disableTaskLockCheck = true;
    insert materials;
    gcMaterial.disableTaskLockCheck = origState;

    if( caseIds.size() > 0 )
    {
      List<Case> updateCases = new List<Case>();
      for( Id caseId : caseIds )
      {
        updateCases.add( new Case(
          Id = caseId,
          ERP_Order__c = erp.Id
        ));
      }
      update updateCases;
    }

    Map<String, Object> result = new Map<String, Object>();
    result.put(
      'erp',
      Project_Selector.allByIds( new Set<Id>{erp.Id} )[0]
    );
    result.put(
      'task',
      task
    );
    result.put(
      'materials',
      Material_Selector.selectAllByTaskId( new Set<Id>{ task.Id} )
    );
    return result;
  }

  @AuraEnabled
  public static List<CommissionLineItem2__c> buildCommissionLines
    ( List<AcctSeedERP__Material__c>  materials)
  {
    List<CommissionLineItem2__c> result = new List<CommissionLineItem2__c>();
    Map<Id, List<AcctSeedERP__Material__c>> materialsByTaskId = new Map<Id, List<AcctSeedERP__Material__c>>();
    Set<Id> productIds = new Set<Id>();
    for( AcctSeedERP__Material__c mat : materials )
    {
      System.debug( mat.AcctSeedERP__Product__r.Name);
      System.debug( mat.AcctSeedERP__Project_Task__c);
      productIds.add( mat.AcctSeedERP__Product__c );
      if( !materialsByTaskId.containsKey( mat.AcctSeedERP__Project_Task__c ) )
      {
        materialsByTaskId.put(
          mat.AcctSeedERP__Project_Task__c,
          new List<AcctSeedERP__Material__c>()
        );
      }
      materialsByTaskId.get( mat.AcctSeedERP__Project_Task__c ).add( mat );
    }
    Map<Id, CommissionRecord2__c> comRecordIdByTaskId = new Map<Id, CommissionRecord2__c>();
    for( CommissionRecord2__c cr : CommissionRecord2_Selector.allByProjectTaskIds( materialsByTaskId.keySet() ) )
    {
      comRecordIdByTaskId.put( cr.Project_Task__c, cr );
    }
    Map<Id, PricebookEntry> pricebookEntryByProductId = new Map<Id, PricebookEntry>();
    for( PricebookEntry pbe : PricebookEntry_Selector.allFactoryEntriesByProductId( productIds ) )
    {
      pricebookEntryByProductId.put( pbe.Product2Id, pbe );
    }

    for( String taskId : materialsByTaskId.keySet() )
    {
      Decimal cost = 0;
      Decimal sale = 0;
      Decimal labour = 0;
      for( AcctSeedERP__Material__c mat : materialsByTaskId.get( taskId ) )
      {
        Decimal riggingTime;
        if( pricebookEntryByProductId.containsKey( mat.AcctSeedERP__Product__c) )
        {
          riggingTime = pricebookEntryByProductId.get(mat.AcctSeedERP__Product__c).Product2.Rigging_Time__c;
          cost += pricebookEntryByProductId.get(mat.AcctSeedERP__Product__c).UnitPrice * mat.AcctSeedERP__Quantity_Per_Unit__c;
        }
        sale += mat.GMBLASERP__Unit_Price__c * mat.AcctSeedERP__Quantity_Per_Unit__c;

        labour += riggingTime == null ? 0 : riggingTime;
      }
      Decimal rate = comRecordIdByTaskId.get( taskId ).Calculation_Method__c == 'Gross Margin' ?
        CommissionLineItem2_Service.grossMarginRate :
        CommissionLineItem2_Service.partsRate;
      result.add( new CommissionLineItem2__c(
          Comment__c = 'Parts Back Order Entry',
          CommissionRecord2__c = comRecordIdByTaskId.get( taskId ).Id,
          CommissionRecord2__r = comRecordIdByTaskId.get( taskId ),
          Cost__c = cost,
          Sale_Price__c = sale,
          Description__c = 'Parts Back Order Entry',
          Labour_Cost__c = labour * LGND_Constants.retailLabourRate,
          Quantity__c = 1,
          Commission_Rate__c = rate
        )
      );
    }
    return result;
  }

  @AuraEnabled
  public static void updateOriginalSale(
    List<Id> deleteMaterialIds,
    List<AcctSeedERP__Material__c> newMaterials,
    List<CommissionLineItem2__c> newCommissionLines
  )
  {
    Boolean disableTaskLockCheck = gcMaterial.disableTaskLockCheck;
    Boolean allowKitPartDelete = gcMaterial.allowKitPartDelete;
    Boolean disableProjectLockCheck = gcProject.disableLockedCheck;
    Boolean disableCommission = gcMaterial.disableCommission;
    gcMaterial.disableTaskLockCheck = true;
    gcMaterial.allowKitPartDelete = true;
    gcProject.disableLockedCheck = true;
    gcMaterial.disableCommission = true;
    List<AcctSeedERP__Material__c> deleteMats = new List<AcctSeedERP__Material__c>();
    for( Id matId : deleteMaterialIds )
    {
      deleteMats.add( new AcctSeedERP__Material__c(
        Id = matId
      ));
    }
    delete deleteMats;
    insert newMaterials;
    insert newCommissionLines;
    gcMaterial.disableTaskLockCheck = disableTaskLockCheck;
    gcMaterial.allowKitPartDelete =  allowKitPartDelete;
    gcProject.disableLockedCheck = disableProjectLockCheck;
    gcMaterial.disableCommission = disableCommission;
  }

}