@isTest
public class Factory_Contact {
	public static Contact buildContact( Id acctId, String firstName, String lastName, String email ) {
		Contact c = new Contact(
			AccountId = acctId,
			FirstName = firstName,
			LastName = lastName,
			Email = email
		);
		insert c;
		Profile p = [SELECT Id FROM Profile WHERE Name = 'Legend Partner' LIMIT 1];
		User u = new User(
			ContactId = c.Id,
			Email = email,
			Username = firstName.deleteWhiteSpace() + '_' + email,
			ProfileId = p.Id,
			LastName = lastName,
			Alias = 'abcde',
			TimeZoneSidKey = 'America/New_York',
			LocaleSidKey = 'en_CA',
			EmailEncodingKey = 'ISO-8859-1',
			LanguageLocaleKey = 'en_US'
		);
		insert u;
		return c;
	}

	public static Contact newContact( Id acctId, String firstName, String lastName ) {
		return new Contact(
			AccountId = acctId,
			FirstName = firstName,
			LastName = lastName,
			Email = firstName + '@testcompany.com'
		);
	}

}