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
    return result;
  }
}