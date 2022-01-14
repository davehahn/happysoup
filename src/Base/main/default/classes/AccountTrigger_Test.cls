/* TODO: DELETE ME */
@isTest
private class AccountTrigger_Test
{
//
//  private static void init() {
//    Legend_Settings__c ls = new Legend_Settings__c();
//    ls.TriggerEnable_OpportunityTrigger__c = true;
//    ls.TriggerEnable_AccountTrigger__c = true;
//    insert ls;
//    AcctSeed_Settings_Factory.getWarehouse('Whitefish');
//  }
//
//	@isTest
//	static void itShould()
//	{
//		init();
//    Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Account;
//    Map<String,Schema.RecordTypeInfo> AccountRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
//    Id personAccountId = AccountRecordTypeInfo.get('Person Account').getRecordTypeId();
//
//    Account pa = new Account(
//      RecordTypeId = personAccountId,
//      FirstName = 'Fred',
//      LastName = 'Flintstone',
//      PersonEmail = 'fredflintstone@hannabarbara.com'
//    );
//    insert pa;
//
//    Opportunity opp = new Opportunity(
//      Name = 'test person opportunity',
//      CloseDate= Date.today(),
//      StageName='Prospecting',
//      AccountId = pa.id
//    );
//    insert opp;
//
//    opp = [SELECT Id, ContactEmail__c, Name, Account.Id FROM Opportunity WHERE Id = :opp.Id];
//
//    System.assertEquals( 'fredflintstone@hannabarbara.com', opp.ContactEmail__c);
//
//    pa = [SELECT Id, PersonEmail, isPersonAccount FROM Account WHERE Id = :pa.Id];
//    pa.PersonEmail = 'fflintstone@hannabarbara.com';
//    update pa;
//
//    opp = [SELECT Id, ContactEmail__c, Name, Account.Id FROM Opportunity WHERE Id = :opp.Id];
//
//    System.assert(pa.isPersonAccount);
//    System.assertEquals( 'fflintstone@hannabarbara.com', pa.PersonEmail);
//    System.assertEquals( 'fflintstone@hannabarbara.com', opp.ContactEmail__c);
//	}
}