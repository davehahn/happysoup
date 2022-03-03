/**
 * Created by dave on 2022-03-02.
 */

public inherited sharing class TA_POL_CreateManufacturingWorkOrder implements TriggerAction.AfterInsert
{
  private Application_RecordType rts {
    get {
      if( rts == null ){
        rts = new Application_RecordType();
      }
      return rts;
    }
    set {}
  }

  public void afterInsert( List< AcctSeedERP__Purchase_Order_Line__c> newList ){
    Map<Id, AcctSeedERP__Purchase_Order_Line__c> newMap = new Map<Id, AcctSeedERP__Purchase_Order_Line__c>(newList);

    List<AcctSeedERP__Purchase_Order_Line__c> requiresWorkOrder = filterRecords( newList );

    if( !requiresWorkOrder.isEmpty() ){
      for( Integer i=0; requiresWorkOrder.size() < i; i++  ){

      }
    }

  }

  private List<AcctSeedERP__Purchase_Order_Line__c> filterRecords( List<AcctSeedERP__Purchase_Order_Line__c> newList ){
    List<AcctSeedERP__Purchase_Order_Line__c> result = new List<AcctSeedERP__Purchase_Order_Line__c>();
    Id boatRtId = rts.getProductRecordTypes().getBoatId();
    for( AcctSeedERP__Purchase_Order_Line__c pol : records ){
      if( pol.AcctSeedERP__Project__c == null && pol.AcctSeedERP__Product__r.RecordTypeId == boatRtId ){
        result.add( pol );
      }
    }
    return result;
  }
}