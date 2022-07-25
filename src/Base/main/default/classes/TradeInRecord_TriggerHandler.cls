public with sharing class TradeInRecord_TriggerHandler {
  public static Boolean disableTrigger {
    get {
      if (disableTrigger == null)
        return false;
      else
        return disableTrigger;
    }
    set {
      if (value == null)
        disableTrigger = false;
      else
        disableTrigger = value;
    }
  }

  public static void doHandle(
    Map<Id, Trade_In_Record__c> oldMap,
    Map<Id, Trade_In_Record__c> newMap,
    List<Trade_In_Record__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, Trade_In_Record__c>();
    if (newMap == null)
      newMap = new Map<Id, Trade_In_Record__c>();
    if (listNew == null)
      listNew = new List<Trade_In_Record__c>();

    //Things to do BEFORE
    if (boolIsBefore) {
      if (boolIsInsert) {
        syncIfQuoteIsSyncing(listNew);
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
      }
    } else // well.. if it is not before it has to be AFTER
    {
      if (boolIsInsert) {
        syncAmountsToQuote(listNew, null);
      }
      if (boolIsUpdate) {
        syncAmountsToQuote(listNew, oldMap);
      }
      if (boolIsDelete) {
      }
    }
  }

  private static void syncIfQuoteIsSyncing(List<Trade_In_Record__c> listNew) {
    Set<Id> quoteIds = new Set<Id>();
    for (Trade_In_Record__c tr : listNew) {
      if (tr.Quote__c != null) {
        quoteIds.add(tr.Quote__c);
      }
    }
    Map<Id, Quote> quotesMap = new Map<Id, Quote>([SELECT Id, IsSyncing FROM Quote WHERE Id IN :quoteIds]);
    for (Trade_In_Record__c tr : listNew) {
      if (tr.Quote__c != null && quotesMap.containsKey(tr.Quote__c)) {
        tr.IsSyncing__c = quotesMap.get(tr.Quote__c).IsSyncing;
      }
    }
  }

  private static void syncAmountsToQuote(Trade_In_Record__c[] listNew, Map<Id, Trade_In_Record__c> oldMap) {
    Quote[] quotesToUpdate = new List<Quote>();
    for (Trade_In_Record__c tir : listNew) {
      if (tir.Quote__c != null) {
        Quote q = new Quote(Id = tir.Quote__c);
        q.TradeInAmount__c = tir.Total_Value__c;
        q.TradeInLien__c = tir.Lien_Amount__c;
        quotesToUpdate.add(q);
      }
    }
    if (quotesToUpdate.size() > 0) {
      Boolean orig = Quote_TriggerHandler.disableTrigger;
      Quote_TriggerHandler.disableTrigger = true;
      update quotesToUpdate;
      Quote_TriggerHandler.disableTrigger = orig;
    }
  }
}
