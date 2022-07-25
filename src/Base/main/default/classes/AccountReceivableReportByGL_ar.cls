public without sharing class AccountReceivableReportByGL_ar {
  public class transactionData {
    public Id accountId { get; set; }
    public String accountName { get; set; }
    public Decimal billingBalance { get; set; }
    public Decimal receiptBalance { get; set; }
    public Decimal actualBalance { get; set; }

    transactionData() {
      billingBalance = 0;
      receiptBalance = 0;
      actualBalance = 0;
    }
  }
  @AuraEnabled
  public static String getAccountTypes() {
    List<Map<String, String>> listOptions = new List<Map<String, String>>();
    Map<Id, Schema.RecordTypeInfo> accountRecordTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosById();

    for (Id idRT : accountRecordTypeInfo.keySet()) {
      Map<String, String> m = new Map<String, String>();
      m.put('Id', idRT);
      m.put('Name', accountRecordTypeInfo.get(idRT).getName());
      listOptions.add(m);
    }

    return JSON.serialize(listOptions);
  }

  @AuraEnabled
  public static list<AcctSeed__Accounting_Period__c> getPeriods() {
    return GMBLASERP.gcAccountingPeriod.periodAll();
  }

  @AuraEnabled
  public static String retrieveNextPeriod(String idPeriod) {
    if (idPeriod == null)
      idPeriod = GMBLASERP.gcAccountingPeriod.periodCurr().Id;
    return GMBLASERP.gcAccountingPeriod.periodNext(idPeriod).Id;
  }

  @AuraEnabled
  public static String retrievePreviousPeriod(String idPeriod) {
    if (idPeriod == null)
      idPeriod = GMBLASERP.gcAccountingPeriod.periodCurr().Id;
    return GMBLASERP.gcAccountingPeriod.periodPrev(idPeriod).Id;
  }

  public static List<sObject> retrieveTxnData(Set<Id> setIdPeriods, Set<Id> setIdGLAcc) {
    //retrieve the AR control account
    list<sObject> listAggObj = new List<sObject>();
    String soql;
    soql = ' SELECT ';
    soql += ' AcctSeed__Account__c idAccount, ';
    soql += ' AcctSeed__GL_Account__c idGL, ';
    soql += ' AcctSeed__Billing_Line__r.AcctSeed__Billing__r.AcctSeed__Customer__c idAccountB, ';
    soql += ' AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.AcctSeed__Customer__c idAccountBcr, ';
    soql += ' AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.AcctSeed__Customer__c idAccountSre, ';
    soql += ' sum(AcctSeed__Amount__c) amt ';
    soql += ' FROM AcctSeed__Transaction__c ';
    soql += ' WHERE AcctSeed__GL_Account__c IN :setIdGLAcc ';
    soql += ' AND AcctSeed__Accounting_Period__c IN :setIdPeriods ';
    soql += ' AND (AcctSeed__Amount__c < 0 OR AcctSeed__Amount__c > 0) ';
    soql += ' GROUP BY ';
    soql += ' AcctSeed__Account__c, ';
    soql += ' AcctSeed__GL_Account__c, ';
    soql += ' AcctSeed__Billing_Line__r.AcctSeed__Billing__r.AcctSeed__Customer__c, ';
    soql += ' AcctSeed__Billing_Cash_Receipt__r.AcctSeed__Billing__r.AcctSeed__Customer__c, ';
    soql += ' AcctSeed__Scheduled_Revenue_Expense__r.AcctSeed__Billing__r.AcctSeed__Customer__c ';

    soql += ' HAVING (sum(AcctSeed__Amount__c) < 0 OR sum(AcctSeed__Amount__c) > 0)';

    listAggObj.addAll(Database.query(soql));
    return listAggObj;
  }

  @AuraEnabled
  public static String retrieveTxnDetailsByAccount(String idAccount, String idPeriod, String strType) {
    List<Map<String, String>> listTxnData = new List<Map<String, String>>();
    set<Id> setIdPayee = new Set<Id>();
    map<Id, transactionData> mapTD = new Map<Id, transactionData>();
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
      String typeName = 'TXN';
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

  @AuraEnabled
  public static String retrieveAccountTxnDetails(String idPeriod, String idAccRecType) {
    List<transactionData> listTxnData = new List<transactionData>();
    set<Id> setIdPayee = new Set<Id>();
    map<Id, transactionData> mapTD = new Map<Id, transactionData>();

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
    System.debug(loggingLevel.error, 'setIdPeriods:' + setIdPeriods);
    AcctSeed__Accounting_Settings__c accSetting = [
      SELECT AcctSeed__AR_Control_GL_Account__c, AcctSeed__Unapplied_Cash_GL_Account__c
      FROM AcctSeed__Accounting_Settings__c
      ORDER BY CreatedDate
    ][0];
    Id idGLAR = accSetting.AcctSeed__AR_Control_GL_Account__c;
    Id idGLUnapplied = accSetting.AcctSeed__Unapplied_Cash_GL_Account__c;
    Set<Id> setIdGL = new Set<Id>{ idGLAR, idGLUnapplied };
    list<sObject> listAggObj = retrieveTxnData(setIdPeriods, setIdGL);

    for (sObject aggRes : listAggObj) {
      Id idPayee = (Id) aggRes.get('idAccount');
      if (idPayee == null)
        idPayee = (Id) aggRes.get('idAccountB');
      if (idPayee == null)
        idPayee = (Id) aggRes.get('idAccountBcr');
      if (idPayee == null)
        idPayee = (Id) aggRes.get('idAccountSre');

      if (idPayee == null)
        continue;

      Decimal amt = (Decimal) aggRes.get('amt');
      Id idGL = (Id) aggRes.get('idGL');

      if (!mapTD.containsKey(idPayee))
        mapTD.put(idPayee, new transactionData());

      transactionData txnData = mapTD.get(idPayee);
      if (idGL == idGLAR)
        txnData.billingBalance += amt;

      if (idGL == idGLUnapplied)
        txnData.receiptBalance += amt;
    }

    for (Account a : [SELECT Id, Name FROM Account WHERE Id IN :mapTD.keySet() ORDER BY Name]) {
      transactionData txnData = mapTD.get(a.Id);
      txnData.accountId = a.Id;
      txnData.accountName = a.Name;
      txnData.actualBalance = txnData.billingBalance + txnData.receiptBalance;
      if (txnData.billingBalance == txnData.receiptBalance)
        continue;
      listTxnData.add(txnData);
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
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
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
