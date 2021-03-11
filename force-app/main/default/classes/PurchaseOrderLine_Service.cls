/**
 * Created by dave on 2021-03-09.
 */

public with sharing class PurchaseOrderLine_Service
{


  public static void propagateDeliveryDate( Set<Id> polIds )
  {
    List<AcctSeed__Project__c> retailErpsToUpdate = new List<AcctSeed__Project__c>();
    for( AcctSeedERP__Purchase_Order_Line__c pol : PurchaseOrderLine_Selector.allWithPartnerErps_LinkedToRetail( polIds ) )
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