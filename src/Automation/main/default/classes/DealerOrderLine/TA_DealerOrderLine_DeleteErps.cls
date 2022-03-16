
public without sharing class TA_DealerOrderLine_DeleteErps implements TriggerAction.AfterDelete{

    public void afterDelete(List<Dealer_Order_Line__c> oldList) {
        Set<Id> erpIds = new Set<Id>();
        Set<Id> dealerOrderIds = new Set<Id>();


        for( Dealer_Order_Line__c dol : oldList )
        {
            if( dol.ERP_Order__c != null )
            {
                erpIds.add(dol.ERP_Order__c);
                dealerOrderIds.add( dol.Dealer_Order__c );
            }
        }
        if( erpIds.size() > 0 )
        {
            TriggerBase.bypass('Dealer_Order__c');
            DealerOrderLine_Service.deleteErps(erpIds);
            TriggerBase.clearBypass('Dealer_Order__c');
        }

    }
}