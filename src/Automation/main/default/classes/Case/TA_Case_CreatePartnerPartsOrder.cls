/**
 * Created by dave on 2022-01-05.
 */

public inherited sharing class TA_Case_CreatePartnerPartsOrder implements  TriggerAction.AfterUpdate
{

  public void afterUpdate( List<Case> newList, List<Case> oldList ){
    Map<Id, Case> oldMap = new Map<Id, Case>( oldList );
    createPartsOrders( newList, oldMap );
  }

  private void createPartsOrders( List<Case> newList, Map<Id, Case> oldMap ){
    Id warrantyRtId = new Application_RecordType().getCaseRecordTypes().getWarrantyId();
    Set<Id> caseIds = new Set<Id>();
    for( case c : newList )
    {
      if( c.RecordTypeId == warrantyRtId &&
        c.Status == 'Approved' &&
        c.Parts_Order_ERP__c == null &&
        ( oldMap == null ||
          oldMap != null && oldMap.get(c.Id).Status != 'Approved' ) )
      {
        caseIds.add( c.Id );
      }
    }
    if( caseIds.size() > 0 )
    {
      Project_Service.PartnerPartsOrderFromCases_Queue queue =
        new Project_Service.PartnerPartsOrderFromCases_Queue( caseIds );
      System.enqueueJob( queue );
    }
  }

}