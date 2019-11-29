@isTest
private class lgnd_account_search_test {

  private static Account[] partners;
  private static Account[] suppliers;
  private static Account[] people;
  private static Lead[] leads;
  private static Id[] acctIds;
  private static Id[] leadIds;

  static {
    //create 10 Dealer Accounts, 10 Person Accounts, 10 Supplier Accounts and 10 Leads
    partners = new List<Account>();
    people = new List<Account>();
    suppliers = new List<Account>();
    leads = new List<Lead>();
    for( Integer i=0; i<10; i++ )
    {
      people.add( AccountFactory.buildPersonAccount('testCommon-fName'+i, 'lName'+i) );
      partners.add( AccountFactory.buildDealerAccount('testCommon-partnerCo'+i) );
      suppliers.add( AccountFactory.buildSupplierAccount('testCommon-supplier'+i) );
      leads.add( new Lead(
          FirstName = 'testCommon-first'+i,
          LastName = 'last'+i
        )
      );
    }
    insert people;
    insert partners;
    insert suppliers;
    insert leads;
    acctIds = new List<Id>();
    leadIds = new List<Id>();
    for( Account a : people )
    {
      acctIds.add(a.Id);
    }
    for( Account a : partners )
    {
      acctIds.add(a.Id);
    }
    for( Lead l : leads )
    {
      leadIds.add( l.Id );
    }
  }

	@isTest static void searchAccounts_Test() {
    Id[] fixedSearchResults = new List<Id>();
    fixedSearchResults.addAll( acctIds );
    fixedSearchResults.addAll( leadIds );
    Test.setFixedSearchResults(fixedSearchResults);

    List<List<sObject>> all = lgnd_account_search.searchAccounts('test');
    List<List<sObject>> rpartners = lgnd_account_search.searchAccounts('partnerCo');
    List<List<sObject>> rpeople = lgnd_account_search.searchAccounts('fName');
    List<List<sObject>> rleads = lgnd_account_search.searchAccounts('first');

    system.debug( all );
    System.assertEquals( 2, all.size() );
    System.assertEquals( 10, ( all[0].size() + all[1].size() ) );
    System.assert( rpartners[0].size() > 0 );
    System.assert( rpeople[0].size() > 0 );
    System.assert( rleads[1].size() > 0 );
	}

	@isTest static void searchDealerAccounts_Test() {
		List<Account> dealers = lgnd_account_search.searchDealerAccounts('partnerCo');
    System.debug( dealers );
    System.assertEquals( 10, dealers.size() );
	}

  @isTest static void searchSupplierAccounts_Test() {
    List<Account> suppliers = lgnd_account_search.searchSupplierAccounts('supplier');
    System.debug( suppliers );
    System.assertEquals( 10, suppliers.size() );
  }

  @isTest static void search_getAccount_Test() {
    Account a = lgnd_account_search.search_getAccount( people[0].Id );
    System.assertEquals( people[0].Id, a.Id );
  }

  @isTest static void search_getLead_Test() {
    Lead l = lgnd_account_search.search_getLead( leads[0].Id );
    System.assertEquals( leads[0].Id, l.Id );
  }

}