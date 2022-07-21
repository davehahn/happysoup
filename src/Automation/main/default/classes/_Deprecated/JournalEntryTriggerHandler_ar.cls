/* TODO: DELETE ME */
public without sharing class JournalEntryTriggerHandler_ar {
  //	public static Boolean disableTrigger{
  //		get{
  //			if(disableTrigger == null) return false;
  //			else return disableTrigger;
  //		}
  //		set{
  //			if(value == null) disableTrigger = false;
  //			else disableTrigger = value;
  //		}
  //	}
  //
  //	public static void triggerHandler
  //		(map<Id,AcctSeed__Journal_Entry__c> oldMap,
  //		 map<Id,AcctSeed__Journal_Entry__c> newMap,
  //		 list<AcctSeed__Journal_Entry__c> listNew,
  //		 Boolean boolIsBefore,
  //		 Boolean boolIsInsert,
  //		 Boolean boolIsUpdate,
  //		 Boolean boolIsDelete)
  //	{
  //		if(oldMap == NULL) oldMap = new map<Id,AcctSeed__Journal_Entry__c>();
  //		if(newMap == NULL) newMap = new map<Id,AcctSeed__Journal_Entry__c>();
  //		if(listNew == NULL) listNew = new list<AcctSeed__Journal_Entry__c>();
  //
  //		updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);
  //
  //		if(boolIsBefore)
  //		{
  //			if(boolIsInsert)
  //			{
  //			}
  //			if(boolIsUpdate)
  //			{
  //			}
  //			if(boolIsDelete)
  //			{
  //			}
  //		}
  //		else //i.e. trigger.isAfter
  //		{
  //			if(boolIsInsert)
  //			{
  //			}
  //			if(boolIsUpdate)
  //			{
  //			}
  //			if(boolIsDelete)
  //			{
  //			}
  //		}
  //	}
  //
  //	private static void updateAndValidate
  //		(map<Id,AcctSeed__Journal_Entry__c> oldMap,
  //		 map<Id,AcctSeed__Journal_Entry__c> newMap,
  //		 list<AcctSeed__Journal_Entry__c> listNew,
  //		 Boolean boolIsBefore,
  //		 Boolean boolIsInsert,
  //		 Boolean boolIsUpdate,
  //		 Boolean boolIsDelete)
  //	{
  //		if(boolIsBefore && (boolIsUpdate || boolIsInsert)) {
  //			for (AcctSeed__Journal_Entry__c je : listNew) {
  //				je.AcctSeed__Ledger__c = gcConstants.idActualLedger;
  //			}
  //		}
  //		if(!boolIsBefore && (boolIsUpdate || boolIsInsert))
  //		{
  //			Set<Id> setIdJE = new Set<Id>();
  //			for(AcctSeed__Journal_Entry__c je : listNew){
  //				String journalName = je.Name;
  //				if(je.Project__c != null && (boolIsInsert || (boolIsUpdate && je.Project__c != oldMap.get(je.Id).Project__c)))
  //					setIdJE.add(je.Id);
  //			}
  //
  //			if(!setIdJE.isEmpty()){
  //				List<AcctSeed__Journal_Entry_Line__c> listJEL = new List<AcctSeed__Journal_Entry_Line__c>();
  //				for(AcctSeed__Journal_Entry_Line__c jel : [SELECT Id FROM AcctSeed__Journal_Entry_Line__c WHERE AcctSeed__Journal_Entry__c IN:setIdJE]){
  //					listJEL.add(jel);
  //				}
  //				if(!listJEL.isEmpty()){
  //					Boolean oldV = gcJournalEntryLine.allowProjectAndTask;
  //					gcJournalEntryLine.allowProjectAndTask = true;
  //					update listJEL;
  //					gcJournalEntryLine.allowProjectAndTask = oldV;
  //				}
  //			}
  //		}
  //	}
}
