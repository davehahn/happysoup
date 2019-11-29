public with sharing class Quote_TriggerHandler {

  public static Boolean disableTrigger {
    get{
      if(disableTrigger == null) return false;
      else return disableTrigger;
    }
    set{
      if(value == null) disableTrigger = false;
      else disableTrigger = value;
    }
  }

  public static void doHandle( Map<Id,Quote> oldMap,
                               Map<Id,Quote> newMap,
                               List<Quote> listNew,
                               Boolean boolIsBefore,
                               Boolean boolIsInsert,
                               Boolean boolIsUpdate,
                               Boolean boolIsDelete)
  {
    if(oldMap == NULL) oldMap = new Map<Id,Quote>();
    if(newMap == NULL) newMap = new Map<Id,Quote>();
    if(listNew == NULL) listNew = new List<Quote>();

    //Things to do BEFORE
    if(boolIsBefore)
    {
      if(boolIsInsert)
      {

      }
      if(boolIsUpdate)
      {

      }
      if(boolIsDelete)
      {
         deleteTradeInRecords( oldMap.keySet() );
      }
    }
    else // well.. if it is not before it has to be AFTER
    {
      if(boolIsInsert)
      {

      }
      if(boolIsUpdate)
      {
        syncTradeIn( listNew, oldMap );
      }
      if(boolIsDelete)
      {

      }
    }

  }

  private static void syncTradeIn( Quote[] listNew, Map<Id, Quote> oldMap )
  {
    Map<Id, Quote> changed = new Map<Id, Quote>();
    for( Quote q : listNew )
    {
      if( q.IsSyncing != oldMap.get( q.Id ).IsSyncing )
      {
        changed.put( q.Id, q );
      }
    }
    Trade_In_Record__c[] tirs = [SELECT Id, Total_Value__c, Lien_Amount__c, Quote__c
                                 FROM Trade_In_Record__c
                                 WHERE Quote__c IN :changed.keyset() ];
    for( Trade_In_Record__c tir : tirs )
    {
      tir.IsSyncing__c = changed.get( tir.Quote__c ).IsSyncing;
    }
    update tirs;
  }

  private static void deleteTradeInRecords( Set<Id> qIds )
  {
    delete [SELECT Id FROM Trade_In_Record__c WHERE Quote__c IN :qIds ];
  }

}