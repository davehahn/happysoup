
public without sharing class  TA_DealerOrder_SetERPStage implements TriggerAction.AfterUpdate {



        public void afterUpdate(List<Dealer_Order__c> newList, List<Dealer_Order__c> oldList) {
            Map<Id, Dealer_Order__c> oldMap = new Map<Id, Dealer_Order__c> (oldList);
            Map<Id, Id> ownerChanged = new Map<Id, Id>();
            Map<Id, Dealer_Order__c> stageChangeMap = new Map<Id, Dealer_Order__c>();

            for( Dealer_Order__c newOrder : newList )
            {
                Dealer_Order__c oldOrder = oldMap.get( newOrder.Id );
                if( oldOrder.Stage__c != newOrder.Stage__c )
                    stageChangeMap.put( newOrder.Id, newOrder );
            }
            DealerOrder_Service.setErpStage( stageChangeMap );
        }
}