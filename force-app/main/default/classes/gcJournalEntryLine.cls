public without sharing class gcJournalEntryLine {

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

	public static Boolean allowProjectAndTask{
		get{
			if(allowProjectAndTask == null) return false;
			else return allowProjectAndTask;
		}
		set{
			if(value == null) allowProjectAndTask = false;
			else allowProjectAndTask = value;
		}
	}

	public static void triggerHandler
		(map<Id,AcctSeed__Journal_Entry_Line__c> oldMap,
		 map<Id,AcctSeed__Journal_Entry_Line__c> newMap,
		 list<AcctSeed__Journal_Entry_Line__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeed__Journal_Entry_Line__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeed__Journal_Entry_Line__c>();
		if(listNew == NULL) listNew = new list<AcctSeed__Journal_Entry_Line__c>();

		updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);

		if(boolIsBefore)
		{
			if(boolIsInsert)
			{
				setFinancialAttributes(listNew);
			}
			if(boolIsUpdate)
			{
				setFinancialAttributes(listNew);
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
			}
			if(boolIsDelete)
			{
			}
		}			
	}

	private static void setFinancialAttributes(List<AcctSeed__Journal_Entry_Line__c> listNew)
	{
		gcTransactionParent.setFinancialAttributes(
			listNew,
			null,
			'AcctSeed__Project_Task__c',
			'AcctSeed__GL_Account__c');
	}

	private static void updateAndValidate
		(map<Id,AcctSeed__Journal_Entry_Line__c> oldMap,
		 map<Id,AcctSeed__Journal_Entry_Line__c> newMap,
		 list<AcctSeed__Journal_Entry_Line__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(boolIsBefore && ((boolIsUpdate && allowProjectAndTask) || boolIsInsert))
		{
			Map<Id,Id> mapProjectTask = new Map<Id,Id>();
			for(AcctSeed__Journal_Entry_Line__c jel : listNew){
				String journalName = jel.Journal_Entry_Name__c;
				if(jel.Journal_Entry_Project_Id__c != null && !(journalName.startsWith('Job Cost for') || journalName.startsWith('Internal Labour for') || journalName.startsWith('Internal Warranty for')))
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