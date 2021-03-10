/**
 * Created by dave on 2021-03-09.
 */

public with sharing class PurchaseOrderLine_Service
{


  public static void propagateDeliveryDate( Set<Id> polIds )
  {
    Id partnerErpRtId = new Application_RecordType()
      .getERPOrderRecordTypes()
      .getPartnerBoatSaleId();
    List<AcctSeedERP__Purchase_Order_Line__c> pols = [
      SELECT
        Id,
        deliverDate__c,
        AcctSeedERP__Project__c,
        AcctSeedERP__Project__r.Retail_ERP__c
      FROM AcctSeedERP__Purchase_Order_Line__c
      WHERE Id IN :polIds
      AND AcctSeedERP__Project__r.RecordTypeId = :partnerErpRtId
      AND AcctSeedERP__Project__r.Retail_ERP__c <> null
    ];

    List<AcctSeed__Project__c> retailErpsToUpdate = new List<AcctSeed__Project__c>();
    for( AcctSeedERP__Purchase_Order_Line__c pol : pols )
    {
      retailErpsToUpdate.add( new AcctSeed__Project__c(
        Id = pol.AcctSeedERP__Project__r.Retail_ERP__c,
        Arrival_Date__c = pol.deliverDate__c
      ));
    }
    Boolean orig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    update retailErpsToUpdate;
    gcProject.disableTrigger = orig;
  }

}