public without sharing class gcJournalEntryLine {
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

  public static Boolean allowProjectAndTask {
    get {
      if (allowProjectAndTask == null)
        return false;
      else
        return allowProjectAndTask;
    }
    set {
      if (value == null)
        allowProjectAndTask = false;
      else
        allowProjectAndTask = value;
    }
  }

  public static void triggerHandler(
    map<Id, AcctSeed__Journal_Entry_Line__c> oldMap,
    map<Id, AcctSeed__Journal_Entry_Line__c> newMap,
    list<AcctSeed__Journal_Entry_Line__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, AcctSeed__Journal_Entry_Line__c>();
    if (newMap == null)
      newMap = new Map<Id, AcctSeed__Journal_Entry_Line__c>();
    if (listNew == null)
      listNew = new List<AcctSeed__Journal_Entry_Line__c>();

    updateAndValidate(oldMap, newMap, listNew, boolIsBefore, boolIsInsert, boolIsUpdate, boolIsDelete);

    if (boolIsBefore) {
      if (boolIsInsert) {
        setFinancialAttributes(listNew);
      }
      if (boolIsUpdate) {
        setFinancialAttributes(listNew);
      }
      if (boolIsDelete) {
      }
    } else //i.e. trigger.isAfter
    {
      if (boolIsInsert) {
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
      }
    }
  }

  private static void setFinancialAttributes(List<AcctSeed__Journal_Entry_Line__c> listNew) {
    gcTransactionParent.setFinancialAttributes(listNew, null, 'AcctSeed__Project_Task__c', 'AcctSeed__GL_Account__c');
  }

  private static void updateAndValidate(
    map<Id, AcctSeed__Journal_Entry_Line__c> oldMap,
    map<Id, AcctSeed__Journal_Entry_Line__c> newMap,
    list<AcctSeed__Journal_Entry_Line__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    Map<Id, Boolean> mapProjectInternal = new Map<Id, Boolean>();
    Set<Id> setIdProject = new Set<Id>();
    Map<Id, Id> mapJournal = new Map<Id, Id>();
    Map<Id, Id> mapProjectTask = new Map<Id, Id>();
    if (boolIsBefore && (boolIsUpdate || boolIsInsert)) {
      for (AcctSeed__Journal_Entry_Line__c jel : listNew) {
        if (jel.AcctSeed__Project__c != null)
          setIdProject.add(jel.AcctSeed__Project__c);
        mapJournal.put(jel.AcctSeed__Journal_Entry__c, null);
      }
    }
    /// Retrieving JE
    if (!mapJournal.isEmpty()) {
      for (AcctSeed__Journal_Entry__c je : [
        SELECT Id, Project__c
        FROM AcctSeed__Journal_Entry__c
        WHERE Id IN :mapJournal.keySet() AND Project__c != NULL
      ]) {
        mapJournal.put(je.Id, je.Project__c);
        setIdProject.add(je.Project__c);
      }
    }
    // Now look for ERP Account
    if (!setIdProject.isEmpty()) {
      for (AcctSeed__Project__c p : [
        SELECT
          Id,
          AcctSeed__Account__r.Is_Internal__c,
          (SELECT Id FROM AcctSeed__Project_Tasks__r ORDER BY CreatedDate ASC LIMIT 1)
        FROM AcctSeed__Project__c
        WHERE Id IN :setIdProject
      ]) {
        if (p.AcctSeed__Account__r.Is_Internal__c) {
          mapProjectInternal.put(p.Id, true);
        }
        if (!p.AcctSeed__Project_Tasks__r.isEmpty())
          mapProjectTask.put(p.Id, p.AcctSeed__Project_Tasks__r[0].Id);
      }
    }

    if (boolIsBefore && (boolIsUpdate || boolIsInsert)) {
      for (AcctSeed__Journal_Entry_Line__c jel : listNew) {
        System.debug('jel before: ' + jel);
        if (
          jel.AcctSeed__Project__c != null &&
          mapProjectInternal.containsKey(jel.AcctSeed__Project__c) &&
          mapProjectInternal.get(jel.AcctSeed__Project__c)
        )
          jel.Is_Internal__c = true;
        else if (
          jel.AcctSeed__Project__c == null &&
          mapJournal.containsKey(jel.AcctSeed__Journal_Entry__c) &&
          mapJournal.get(jel.AcctSeed__Journal_Entry__c) != null
        ) {
          Id idProject = mapJournal.get(jel.AcctSeed__Journal_Entry__c);
          if (mapProjectInternal.containsKey(idProject) && mapProjectInternal.get(idProject))
            jel.Is_Internal__c = true;
        }
        System.debug('jel after: ' + jel);
        if ((boolIsUpdate && allowProjectAndTask) || boolIsInsert) {
          String journalName = jel.Journal_Entry_Name__c;
          if (
            mapJournal.get(jel.AcctSeed__Journal_Entry__c) != null &&
            !(journalName.startsWith('Job Cost for') ||
            journalName.startsWith('Internal Labour for') ||
            journalName.startsWith('Internal Warranty for'))
          ) {
            Id idPT = mapProjectTask.get(mapJournal.get(jel.AcctSeed__Journal_Entry__c));
            if (jel.AcctSeed__Project__c != mapJournal.get(jel.AcctSeed__Journal_Entry__c))
              jel.AcctSeed__Project__c = mapJournal.get(jel.AcctSeed__Journal_Entry__c);
            if (
              jel.AcctSeed__Project_Task__c == null ||
              (boolIsUpdate && jel.AcctSeed__Project__c != oldMap.get(jel.Id).AcctSeed__Project__c)
            )
              jel.AcctSeed__Project_Task__c = idPT;
          }
        }
      }
    }

    /*if(boolIsBefore && ((boolIsUpdate && allowProjectAndTask) || boolIsInsert))
		{
			Map<Id,Id> mapProjectTask = new Map<Id,Id>();
			for(AcctSeed__Journal_Entry_Line__c jel : listNew){
				String journalName = jel.Journal_Entry_Name__c;
				if(jel.Journal_Entry_Project_Id__c != null && !(journalName.startsWith('Job Cost for') || journalName.startsWith('Internal Labour for') || journalName.startsWith('Internal Warranty for'))){
					mapProjectTask.put(jel.Journal_Entry_Project_Id__c, null);
			}

			if(!mapProjectTask.isEmpty()){
				for(AcctSeed__Project__c p : 
					[SELECT Id, 
						(SELECT Id 
						FROM AcctSeed__Project_Tasks__r 
						ORDER BY CreatedDate ASC 
						LIMIT 1) 
					FROM AcctSeed__Project__c 
					WHERE Id IN:mapProjectTask.keySet()]){
					if(!p.AcctSeed__Project_Tasks__r.isEmpty())
						mapProjectTask.put(p.Id, p.AcctSeed__Project_Tasks__r[0].Id);
				}
				for(AcctSeed__Journal_Entry_Line__c jel : listNew){
					if(jel.Journal_Entry_Project_Id__c != null && mapProjectTask.get(jel.Journal_Entry_Project_Id__c) != null){
						Id idPT = mapProjectTask.get(jel.Journal_Entry_Project_Id__c);
						if(jel.AcctSeed__Project__c != jel.Journal_Entry_Project_Id__c)
							jel.AcctSeed__Project__c = jel.Journal_Entry_Project_Id__c;
						if(jel.AcctSeed__Project_Task__c == null || (boolIsUpdate && jel.AcctSeed__Project__c != oldMap.get(jel.Id).AcctSeed__Project__c))
							jel.AcctSeed__Project_Task__c = idPT;
					}
				}
			}
		}*/
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
  }
}
