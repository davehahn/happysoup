public without sharing class RetailSalesToolController_dh {
  public class Business {
    public String name;
    public String email;
    public String phone;
    public String fax;
    public String id;
    public String billingStreet;
    public String billingCity;
    public String billingState;
    public String billingStateCode;
    public String billingCountry;
    public String billingCountryCode;
    public String billingPostalCode;
    public String shippingStreet;
    public String shippingCity;
    public String shippingState;
    public String shippingStateCode;
    public String shippingCountry;
    public String shippingCountryCode;
    public String shippingPostalCode;
    public BusinessContact[] contacts;

    public Business() {
    }
    public Business(Account acct) {
      this.id = acct.Id;
      this.name = acct.Name;
      this.email = acct.AccountEmail__c;
      this.phone = acct.Phone;
      this.fax = acct.Fax;
      this.billingStreet = acct.BillingStreet;
      this.billingCity = acct.BillingCity;
      this.billingState = acct.BillingState;
      this.billingStateCode = acct.BillingStateCode;
      this.billingCountry = acct.BillingCountry;
      this.billingCountryCode = acct.BillingCountryCode;
      this.billingPostalCode = acct.BillingPostalCode;
      this.shippingStreet = acct.ShippingStreet;
      this.shippingCity = acct.ShippingCity;
      this.shippingState = acct.ShippingState;
      this.shippingStateCode = acct.ShippingStateCode;
      this.shippingCountry = acct.ShippingCountry;
      this.shippingCountryCode = acct.ShippingCountryCode;
      this.shippingPostalCode = acct.ShippingPostalCode;

      this.contacts = buildContacts(acct.Contacts);
    }

    public Account toAccount() {
      return new Account(
        Id = this.id,
        Name = this.name,
        AccountEmail__c = this.email,
        Phone = this.Phone,
        Fax = this.fax,
        BillingCountry = this.billingCountry,
        BillingCountryCode = this.billingCountryCode,
        BillingStreet = this.billingStreet,
        BillingCity = this.billingCity,
        BillingState = this.billingState,
        BillingStateCode = this.billingStateCode,
        BillingPostalCode = this.billingPostalCode,
        ShippingCountry = this.shippingCountry,
        ShippingCountryCode = this.shippingCountryCode,
        ShippingStreet = this.shippingStreet,
        ShippingCity = this.shippingCity,
        ShippingState = this.shippingState,
        ShippingStateCode = this.shippingStateCode,
        ShippingPostalCode = this.shippingPostalCode
      );
    }

    public void fillCountryAndState() {
      if (this.billingState != null && this.billingStateCode == null) {
        fixState('code', 'billing');
      }
      if (this.billingStateCode != null && this.billingState == null) {
        fixState('state', 'billing');
      }
      if (this.shippingState != null && this.shippingStateCode == null) {
        fixState('code', 'shipping');
      }
      if (this.shippingStateCode != null && this.shippingState == null) {
        fixState('state', 'shipping');
      }
      if (this.billingCountry != null && this.billingCountryCode == null) {
        fixCountry('code', 'billing');
      }
      if (this.billingCountryCode != null && this.billingCountry == null) {
        fixCountry('country', 'billing');
      }
      if (this.shippingCountry != null && this.shippingCountryCode == null) {
        fixCountry('code', 'shipping');
      }
      if (this.shippingCountryCode != null && this.shippingCountry == null) {
        fixCountry('country', 'shipping');
      }
    }

    private void fixState(String missingAttr, String addrType) {
      Schema.DescribeFieldResult fieldResult = User.statecode.getDescribe();
      List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
      for (Schema.PicklistEntry f : ple) {
        if (addrType == 'billing ') {
          if (missingAttr == 'code' && f.getLabel() == this.billingState) {
            this.billingStateCode = f.getValue();
          }
          if (missingAttr == 'state' && f.getValue() == this.billingStateCode) {
            this.billingState = f.getLabel();
          }
        }
        if (addrType == 'shipping ') {
          if (missingAttr == 'code' && f.getLabel() == this.shippingState) {
            this.shippingStateCode = f.getValue();
          }
          if (missingAttr == 'state' && f.getValue() == this.shippingStateCode) {
            this.shippingState = f.getLabel();
          }
        }
      }
    }

    private void fixCountry(String missingAttr, String addrType) {
      Schema.DescribeFieldResult fieldResult = User.Countrycode.getDescribe();
      List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
      for (Schema.PicklistEntry f : ple) {
        if (addrType == 'billing') {
          if (missingAttr == 'code' && f.getLabel() == this.billingCountry) {
            this.billingCountryCode = f.getValue();
          }
          if (missingAttr == 'country' && f.getValue() == this.billingCountryCode) {
            this.billingCountry = f.getLabel();
          }
        }
        if (addrType == 'shipping') {
          if (missingAttr == 'code' && f.getLabel() == this.shippingCountry) {
            this.shippingCountryCode = f.getValue();
          }
          if (missingAttr == 'country' && f.getValue() == this.shippingCountryCode) {
            this.shippingCountry = f.getLabel();
          }
        }
      }
    }

    private BusinessContact[] buildContacts(Contact[] contacts) {
      BusinessContact[] result = new List<BusinessContact>();
      for (Contact c : contacts) {
        result.add(new BusinessContact(c));
      }
      //if( result.size() == 0 )
      //  result.add( new BusinessContact() );
      return result;
    }
  }

  public class BusinessContact {
    public String id;
    public String label;
    public String firstName;
    public String lastName;
    public String phone;
    public String mobilePhone;
    public String email;
    public String title;
    public String contactRoleType;

    public BusinessContact() {
    }
    public BusinessContact(Contact c) {
      this.id = c.Id;
      this.label = c.FirstName + ' ' + c.LastName;
      this.firstName = c.FirstName;
      this.lastName = c.LastName;
      this.phone = c.Phone;
      this.mobilePhone = c.MobilePhone;
      this.email = c.Email;
      this.title = c.Title;
    }

    public Contact toContact(Id acctId) {
      return new Contact(
        Id = this.id,
        AccountId = acctId,
        FirstName = this.firstName,
        LastName = this.lastName,
        Phone = this.phone,
        MobilePhone = this.mobilePhone,
        Email = this.email,
        Title = this.title
      );
    }
  }

  public class OppWrapper {
    public String priceBook;
    public String campaignSource;
    public String leadSource;
    public Date closeDate;
    public OppWrapper() {
      this.priceBook = [
        SELECT Id
        FROM Pricebook2
        WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c
      ]
      .Id;
    }
  }

  public class initWrapper {
    public List<Map<String, String>> preferredLanguage;
    public List<Map<String, String>> relationshipStatus;
    public List<Map<String, String>> towVehicle;
    public List<Map<String, String>> emotionalMotivation;
    public List<Map<String, String>> hobbies;
    public List<Map<String, String>> animals;
    public List<Map<String, String>> priceBooks;
    public List<Map<String, String>> leadSource;
    public List<Map<String, String>> gender;
    public List<OptionGroup> campaigns;
    public OppWrapper opp;

    public initWrapper() {
      this.opp = new OppWrapper();
    }
  }

  public class OptionGroup {
    public String groupName;
    public List<Map<String, String>> options;
    public OptionGroup() {
    }
  }

  @AuraEnabled
  public static String buildSelectOptions() {
    String userType = UserInfo.getUserType();
    System.debug(userType);
    InitWrapper result = new initWrapper();
    result.preferredLanguage = listToMap(LGND_Utilities.getPicklistValues('Account', 'Preferred_Language__c'));
    result.relationshipStatus = listToMap(LGND_Utilities.getPicklistValues('Account', 'Relationship_Status__c'));
    result.towVehicle = listToMap(LGND_Utilities.getPicklistValues('Account', 'Tow_Vehicle__c'));
    result.emotionalMotivation = listToMap(LGND_Utilities.getPicklistValues('Account', 'Emotional_Motivation__c'));
    result.hobbies = listToMap(LGND_Utilities.getPicklistValues('Account', 'Hobbies__c'));
    result.animals = listToMap(LGND_Utilities.getPicklistValues('Account', 'Animals__c'));
    result.priceBooks = fetchPricebooks(userType);
    result.campaigns = fetchCampaignOptions(userType);
    result.leadSource = listToMap(LGND_Utilities.getPicklistValues('Opportunity', 'LeadSource'));
    result.gender = listToMap(LGND_Utilities.getPicklistValues('Account', 'Gender__pc'));

    return JSON.serialize(result);
  }

  @AuraEnabled
  public static String fetchCustomer(String objectId) {
    String result;
    Schema.sObjectType entityType = Id.valueOf(objectId).getSObjectType();
    if (entityType == Account.sObjectType)
      result = fetchPersonAccount(objectId);
    if (entityType == Lead.sObjectType)
      result = fetchLead(objectId);
    if (result == null)
      throw new AuraHandledException('No customer found with supplied Id');
    else
      return result;
  }

  @AuraEnabled
  public static String fetchBusiness(String objectId) {
    return fetchBusinessAccount(objectId);
  }

  @AuraEnabled
  public static String checkDuplicate(String customerJSON) {
    List<Account> listAcc = new List<Account>();
    Customer.Person c = (Customer.Person) JSON.deserialize(customerJSON, Customer.Person.class);
    c.fillCountryAndState();
    Account acct = c.revertToAccount();
    List<Account_Matching_Field__mdt> listFields = queryDuplicateFields();
    if (!listFields.isEmpty()) {
      String query = ' SELECT Id, Name, PersonEmail, Phone, BillingStreet, BillingCity, BillingState, BillingCountry ';
      query += ' FROM Account WHERE ';
      String whereClause = '';
      for (Account_Matching_Field__mdt amf : listFields) {
        if (whereClause == '')
          whereClause += amf.DeveloperName + ' = \'' + acct.get(amf.DeveloperName) + '\'';
        else
          whereClause += ' and ' + amf.DeveloperName + ' = \'' + acct.get(amf.DeveloperName) + '\'';
      }
      query += whereClause;
      System.debug('whereClause');
      System.debug(whereClause);
      System.debug('query');
      System.debug(query);
      for (Account acc : Database.query(query)) {
        listAcc.add(acc);
      }
    }
    return JSON.serialize(listAcc);
  }

  @AuraEnabled
  public static String createSale(String customerJSON, String oppJSON) {
    User u = [SELECT Id, Sales_Department__c FROM User WHERE Id = :UserInfo.getUserId()];
    System.debug(customerJSON);
    Customer.Person c = (Customer.Person) JSON.deserialize(customerJSON, Customer.Person.class);
    c.fillCountryAndState();
    c.setCreateOpportunityOnLeadConvert(true);
    OppWrapper oppFields = (OppWrapper) JSON.deserialize(oppJSON, OppWrapper.class);
    Opportunity opp;

    Customer.AccountSaveResult result = c.upsertRecord();

    if (result.status == 'success') {
      if (result.opportunityId == null) {
        opp = new Opportunity(Name = buildOppName(c.firstName + ' ' + c.lastName), AccountId = result.record.Id);
      } else {
        opp = [SELECT Id, Account.Name FROM Opportunity WHERE Id = :result.opportunityId];
      }
    } else {
      throw new AuraHandledException(result.messages[0]);
    }

    opp.StageName = 'Quoting';
    opp.LeadSource = oppFields.leadSource;
    opp.CampaignId = oppFields.campaignSource == '' ? null : oppFields.campaignSource;
    opp.CloseDate = oppFields.closeDate;
    if (u.Sales_Department__c != null) {
      opp.Sales_Department__c = u.Sales_Department__c;
    }

    try {
      if (opp.Id == null) {
        insert opp;
      }
      if (oppFields.pricebook != null) {
        opp.Pricebook2Id = oppFields.pricebook;
      }
      update opp;
      return opp.Id;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static String createSale_Business(String businessJSON, String oppJSON) {
    User u = [SELECT Id, Sales_Department__c FROM User WHERE Id = :UserInfo.getUserId()];
    Business b = (Business) JSON.deserialize(businessJSON, Business.class);
    b.fillCountryAndState();
    System.debug(b);
    OppWrapper oppFields = (OppWrapper) JSON.deserialize(oppJSON, OppWrapper.class);
    // insert/update Account information
    Account acct = b.toAccount();
    System.debug(acct);
    upsert acct;

    // insert/update contacts
    Map<String, Contact> conts = new Map<String, Contact>();
    for (BusinessContact bc : b.contacts) {
      Contact c = bc.toContact(acct.Id);
      if (bc.contactRoleType == null)
        conts.put('na', c);
      else
        conts.put(bc.contactRoleType, c);
    }
    // throw an error if none of the contacts where set as a buyer
    if (!conts.containsKey('buyer'))
      throw new AuraHandledException('None of the contacts where specified as a Buyer');
    upsert conts.values();

    // Build the Opportunity
    Opportunity opp = new Opportunity(
      Name = buildOppName(acct.Name),
      AccountId = acct.Id,
      StageName = 'Quoting',
      LeadSource = oppFields.leadSource,
      CampaignId = oppFields.campaignSource == '' ? null : oppFields.campaignSource,
      CloseDate = oppFields.closeDate
    );
    if (u.Sales_Department__c != null) {
      opp.Sales_Department__c = u.Sales_Department__c;
    }

    try {
      if (opp.Id == null) {
        insert opp;
      }
      if (oppFields.pricebook != null) {
        opp.Pricebook2Id = oppFields.pricebook;
      }
      update opp;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }

    //Build the OpportunityContactRoles
    OpportunityContactRole[] ocrs = new List<OpportunityContactRole>();
    Contact buyer = conts.get('buyer');
    ocrs.add(
      new OpportunityContactRole(ContactId = buyer.Id, OpportunityId = opp.Id, Role = 'Buyer', isPrimary = true)
    );
    if (conts.containsKey('cobuyer')) {
      ocrs.add(
        new OpportunityContactRole(
          ContactId = conts.get('cobuyer').Id,
          OpportunityId = opp.Id,
          Role = 'Co-Buyer',
          isPrimary = false
        )
      );
    }

    try {
      insert ocrs;
      return opp.Id;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static String buildOppName(String acctName) {
    Datetime today = Datetime.now();
    String nameString = acctName + ' - ';
    nameString += today.format('yyyy.MM.dd-HHmm');
    return nameString;
  }

  private static List<Map<String, String>> fetchPricebooks(String userType) {
    Id pbRT = LGND_Utilities.recordTypeIdFromName('Pricebook2', 'Sales');
    List<Map<String, String>> result = new List<Map<String, String>>();
    if (userType == 'PowerPartner') {
      return result;
    }
    for (PriceBook2 pb : [
      SELECT Id, Name
      FROM Pricebook2
      WHERE IsStandard = FALSE AND IsActive = TRUE AND RecordTypeId = :pbRT
      ORDER BY Name DESC
    ]) {
      result.add(new Map<String, String>{ 'value' => pb.Id, 'label' => pb.Name });
    }
    return result;
  }

  private static Database.LeadConvertResult convertLead(Lead ld) {
    Savepoint sp = Database.setSavepoint();
    try {
      Database.LeadConvert lc = new Database.LeadConvert();
      lc.setLeadId(ld.id);

      LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
      lc.setConvertedStatus(convertStatus.MasterLabel);
      lc.setOpportunityName(buildOppName(ld.FirstName + ' ' + ld.LastName));
      lc.setOwnerId(UserInfo.getUserId());

      Database.LeadConvertResult lcr = Database.convertLead(lc);
      return lcr;
    } catch (Exception e) {
      Database.rollback(sp);
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static optionGroup[] fetchCampaignOptions(String userType) {
    Map<String, List<Map<String, String>>> options = new Map<String, List<Map<String, String>>>();
    List<OptionGroup> result = new List<OptionGroup>();
    List<Campaign> campaigns = [
      SELECT Id, Name, Parent.Name, RecordType.Name
      FROM Campaign
      WHERE isActive = TRUE AND Hidden__c = FALSE AND Status = 'In Progress'
    ];
    for (Campaign c : campaigns) {
      if (userType == 'PowerPartner' && c.RecordType.Name != 'National') {
        System.debug('skipping ' + c.Name + ' beacuse userType is PowerPartner and RecordType is ' + c.RecordType.Name);
        continue;
      }
      String par = c.Parent.Name == null ? 'Standard' : c.Parent.Name;
      if (!options.containsKey(par)) {
        options.put(par, new List<Map<String, String>>());
      }
      options.get(par).add(new Map<String, String>{ 'label' => c.Name, 'value' => c.Id });
    }
    for (String groupName : options.keySet()) {
      OptionGroup og = new OptionGroup();
      og.groupName = groupName;
      og.options = options.get(groupName);
      result.add(og);
    }
    return result;
  }

  private static List<Map<String, String>> listToMap(List<String> options) {
    List<Map<String, String>> result = new List<Map<String, String>>();
    for (String o : options) {
      result.add(new Map<String, String>{ 'label' => o, 'value' => o });
    }
    return result;
  }

  private static String fetchPersonAccount(String acctId) {
    try {
      return JSON.serialize(new Customer.Person(Account_Selector.personAccountById(acctId)));
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static String fetchBusinessAccount(String acctId) {
    try {
      return JSON.serialize(new Business(Account_Selector.businessAccountWithContactsById(acctId)));
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static String fetchLead(String leadId) {
    try {
      Lead theLead = Lead_Selector.byIdIncludingCampaignMembers(leadId);
      Customer.Person thePerson = new Customer.Person(theLead);
      return JSON.serialize(thePerson);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static List<Account_Matching_Field__mdt> queryDuplicateFields() {
    return [SELECT Id, DeveloperName, Wrapper_Field_Name__c FROM Account_Matching_Field__mdt];
  }
}
