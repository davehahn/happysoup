/**
 * Created by dhavalmacbook on 20/01/22.
 */

public inherited sharing class DealerOrderLine_Service {
  public static void setLineTotal(List<Dealer_Order_Line__c> lines) {
    System.debug('DealerOrderLine_Service.setLineTotal');
    for (Dealer_Order_Line__c dol : lines) {
      dol.Line_Total__c = dol.Line_Total_Pre_Tax__c;
      dol.Line_Total_No_Fees_or_Discounts__c = dol.Line_Total_NoFeesOrDiscountsCalc__c;
    }
  }

  public static void handlePartnerProgram(List<Dealer_Order_Line__c> listNew) {
    Set<Id> dealerOrderIds = new Set<Id>();
    for (Dealer_Order_Line__c dol : listNew) {
      if (dol.ERP_Order__c != null && !dol.Is_For_Factory_Store__c) {
        dealerOrderIds.add(dol.Dealer_Order__c);
      }
    }
    applyPartnerProgram(dealerOrderIds);
  }

  @Future
  public static void applyPartnerProgram(Set<Id> dealerOrderIds) {
    Map<Id, Dealer_Order__c> dealerOrders = new Map<Id, Dealer_Order__c>(
      [SELECT Id FROM Dealer_Order__c WHERE Id IN :dealerOrderIds AND Is_Booking_Order__c = TRUE]
    );
    PartnerProgram_Service ppService = new PartnerProgram_Service(dealerOrders.keySet());
    ppService.checkAndApply();
  }

  public static void deleteErps(Set<Id> erpIds) {
    delete [SELECT Id FROM AcctSeed__Project_Task__c WHERE AcctSeed__Project__c IN :erpIds];
    delete [SELECT Id FROM AcctSeed__Project__c WHERE Id IN :erpIds];
  }

  public static void deleteLegendTransferRequests(Set<Id> transferIds) {
    Legend_Transfer_Request__c[] ltrs = [SELECT Id FROM Legend_Transfer_Request__c WHERE Id IN :transferIds];
    delete ltrs;
  }

  public static void deleteDealerMotorRequests(Set<Id> motorRequestIds) {
    Dealer_Motor_Request__c[] dmrs = [SELECT Id FROM Dealer_Motor_Request__c WHERE Id IN :motorRequestIds];
    delete dmrs;
  }
}
