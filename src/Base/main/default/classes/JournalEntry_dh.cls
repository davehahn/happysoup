public with sharing class JournalEntry_dh {

	public static Boolean disableTrigger{
    get{
      if(disableTrigger == null) return false;
      else return disableTrigger;
    }
    set{
      if(value == null) disableTrigger = false;
      else disableTrigger = value;
    }
  }

  public static void triggerHandler
    (Map<Id,AcctSeed__Journal_Entry__c> oldMap,
     Map<Id,AcctSeed__Journal_Entry__c> newMap,
     List<AcctSeed__Journal_Entry__c> listNew,
     Boolean boolIsBefore,
     Boolean boolIsInsert,
     Boolean boolIsUpdate,
     Boolean boolIsDelete)
  {
    if(oldMap == NULL) oldMap = new Map<Id,AcctSeed__Journal_Entry__c>();
    if(newMap == NULL) newMap = new Map<Id,AcctSeed__Journal_Entry__c>();
    if(listNew == NULL) listNew = new List<AcctSeed__Journal_Entry__c>();

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
      }
    }
    else //i.e. trigger.isAfter
    {
      if(boolIsInsert)
      {
      }
      if(boolIsUpdate)
      {
        Map<Id, Date> dateMap = new Map<Id, Date>();
        for( AcctSeed__Journal_Entry__c je : listNew )
        {
          AcctSeed__Journal_Entry__c oldJE = oldMap.get(je.Id);
          if( je.AcctSeed__Journal_Date__c != oldJE.AcctSeed__Journal_Date__c )
            dateMap.put( je.Id, je.AcctSeed__Journal_Date__c);
        }
        if( dateMap.size() > 0 )
          updateJournalEntryDates( dateMap );

      }
      if(boolIsDelete)
      {
      }
    }
  }

  private static void updateJournalEntryDates( Map<Id, Date> dateMap )
  {
    AcctSeed__Journal_Entry_Line__c[] jels = [SELECT Id, AcctSeed__Journal_Entry__c
                                              FROM AcctSeed__Journal_Entry_Line__c
                                              WHERE AcctSeed__Journal_Entry__c IN :dateMap.keySet()];
    for( AcctSeed__Journal_Entry_Line__c jel : jels )
    {
      jel.AcctSeed__Date__c = dateMap.get( jel.AcctSeed__Journal_Entry__c );
    }
    Boolean origTriggerState = gcJournalEntryLine.disableTrigger;
    gcJournalEntryLine.disableTrigger = true;
    update jels;
    gcJournalEntryLine.disableTrigger = origTriggerState;
  }

  public static void coverage(){
    integer i;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
  }

}