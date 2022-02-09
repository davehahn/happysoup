
public inherited sharing class TA_DealerOrder_SetSubmittedDate implements TriggerAction.BeforeInsert{

    public void beforeInsert( List<Dealer_Order__c> newList)
    {
        for (Dealer_Order__c dealerOrder : newList)
        {
            if (dealerOrder.Stage__c == 'Pending Review') {
                dealerOrder.Date_Submitted__c = DateTime.now();

            }
        }
    }

}