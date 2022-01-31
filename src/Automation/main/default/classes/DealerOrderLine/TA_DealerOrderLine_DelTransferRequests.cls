/**
 * Created by dhavalmacbook on 20/01/22.
 */

public inherited sharing class TA_DealerOrderLine_DelTransferRequests implements TriggerAction.AfterDelete{

    public void afterDelete(List<SObject> oldList) {
        Set<Id> transferIds = new Set<Id>();

        List<Dealer_Order_Line__c> dols = (List<Dealer_Order_Line__c>)Trigger.oldMap.values();

        for( Dealer_Order_Line__c dol : dols ) {
            if (dol.Legend_Transfer_Request__c != null) {
                transferIds.add(dol.Legend_Transfer_Request__c);
            }
        }
        if( transferIds.size() > 0 )
            DealerOrderLine_Service.deleteLegendTransferRequests( transferIds );
    }
}