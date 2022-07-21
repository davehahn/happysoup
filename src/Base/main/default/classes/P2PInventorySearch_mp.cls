public without sharing class P2PInventorySearch_mp {
  public virtual class ResultWrapper {
    public Map<String, List<AccountWrapper>> inventory;
    public List<GroupSelectOpts> boatSelectOptions;

    public ResultWrapper() {
      this.inventory = new Map<String, List<AccountWrapper>>();
      this.boatSelectOptions = new List<GroupSelectOpts>();
    }
  }

  public virtual class GroupSelectOpts implements Comparable {
    public String family;
    public Set<String> options;

    public GroupSelectOpts(String family) {
      this.family = family;
      this.options = new Set<String>();
    }

    public Integer compareTo(Object compareTo) {
      GroupSelectOpts compare = (GroupSelectOpts) compareTo;
      if (family == compare.family)
        return 0;
      if (family > compare.family)
        return 1;
      return -1;
    }
  }

  public virtual class AccountWrapper implements Comparable {
    public Id id;
    public String name;
    public String phone;
    public String email;
    public String street;
    public String city;
    public String state;
    public String country;
    public String postalCode;
    public String photoURL;
    public Boolean inStock = false;
    public Boolean onOrder = false;

    public AccountWrapper(Registration__c reg) {
      this.id = reg.Account__c;
      this.name = reg.Account__r.Name;
      this.phone = reg.Account__r.Phone;
      this.email = reg.Account__r.AccountEmail__c;
      this.street = reg.Account__r.BillingStreet;
      this.city = reg.Account__r.BillingCity;
      this.state = reg.Account__r.BillingState;
      this.country = reg.Account__r.BillingCountry;
      this.postalCode = reg.Account__r.BillingPostalCode;
      this.photoURL = reg.Account__r.PhotoUrl;
      this.inStock = true;
    }

    public AccountWrapper(Dealer_Order_Line__c dol) {
      this.id = dol.Dealer_Order__r.Account__c;
      this.name = dol.Dealer_Order__r.Account__r.Name;
      this.phone = dol.Dealer_Order__r.Account__r.Phone;
      this.email = dol.Dealer_Order__r.Account__r.AccountEmail__c;
      this.street = dol.Dealer_Order__r.Account__r.BillingStreet;
      this.city = dol.Dealer_Order__r.Account__r.BillingCity;
      this.state = dol.Dealer_Order__r.Account__r.BillingState;
      this.country = dol.Dealer_Order__r.Account__r.BillingCountry;
      this.postalCode = dol.Dealer_Order__r.Account__r.BillingPostalCode;
      this.photoURL = dol.Dealer_Order__r.Account__r.PhotoUrl;
      this.onOrder = true;
    }

    public Integer compareTo(Object compareTo) {
      AccountWrapper compareAW = (AccountWrapper) compareTo;
      if (name == compareAW.name)
        return 0;
      if (name > compareAW.name)
        return 1;
      return -1;
    }
  }

  @AuraEnabled
  public static String searchPartnerInventories(Boolean includeFactoryStoresForPartners) {
    Set<String> uniquer = new Set<String>();
    ResultWrapper result = new ResultWrapper();
    Map<String, List<AccountWrapper>> inventory = new Map<String, List<AccountWrapper>>();
    Map<String, GroupSelectOpts> selectOpts = new Map<String, GroupSelectOpts>();
    List<Registration__c> registrations = findRegistrations(includeFactoryStoresForPartners);
    Map<String, List<Dealer_Order_Line__c>> dealerOrderLinesByAccountId = findOnOrderBoats(
      includeFactoryStoresForPartners
    );
    System.debug('^^^ DOLS BY ACCTID ^^^');
    System.debug(dealerOrderLinesByAccountId);
    for (Registration__c reg : registrations) {
      System.debug('Registrations for ' + reg.Account__r.Name + reg.SerialNumber__r.Product_Name__c);
      //add to select options
      if (!selectOpts.containsKey(reg.SerialNumber__r.GMBLASERP__Product__r.Family))
        selectOpts.put(
          reg.SerialNumber__r.GMBLASERP__Product__r.Family,
          new GroupSelectOpts(reg.SerialNumber__r.GMBLASERP__Product__r.Family)
        );
      selectOpts.get(reg.SerialNumber__r.GMBLASERP__Product__r.Family).options.add(reg.SerialNumber__r.Product_Name__c);

      //add to inventory
      if (!inventory.containsKey(reg.SerialNumber__r.Product_Name__c)) {
        inventory.put(reg.SerialNumber__r.Product_Name__c, new List<AccountWrapper>());
      }
      String uniq = String.valueOf(reg.Account__c) + String.valueOf(reg.SerialNumber__r.GMBLASERP__Product__c);
      if (!uniquer.contains(uniq)) {
        uniquer.add(uniq);
        AccountWrapper wrapper = new AccountWrapper(reg);
        System.debug('On Order = ' + dealerOrderLinesByAccountId.containsKey(uniq));
        if (dealerOrderLinesByAccountId.containsKey(uniq)) {
          wrapper.onOrder = true;
          dealerOrderLinesByAccountId.remove(uniq);
        }
        inventory.get(reg.SerialNumber__r.Product_Name__c).add(wrapper);
        System.debug(wrapper);
      }
    }

    if (dealerOrderLinesByAccountId.size() > 0) {
      uniquer = new Set<String>();
      for (String accountProduct : dealerOrderLinesByAccountId.keySet()) {
        for (Dealer_Order_Line__c dol : dealerOrderLinesByAccountId.get(accountProduct)) {
          //add to select options
          if (!selectOpts.containsKey(dol.Product__r.Family))
            selectOpts.put(dol.Product__r.Family, new GroupSelectOpts(dol.Product__r.Family));
          selectOpts.get(dol.Product__r.Family).options.add(dol.Product__r.Name);

          //add to inventory
          if (!inventory.containsKey(dol.Product__r.Name)) {
            inventory.put(dol.Product__r.Name, new List<AccountWrapper>());
          }
          String uniq = String.valueOf(dol.Dealer_Order__r.Account__c) + String.valueOf(dol.Product__c);
          if (!uniquer.contains(uniq)) {
            uniquer.add(uniq);
            AccountWrapper wrapper = new AccountWrapper(dol);
            inventory.get(dol.Product__r.Name).add(wrapper);
          }
        }
      }
    }
    //sort inventory by Account Name
    for (String pName : inventory.keySet()) {
      List<AccountWrapper> aws = inventory.get(pName);
      aws.sort();
      inventory.put(pName, aws);
    }
    result.inventory = inventory;
    result.boatSelectOptions = selectOpts.values();
    result.boatSelectOptions.sort();
    return JSON.serialize(result);
  }

  private static Registration__c[] findRegistrations(Boolean includeFactoryStoresForPartners) {
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
    for (String f : fields) {
      query += ' ' + f + ',';
    }
    query = query.removeEnd(',');
    query += ' FROM Registration__c WHERE Account__r.Type = \'Dealer\'';
    query += ' AND isCurrent__c = true AND SerialNumber__r.Product_Record_Type__c = \'Boat\'';
    if (excludeFactoryStores) {
      query += ' AND Account__r.Is_Internal__c <> true';
    }
    if (cu.AccountId != null)
      query += ' AND Account__c != \'' + cu.AccountId + '\'';
    query += ' ORDER BY SerialNumber__r.Product_Name__c ASC';
    return Database.query(query);
  }

  private static Map<String, List<Dealer_Order_Line__c>> findOnOrderBoats(boolean includeFactoryStoresForPartners) {
    Map<String, List<Dealer_Order_Line__c>> result = new Map<String, List<Dealer_Order_Line__c>>();
    Set<String> ignoreStages = new Set<String>{ 'Draft', 'Delivered', 'Closed Lost' };
    Map<Id, Account> dealers = new Map<Id, Account>(Account_Selector.allActiveDealers());
    List<Dealer_Order_Line__c> dols = [
      SELECT
        Id,
        Erp_Order__r.Stage__c,
        Dealer_Order__r.Account__c,
        Dealer_Order__r.Account__r.Phone,
        Dealer_Order__r.Account__r.Is_Internal__c,
        Dealer_Order__r.Account__r.PhotoUrl,
        Dealer_Order__r.Account__r.AccountEmail__c,
        Dealer_Order__r.Account__r.Name,
        Dealer_Order__r.Account__r.BillingStreet,
        Dealer_Order__r.Account__r.BillingCity,
        Dealer_Order__r.Account__r.BillingState,
        Dealer_Order__r.Account__r.BillingCountry,
        Dealer_order__r.Account__r.BillingPostalCode,
        Product__c,
        Product__r.RecordTypeId,
        Product__r.Family,
        Product__r.Name
      FROM Dealer_Order_Line__c
      WHERE
        ERP_Order__c != NULL
        AND ERP_Order__r.Stage__c NOT IN :ignoreStages
        AND Dealer_Order__r.Account__c = :dealers.keySet()
        AND Product__c != NULL
    ];
    for (Dealer_Order_Line__c dol : dols) {
      if (dol.Dealer_Order__r.Account__r.Is_Internal__c && !includeFactoryStoresForPartners)
        continue;
      String uniq = String.valueOf(dol.Dealer_Order__r.Account__c) + String.valueOf(dol.Product__c);
      if (!result.containsKey(uniq)) {
        result.put(uniq, new List<Dealer_Order_Line__c>());
      }
      result.get(uniq).add(dol);
    }
    return result;
  }
}
