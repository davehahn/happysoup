@isTest
private class JournalEntryTriggerHandler_ar_Test {

	@testSetup static void dataSetup()
	{
		new Factory_TestData();
		Factory_CustomSettings.setupInventorySettings();
	}

	@isTest
	static void trigger_Test() {
	    AcctSeed__Accounting_Period__c p = [SELECT Id FROM AcctSeed__Accounting_Period__c LIMIT 1];
	    AcctSeed__Accounting_Settings__c accSetting = [SELECT AcctSeed__Default_Ledger__c FROM AcctSeed__Accounting_Settings__c ORDER BY CreatedDate][0];

	    AcctSeed__GL_Account__c glA = [SELECT Id
	                               FROM AcctSeed__GL_Account__c
	                               LIMIT 1];

	    AcctSeedERP__Warehouse__c wh = [SELECT Id, Name FROM AcctSeedERP__Warehouse__c LIMIT 1];
	    AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(
	      Name = 'Test Loc',
	      AcctSeedERP__Warehouse__c = wh.Id
	    );
	    insert loc;

	    Account cust = Factory_Account.insertFullPersonAccount('TestFname', 'TestLname');
	    GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.insertFullSerial('Boat','Pontoon','0987654321');
	    Boolean orig = gcProject.disableTrigger;
	    gcProject.disableTrigger = true;
	    AcctSeed__Project__c erp = Factory_ERPOrder.insertRetailBoatSale( cust, wh, DateTime.now(), ser);
	    gcProject.disableTrigger = orig;

		AcctSeed__Journal_Entry__c je = new AcctSeed__Journal_Entry__c(
			Name = 'Test Journal',
	    	AcctSeed__Accounting_Period__c = p.Id,
	    	AcctSeed__Ledger__c = accSetting.AcctSeed__Default_Ledger__c
	    );
	    insert je;

		insert new AcctSeed__Journal_Entry_Line__c(
			AcctSeed__Journal_Entry__c = je.Id,
			AcctSeed__GL_Account__c = glA.Id,
			AcctSeed__Debit__c = 1
		);

		je.Project__c = erp.Id;

		update je;
	}

}