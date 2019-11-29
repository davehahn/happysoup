public class lgnd_account_search {
	@AuraEnabled
	public static List<List<sObject>> searchAccounts(String query) {
		System.debug(query);
		Id rtId = LGND_Utilities.recordTypeIdFromName('Account', 'Person Account');
		List<List<sObject>> accounts = [FIND :query IN ALL FIELDS RETURNING Account(Name, BillingAddress, Phone WHERE RecordTypeId = :rtId), Lead(Name, Address, Phone) LIMIT 10];
		return accounts;
	}

	@AuraEnabled
	public static List<Account> searchDealerAccounts(String query) {
		String dealerQuery = '%' + query + '%';
		Id rtId = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer');
		return findAccounts( dealerQuery, rtId );
	}

	@AuraEnabled
	public static List<Account> searchBusinessAccounts(String query) {
	  query = '%' + query + '%';
		Id rtId = LGND_Utilities.recordTypeIdFromName('Account', 'Business Account');
		return findAccounts( query, rtId );
	}

	@AuraEnabled
	public static List<Account> searchSupplierAccounts(String query) {
		String suplierQuery = '%' + query + '%';
		Id rtId = LGND_Utilities.recordTypeIdFromName('Account', 'Supplier');
		return findAccounts( suplierQuery, rtId );
	}

	@AuraEnabled
	public static Account search_getAccount(String accountId) {
		System.debug(accountId);
		Account account = [SELECT Name, BillingAddress, Phone, PersonEmail FROM Account WHERE Id=:accountId LIMIT 1];
		return account;
	}

	@AuraEnabled
	public static Lead search_getLead(String accountId) {
		Lead lead = [SELECT Name, Address, Phone, Email FROM Lead WHERE Id=:accountId LIMIT 1];
		System.debug(lead);
		return lead;
	}

	private static Account[] findAccounts( String query, Id rtId )
	{
		return [ SELECT Name, BillingAddress, Phone FROM Account WHERE RecordTypeId = :rtId AND Name like :query LIMIT 10];
	}
}