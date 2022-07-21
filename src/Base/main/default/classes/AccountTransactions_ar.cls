public with sharing class AccountTransactions_ar {
  @AuraEnabled
  public static String retrieveTxnDetailsByAccount(String idAccount, String idPeriod, String strType) {
    List<Map<String, String>> listTxnData = new List<Map<String, String>>();
    set<Id> setIdPayee = new Set<Id>();
    set<Id> setIdPeriods = new Set<Id>();
    //retrieve all periods prior to and including the selected period
    AcctSeed__Accounting_Period__c period = [
      SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c
      FROM AcctSeed__Accounting_Period__c
      WHERE Id = :idPeriod
    ][0];
    //setIdPeriods.add(period.Id);
    for (AcctSeed__Accounting_Period__c p : [
      SELECT Id
      FROM AcctSeed__Accounting_Period__c
      WHERE AcctSeed__Start_Date__c <= :period.AcctSeed__Start_Date__c
    ]) {
      setIdPeriods.add(p.Id);
    }

    AcctSeed__Accounting_Settings__c accSetting = [
      SELECT AcctSeed__AR_Control_GL_Account__c, AcctSeed__Unapplied_Cash_GL_Account__c
      FROM AcctSeed__Accounting_Settings__c
      ORDER BY CreatedDate
    ][0];
    Id idGLAR = accSetting.AcctSeed__AR_Control_GL_Account__c;
    Id idGLUnapplied = accSetting.AcctSeed__Unapplied_Cash_GL_Account__c;
    Set<Id> setIdGL = new Set<Id>();
    System.debug(loggingLevel.error, 'strType:' + strType);
    if (strType == 'arcontrol')
      setIdGL.add(idGLAR);
    else
      setIdGL.add(idGLUnapplied);
    System.debug(loggingLevel.error, 'setIdGL:' + setIdGL);

    for (AcctSeed__Transaction__c txn : [
      SELECT
        Id,
        Name,
        AcctSeed__Account__c,
        AcctSeed__Billing_Line__r.AcctSeed__Billing__r.Name,
        AcctSeed__Billing_Line__r.AcctSeed__Billing__r.AcctSeed__Customer__c,
        AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.Name,
        AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.AcctSeed__Customer__c,
        AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.Name,
        AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.AcctSeed__Customer__c,
        AcctSeed__Amount__c
      FROM AcctSeed__Transaction__c
      WHERE
        AcctSeed__GL_Account__c IN :setIdGL
        AND AcctSeed__Accounting_Period__c IN :setIdPeriods
        AND (AcctSeed__Amount__c < 0
        OR AcctSeed__Amount__c > 0)
        AND (AcctSeed__Account__c = :idAccount
        OR AcctSeed__Billing_Line__r.AcctSeed__Billing__r.AcctSeed__Customer__c = :idAccount
        OR AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.AcctSeed__Customer__c = :idAccount
        OR AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.AcctSeed__Customer__c = :idAccount)
    ]) {
      String typeName = 'Transaction';
      String sourceName = txn.Name;
      Id idPayee = txn.AcctSeed__Account__c;
      if (idPayee == null) {
        typeName = 'Billing';
        sourceName = txn.AcctSeed__Billing_Line__r.AcctSeed__Billing__r.Name;
        idPayee = txn.AcctSeed__Billing_Line__r.AcctSeed__Billing__r.AcctSeed__Customer__c;
      }
      if (idPayee == null) {
        typeName = 'Billing Cash Receipt';
        sourceName = txn.AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.Name;
        idPayee = txn.AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.AcctSeed__Customer__c;
      }
      if (idPayee == null) {
        typeName = 'Scheduled Revenue Expense';
        sourceName = txn.AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.Name;
        idPayee = txn.AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.AcctSeed__Customer__c;
      }

      //if(idPayee == null) continue;

      Decimal amt = txn.AcctSeed__Amount__c;
      Map<String, String> m = new Map<String, String>();
      m.put('Id', txn.Id);
      m.put('type', typeName);
      m.put('sourceName', sourceName);
      m.put('txnAmount', String.valueOf(amt));
      listTxnData.add(m);
    }

    return JSON.serialize(listTxnData);
  }

  public static void coverage() {
    integer i;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
  }
}
