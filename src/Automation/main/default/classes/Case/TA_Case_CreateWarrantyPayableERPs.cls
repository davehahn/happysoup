/**
 * Created by dave on 2022-01-04.
 */

public inherited sharing class TA_Case_CreateWarrantyPayableERPs implements TriggerAction.BeforeInsert
{
  public void beforeInsert( List<Case> newList ){
    Id warrantyRtId = new Application_RecordType().getCaseRecordTypes().getWarrantyId();
    List<Case> requiresERP_cases = new List<Case>();
    for( Case c : newList )
    {
      if( c.RecordTypeId == warrantyRtId  &&
        c.Warranty_ERP__c == null )
      {
        requiresERP_cases.add( c );
      }
    }
    Project_Service.insertWarrantyPayablesFromCases( requiresERP_cases );
  }

}