/**
 * Created by Legend on 25/4/22.
 */

public with sharing class AutoPostECWID_CashReceipts implements Schedulable, Database.Batchable<sObject> {
  public AutoPostECWID_CashReceipts() {
  }

  public Database.QueryLocator start(Database.BatchableContext BC) {
    String query = 'SELECT Id FROM AcctSeed__Cash_Receipt__c WHERE GMBLASG__Posted__c = false AND Sales_Order__c != null';
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext BC, List<sObject> scope) {
    List<AcctSeed__Cash_Receipt__c> listCR = new List<AcctSeed__Cash_Receipt__c>();
    for (SObject sObj : scope) {
      AcctSeed__Cash_Receipt__c p = (AcctSeed__Cash_Receipt__c) sObj;
      listCR.add(p);
    }
    if (!listCR.isEmpty())
      AcctSeed.CashReceiptPostService.postCashReceipts(listCR);
  }

  public void execute(SchedulableContext sc) {
    AutoPostECWID_CashReceipts b = new AutoPostECWID_CashReceipts();
    database.executeBatch(b, 1);
  }

  public void finish(Database.BatchableContext BC) {
  }
}
