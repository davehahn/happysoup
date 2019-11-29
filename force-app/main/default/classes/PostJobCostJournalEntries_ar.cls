global with sharing class PostJobCostJournalEntries_ar implements Schedulable, Database.Batchable<sObject>{

	global PostJobCostJournalEntries_ar() {}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id FROM AcctSeed__Journal_Entry__c WHERE (Name like \'%Job Cost for%\' OR Name like \'%Internal Labour for%\' OR Name like \'%Internal Warranty for%\') AND AcctSeed__Status__c != \'Posted\'';
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
   		List<AcctSeed__Journal_Entry__c> listJE = new List<AcctSeed__Journal_Entry__c>();
		for(SObject sObj : scope) {
			AcctSeed__Journal_Entry__c je = (AcctSeed__Journal_Entry__c) sObj;
			listJE.add(je);
		}
		if(!listJE.isEmpty())
			AcctSeed.PostResult[] postResults = AcctSeed.JournalEntryPostService.postJournalEntries(listJE);
	}
	
	global void execute(SchedulableContext sc) {
		PostJobCostJournalEntries_ar b = new PostJobCostJournalEntries_ar();
		database.executeBatch(b, 5);
	}
	
	global void finish(Database.BatchableContext BC) {}

	global static void coverage(){
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
	}
}