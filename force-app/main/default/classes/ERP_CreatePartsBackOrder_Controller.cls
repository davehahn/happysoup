/**
 * Created by dave on 2021-03-29.
 */

public with sharing class ERP_CreatePartsBackOrder_Controller
{
  @AuraEnabled(Cacheable=true)
  public static Map<String, Object> fetchMaterials( String recordId )
  {
    Id partRt = new Application_RecordType().getProductRecordTypes().getPartId();
    Set<String> ignoreFamilies = new Set<String>{
      'Labour',
      'Premium Package',
      'Service Package',
      'Discount'
    };
    List<AcctSeedERP__Material__c> materials = new Material_Selector()
      .addWhere( 'AcctSeedERP__Project__c = \'' + recordId + '\'')
      .addWhereFieldNotIn( 'AcctSeedERP__Product__r.Family', ignoreFamilies, 'AND' )
      .addWhere( 'AcctSeedERP__Product__r.RecordTypeId = \'' + partRt + '\'' )
      .query();
    Map<String, Object> result = new Map<String, Object>();
    result.put( 'materials', materials );
    result.put(
      'retailERP',
      Project_Selector.allByIds( new Set<Id>{Id.valueOf(recordId)} )[0]
    );
    result.put(
      'creditProductId',
      Utility_Products__c.getOrgDefaults().Backorder_Credit__c
    );
    return result;
  }

  @AuraEnabled
  public static Map<String, Object> createBackOrderERP(
    AcctSeed__Project__c erp,
    AcctSeed__Project_Task__c task,
    List<AcctSeedERP__Material__c> materials
  )
  {
    Id rtId = new Application_RecordType().getERPOrderRecordTypes().getServiceWorkOrderId();
    erp.RecordTypeId = rtId;
    insert erp;

    task.AcctSeed__Project__c = erp.Id;
    insert task;

    for( AcctSeedERP__Material__c mat : materials )
    {
      mat.AcctSeedERP__Project__c = erp.Id;
      mat.AcctSeedERP__Project_Task__c = task.Id;
    }
    insert materials;

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
}