global class batchPricebookClone implements Database.Batchable<sObject> {
	global final String query;
	global final Id newPbId;
	global final String newPbName;

	global batchPricebookClone(Id oldId, Id newId)
	{
		query = LGND_Utilities.getCreatableFieldsSOQL('PricebookEntry', 'Pricebook2Id = \'' + oldId +'\'');
		newPbId = newId;
		newPbName = [SELECT Name FROM Pricebook2 WHERE Id = :newId].Name;
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<PricebookEntry> scope)
	{
		List<PricebookEntry> entries = new List<PricebookEntry>();
		for(PricebookEntry pbe : scope)
		{
			PricebookEntry n = pbe.clone(false, true);
			n.Pricebook2Id = newPbId;
			entries.add(n);
		}
		insert entries;
	}

	global void finish(Database.BatchableContext BC)
	{
		Pricebook2_CloneController_dh.sendBatchCompleteEmail( BC,
                                                          newPbName + ' - cloning Pricebook Entires');
	}

}