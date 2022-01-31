public class TA_DealerOrderLine_HandlePartnerProg {

  public void afterInsert(List<Dealer_Order_Line__c> newList) {

        DealerOrderLine_Service.handlePartnerProgram (newList);
    }
}