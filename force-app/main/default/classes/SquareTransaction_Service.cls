/**
 * Created by dave on 2020-06-16.
 */

public without sharing class SquareTransaction_Service
{

  public static Square_Transaction__c newFromOnlineBoatReservation( SquareProcessor.PaymentResult paymentResult )
  {
    Opportunity opp = Opportunity_Selector.allByIds( new Set<Id>{ paymentResult.reference_id } )[0];
    Square_Transaction__c squareTransaction = new Square_Transaction__c(
      Account__c = opp.AccountId,
      Amount__c = paymentResult.amount_money.amount,
      Description__c = opp.Name,
      Notes__c = 'Deposit for Online Boat Reservation',
      sqOrderID__c = paymentResult.order_id,
      sqCreateDate__c = paymentResult.created_at,
      sqReceiptNumber__c = paymentResult.receipt_number,
      sqReceiptURL__c = paymentResult.receipt_url,
      sqStatus__c = 'COMPLETED'
    );
    insert squareTransaction;
    return squareTransaction;
  }
}