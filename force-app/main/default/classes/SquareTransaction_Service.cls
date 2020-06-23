/**
 * Created by dave on 2020-06-16.
 */

public without sharing class SquareTransaction_Service
{

  public static Square_Transaction__c newFromOnlineBoatReservation( SquareProcessor.PaymentResult paymentResult )
  {
    Opportunity opp = Opportunity_Selector.allByIds( new Set<Id>{ paymentResult.reference_id } )[0];
    System.debug( 'PAYMENT RESPONSE AMOUNT = ' + paymentResult.amount_money.amount );
    Square_Transaction__c squareTransaction = new Square_Transaction__c(
      Account__c = opp.AccountId,
      Amount__c = paymentResult.amount_money.amount,
      Description__c = opp.Name,
      Notes__c = 'Deposit for Online Boat Reservation',
      sqOrderID__c = paymentResult.order_id,
      sqCreateDate__c = paymentResult.created_at,
      sqReceiptNumber__c = paymentResult.receipt_number,
      sqReceiptURL__c = paymentResult.receipt_url,
      sqReferenceId__c = paymentResult.reference_id,
      sqStatus__c = 'COMPLETED'
    );
    insert squareTransaction;
    return squareTransaction;
  }

  public static List<AcctSeed__Cash_Receipt__c> createCashReceipts( List<Square_Transaction__c> completedSquareTransactions )
  {
    List<AcctSeed__Cash_Receipt__c> cashReceipts = new List<AcctSeed__Cash_Receipt__c>();
    AcctSeed__Accounting_Period__c[] period =
    [SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, Name, AcctSeed__Status__c
    FROM AcctSeed__Accounting_Period__c
    WHERE AcctSeed__Status__c = 'Open'];
    
    for( Square_Transaction__c sqT : completedSquareTransactions )
    {
      System.debug('Square Transaction Amount = ' + sqT.Amount__c );
      Date rDate = Date.newInstance(
        sqT.sqCreateDate__c.year(),
        sqT.sqCreateDate__c.month(),
        sqT.sqCreateDate__c.day() );
      System.debug( rDate );

      map<Date,AcctSeed__Accounting_Period__c> mapDateToPeriod = new map<Date,AcctSeed__Accounting_Period__c>();
      mapDateToPeriod.put(Date.today(),null);
      GMBLASG.gcAccountingPeriod.mapDateToPeriod(mapDateToPeriod);
      System.debug('mapDateToPeriod');
      System.debug(mapDateToPeriod);

      cashReceipts.add( new AcctSeed__Cash_Receipt__c(
        AcctSeed__Account__c = sqT.Account__c,
        AcctSeed__Amount__c = sqT.Amount__c,
        AcctSeed__Payment_Reference__c = sqT.sqOrderID__c,
        AcctSeed__Purpose__c = 'Customer Receipt',
        AcctSeed__Receipt_Date__c = rDate,
        Payment_Method__c = 'Online Store',
        AcctSeed__Accounting_Period__c = period[0].Id,
        AcctSeed__Ledger__c = gcConstants.idActualLedger
      ));
    }

    System.debug( period );
    insert cashReceipts;
    return cashReceipts;
  }
}