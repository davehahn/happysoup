@isTest
private class lgnd_account_createForm_Test {

	@isTest static void createLeadAndConvert_Test() {
    //OpportunityTriggerHandler.disableTrigger = true;
    MetadataTriggerHandler.bypass('Opportunity');
        Test.startTest();
    TriggerBase.bypass('Lead');
		Account acct = lgnd_account_createForm.createLeadAndConvert(
      'Dingus',
      'McPhlappypants',
      'dingdong@noemail.com',
      '123-123-1234',
      '123 Somewhere Street',
      'Somewhereville',
      'Ontario',
      'ON',
      'Canada',
      'CA',
      'A1A 1A1',
      '123-987-5647'
    );
    TriggerBase.clearBypass('Lead');
    Test.stopTest();
    Opportunity[] opps = [SELECT Id FROM Opportunity WHERE AccountId = :acct.Id];
    Lead ld = [SELECT Id, IsConverted
               FROM Lead
               WHERE FirstName = 'Dingus'
               AND LastName = 'McPhlappypants'
               LIMIT 1];
    System.assertNotEquals( null, acct.Id );
    System.assertEquals( true, ld.IsConverted );
    System.assertEquals( 0, opps.size() );
	}

  @isTest static void createAccount_Test()
  {
    Account acct = lgnd_account_createForm.createAccount(
      'Dingus',
      'McPhlappypants',
      'dingdong@noemail.com',
      '123-123-1234',
      '123 Somewhere Street',
      'Somewhereville',
      'Ontario',
      'ON',
      'Canada',
      'CA',
      'A1A 1A1',
      '123-987-5647'
    );

    System.assertNotEquals(null, acct.Id);
  }

}