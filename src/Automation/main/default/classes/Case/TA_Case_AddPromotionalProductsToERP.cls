/**
 * Created by dave on 2022-01-10.
 */

public without sharing class TA_Case_AddPromotionalProductsToERP implements TriggerAction.AfterUpdate
{
  public void afterUpdate( List<Case> newList, List<Case> oldList ){
    Map<Id, Case> oldMap = new Map<Id, Case>( oldList );
    Map<String, String> applicableData = new Map<String, String>();
    Id promoRtId = new Application_RecordType().getCaseRecordTypes().getPromotionId();
    for( Case c : newList )
    {
      if( c.RecordTypeId == promoRtId &&
        c.Promotion_ERP__c != null &&
        c.PromotionId__c != null &&
        c.Status == 'Complete' &&
        oldMap.get(c.Id).Status != 'Complete' )
      {
        System.debug('case is applicable');
        applicableData.put(
          c.Promotion_ERP__c, c.PromotionId__c
        );
      }
    }
    if( applicableData.size() > 0 )
    {
      Promotion_Service.addPromotionItemsToERP( applicableData );
    }
  }
}