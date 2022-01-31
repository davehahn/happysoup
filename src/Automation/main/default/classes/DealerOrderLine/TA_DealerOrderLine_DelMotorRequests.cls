/**
 * Created by dhavalmacbook on 20/01/22.
 */

public inherited sharing  class TA_DealerOrderLine_DelMotorRequests implements TriggerAction.AfterDelete{


    public void afterDelete(List<Dealer_Order_Line__c> oldList) {
        Set<Id> motorRequestIds = new Set<Id>();
        List<Dealer_Order_Line__c> dols = (List<Dealer_Order_Line__c>)Trigger.oldMap.values();

        for( Dealer_Order_Line__c dol : dols )
        {
            if( dol.Dealer_Motor_Request__c != null )
                motorRequestIds.add( dol.Dealer_Motor_Request__c );
        }
        if( motorRequestIds.size() > 0 )
            DealerOrderLine_Service.deleteDealerMotorRequests( motorRequestIds );
    }
}