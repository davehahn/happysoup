public without sharing class P2PInventorySearch_mp {

	public virtual class ResultWrapper {
		public Map<String, List<AccountWrapper>> inventory;
		public List<GroupSelectOpts> boatSelectOptions;

		public ResultWrapper()
		{
			this.inventory = new Map<String, List<AccountWrapper>>();
			this.boatSelectOptions = new List<GroupSelectOpts>();
		}
	}

	public virtual class GroupSelectOpts implements Comparable{
		public String family;
		public Set<String> options;

		public GroupSelectOpts( String family )
		{
			this.family = family;
			this.options = new Set<String>();
		}

		public Integer compareTo( Object compareTo )
    {
      GroupSelectOpts compare = (GroupSelectOpts)compareTo;
      if( family == compare.family ) return 0;
      if( family > compare.family ) return 1;
      return -1;
    }
	}

	public virtual class AccountWrapper implements Comparable {
		public String name;
		public String phone;
		public String email;
		public String street;
		public String city;
		public String state;
		public String country;
		public String postalCode;
		public String photoURL;

		public AccountWrapper( Registration__c reg )
		{
			this.name = reg.Account__r.Name;
			this.phone = reg.Account__r.Phone;
			this.email = reg.Account__r.AccountEmail__c;
			this.street = reg.Account__r.BillingStreet;
			this.city = reg.Account__r.BillingCity;
			this.state = reg.Account__r.BillingState;
			this.country = reg.Account__r.BillingCountry;
			this.postalCode = reg.Account__r.BillingPostalCode;
			this.photoURL = reg.Account__r.PhotoUrl;
		}

		public Integer compareTo( Object compareTo )
    {
      AccountWrapper compareAW = (AccountWrapper)compareTo;
      if( name == compareAW.name ) return 0;
      if( name > compareAW.name ) return 1;
      return -1;
    }
	}

	@AuraEnabled
	public static String searchPartnerInventories( Boolean includeFactoryStoresForPartners) {
		Set<String> uniquer = new Set<String>();
		ResultWrapper result = new ResultWrapper();
		Map<String, List<AccountWrapper>> inventory = new Map<String, List<AccountWrapper>>();
		Map<String, GroupSelectOpts> selectOpts = new Map<String, GroupSelectOpts>();
		for (Registration__c reg : findRegistrations( includeFactoryStoresForPartners ) )
		{
			//add to select options
			if( !selectOpts.containsKey( reg.SerialNumber__r.GMBLASERP__Product__r.Family ) )
				selectOpts.put( reg.SerialNumber__r.GMBLASERP__Product__r.Family, new GroupSelectOpts( reg.SerialNumber__r.GMBLASERP__Product__r.Family ) );
			selectOpts.get( reg.SerialNumber__r.GMBLASERP__Product__r.Family ).options.add( reg.SerialNumber__r.Product_Name__c );

			//add to inventory
			if ( !inventory.containsKey(reg.SerialNumber__r.Product_Name__c) )
			{
				inventory.put(reg.SerialNumber__r.Product_Name__c, new List<AccountWrapper>() );
			}
			String uniq = String.valueOf(reg.Account__c) + String.valueOf(reg.SerialNumber__r.GMBLASERP__Product__c);
			if( !uniquer.contains( uniq ) )
			{
				uniquer.add( uniq );
				inventory.get(reg.SerialNumber__r.Product_Name__c).add( new AccountWrapper( reg ) );
			}

		}
		//sort inventory by Account Name
		for( String pName : inventory.keySet() )
		{
			List<AccountWrapper> aws = inventory.get(pName);
			aws.sort();
			inventory.put(pName, aws);
		}
		result.inventory = inventory;
		result.boatSelectOptions = selectOpts.values();
		result.boatSelectOptions.sort();
		return JSON.serialize( result );
	}

	private static Registration__c[] findRegistrations( Boolean includeFactoryStoresForPartners )
	{
		User cu = [SELECT Id, AccountId, Account.Is_Internal__c FROM User WHERE Id = :UserInfo.getUserId()];
		Boolean excludeFactoryStores = cu.Account.Is_Internal__c ? false : !includeFactoryStoresForPartners;

		String[] fields = new List<String>{
			'Account__c',
			'Account__r.Phone',
			'Account__r.PhotoUrl',
			'Account__r.AccountEmail__c',
			'Account__r.Name',
			'Account__r.BillingStreet',
			'Account__r.BillingCity',
			'Account__r.BillingState',
			'Account__r.BillingCountry',
			'Account__r.BillingPostalCode',
			'SerialNumber__r.GMBLASERP__Product__c',
			'SerialNumber__r.GMBLASERP__Product__r.Family',
			'SerialNumber__r.Product_Name__c'
		};
		String query = 'SELECT';
		for( String f : fields )
		{
			query += ' ' + f + ',';
		}
		query = query.removeEnd(',');
		query += ' FROM Registration__c WHERE Account__r.Type = \'Dealer\'';
		query += ' AND isCurrent__c = true AND SerialNumber__r.Product_Record_Type__c = \'Boat\'';
		if( excludeFactoryStores )
		{
			query += ' AND Account__r.Is_Internal__c <> true';
		}
		if( cu.AccountId != null )
			query += ' AND Account__c != \'' + cu.AccountId + '\'';
		query += ' ORDER BY SerialNumber__r.Product_Name__c ASC';
		return Database.query(query);
	}
}