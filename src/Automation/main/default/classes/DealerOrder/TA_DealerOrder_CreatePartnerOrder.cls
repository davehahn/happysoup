public without sharing class TA_DealerOrder_CreatePartnerOrder implements TriggerAction.AfterInsert{
    public void afterInsert(List<Dealer_Order__c> newList) {
        DealerOrder_Service.createRequiredPartnerBookingOrders(newList);
    }

}