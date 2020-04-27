public without sharing class RetailSalesToolController_dh
{

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

    public Business(){}
    public Business( Account acct )
    {
      this.id = acct.Id;
      this.name = acct.Name;
      this.email = acct.AccountEmail__c;
      this.phone = acct.Phone;
      this.fax = acct.Fax;
      this.billingStreet = acct.BillingStreet;
      this.billingCity = acct.BillingCity;
      this.billingState  = acct.BillingState ;
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

      this.contacts = buildContacts( acct.Contacts );
    }

    public Account toAccount()
    {
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
        BillingState  = this.billingState,
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

    public void fillCountryAndState()
    {
      if( this.billingState != null && this.billingStateCode == null )
      {
        fixState('code', 'billing');
      }
      if( this.billingStateCode != null && this.billingState == null )
      {
        fixState('state', 'billing');
      }
      if( this.shippingState != null && this.shippingStateCode == null )
      {
        fixState('code', 'shipping');
      }
      if( this.shippingStateCode != null && this.shippingState == null )
      {
        fixState('state', 'shipping');
      }
      if( this.billingCountry != null && this.billingCountryCode == null )
      {
        fixCountry('code', 'billing');
      }
      if( this.billingCountryCode != null && this.billingCountry == null )
      {
        fixCountry('country', 'billing');
      }
      if( this.shippingCountry != null && this.shippingCountryCode == null )
      {
        fixCountry('code', 'shipping');
      }
      if( this.shippingCountryCode != null && this.shippingCountry == null )
      {
        fixCountry('country', 'shipping');
      }
    }

    private void fixState( String missingAttr, String addrType )
    {
      Schema.DescribeFieldResult fieldResult = User.statecode.getDescribe();
      List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
      for( Schema.PicklistEntry f : ple) {
        if( addrType == 'billing ')
        {
          if( missingAttr == 'code' && f.getLabel() == this.billingState )
          {
            this.billingStateCode = f.getValue();
          }
          if( missingAttr == 'state' && f.getValue() == this.billingStateCode )
          {
            this.billingState = f.getLabel();
          }
        }
        if( addrType == 'shipping ')
        {
          if( missingAttr == 'code' && f.getLabel() == this.shippingState )
          {
            this.shippingStateCode = f.getValue();
          }
          if( missingAttr == 'state' && f.getValue() == this.shippingStateCode )
          {
            this.shippingState = f.getLabel();
          }
        }
      }
    }

    private void fixCountry( String missingAttr, String addrType )
    {
      Schema.DescribeFieldResult fieldResult = User.Countrycode.getDescribe();
      List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
      for( Schema.PicklistEntry f : ple) {
        if( addrType == 'billing' )
        {
          if( missingAttr == 'code' && f.getLabel() == this.billingCountry )
          {
            this.billingCountryCode = f.getValue();
          }
          if( missingAttr == 'country' && f.getValue() == this.billingCountryCode )
          {
            this.billingCountry = f.getLabel();
          }
        }
        if( addrType == 'shipping' )
        {
          if( missingAttr == 'code' && f.getLabel() == this.shippingCountry )
          {
            this.shippingCountryCode = f.getValue();
          }
          if( missingAttr == 'country' && f.getValue() == this.shippingCountryCode )
          {
            this.shippingCountry = f.getLabel();
          }
        }
      }
    }

    private BusinessContact[] buildContacts( Contact[] contacts )
    {
      BusinessContact[] result = new List<BusinessContact>();
      for( Contact c : contacts )
      {
        result.add( new BusinessContact(c) );
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

    public BusinessContact()
    {
    }
    public BusinessContact( Contact c )
    {
      this.id = c.Id;
      this.label = c.FirstName + ' ' + c.LastName;
      this.firstName = c.FirstName;
      this.lastName = c.LastName;
      this.phone = c.Phone;
      this.mobilePhone = c.MobilePhone;
      this.email = c.Email;
      this.title = c.Title;
    }

    public Contact toContact( Id acctId )
    {
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

  public class Customer {
    public String id { get; set; }
    public String firstName { get; set; }
    public String lastName { get; set; }
    public String email { get; set; }
    public String phone { get; set; }
    public String gender { get; set; }
    public String mobilePhone { get; set; }
    public Boolean isTaxExempt { get; set; }
    public String taxExemptNumber { get; set; }

    public String street { get; set; }
    public String city { get; set; }
    public String state { get; set; }
    public String stateCode { get; set; }
    public String country { get; set; }
    public String countryCode { get; set; }
    public String postalCode { get; set; }

    public String preferredLanguage { get; set; }
    public String relationshipStatus { get; set; }
    public Decimal numberOfChildren { get; set; }
    public String occupation { get; set; }
    public String towVehicle { get; set; }

    public String[] emotionalMotivation { get; set; }
    public String[] hobbies { get; set; }
    public String[] animals { get; set; }
    public String teams { get; set; }

    public String wowNotes { get; set; }


    public Customer(){}
    public Customer( Account acct )
    {
      this.id = acct.Id;
      this.firstName = acct.FirstName;
      this.lastName = acct.LastName;
      this.email = acct.PersonEmail;
      this.phone = formatPhoneNumber( acct.Phone );
      this.mobilePhone = formatPhoneNumber( acct.PersonMobilePhone );
      this.gender = acct.Gender__pc;
      this.isTaxExempt = acct.Tax_Exempt_Status_Card_Number__pc != null;

      this.street = acct.BillingStreet;
      this.city = acct.BillingCity;
      this.state = acct.BillingState;
      this.stateCode = acct.BillingStateCode;
      this.country = acct.BillingCountry;
      this.countryCode = acct.BillingCountryCode;
      this.postalCode = acct.BillingPostalCode;

      this.preferredLanguage = acct.Preferred_Language__c == null ? 'English' : acct.Preferred_Language__c;
      this.relationShipStatus = acct.Relationship_Status__c;
      this.numberOfChildren = acct.Number_Of_Children__c == null ? 0 : acct.Number_Of_Children__c;
      this.occupation = acct.Occupation__c;
      this.towVehicle = acct.Tow_Vehicle__c;

      this.emotionalMotivation = acct.Emotional_Motivation__c == null ? null : acct.Emotional_Motivation__c.split(';');
      this.hobbies = acct.Hobbies__c == null ? null : acct.Hobbies__c.split(';');
      this.animals = acct.Animals__c == null ? null : acct.Animals__c.split(';');
      this.teams = acct.Teams__c;

      this.wowNotes = acct.WOW_Notes__pc;
    }

    public Customer( Lead l )
    {
      this.id = l.Id;
      this.firstName = l.FirstName;
      this.lastName = l.LastName;
      this.email = l.Email;
      this.phone = l.Phone;
      this.mobilePhone = l.MobilePhone;
      this.preferredLanguage = l.Preferred_Language__c;
      this.numberOfChildren = 0;
      this.isTaxExempt = false;
    }

    public void fillCountryAndState()
    {
      if( this.state != null && this.stateCode == null )
      {
        fixState('code');
      }
      if( this.stateCode != null && this.state == null )
      {
        fixState('state');
      }
      if( this.country != null && this.countryCode == null )
      {
        fixCountry('code');
      }
      if( this.countryCode != null && this.country == null )
      {
        fixCountry('country');
      }
    }

    private void fixState( String missingAttr )
    {
      Schema.DescribeFieldResult fieldResult = User.statecode.getDescribe();
      List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
      for( Schema.PicklistEntry f : ple) {
        if( missingAttr == 'code' && f.getLabel() == this.state )
        {
          this.stateCode = f.getValue();
        }
        if( missingAttr == 'state' && f.getValue() == this.stateCode )
        {
          this.state = f.getLabel();
        }
      }
    }

    private void fixCountry( String missingAttr )
    {
      Schema.DescribeFieldResult fieldResult = User.Countrycode.getDescribe();
      List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
      for( Schema.PicklistEntry f : ple) {
        if( missingAttr == 'code' && f.getLabel() == this.country )
        {
          this.countryCode = f.getValue();
        }
        if( missingAttr == 'country' && f.getValue() == this.countryCode )
        {
          this.country = f.getLabel();
        }
      }
    }

    public Account revertToAccount()
    {
      return new Account(
        Id = this.id,
        FirstName = this.firstName,
        LastName = this.lastName,
        PersonEmail = this.email,
        Phone = this.phone,
        PersonMobilePhone = this.mobilePhone,
        Gender__pc = this.gender,
        Tax_Exempt_Status_Card_Number__pc = this.taxExemptNumber,
        BillingCountry = this.country,
        BillingCountryCode = this.countryCode,
        BillingStreet = this.street,
        BillingCity = this.city,
        BillingState = this.state,
        BillingStateCode = this.stateCode,
        BillingPostalCode = this.postalCode,
        Preferred_Language__c = this.preferredLanguage,
        Relationship_Status__c = this.relationshipStatus,
        Number_Of_Children__c = this.numberOfChildren,
        Occupation__c = this.occupation,
        Tow_Vehicle__c = this.towVehicle,
        Emotional_Motivation__c = this.emotionalMotivation == null ? null : String.join(this.emotionalMotivation, ';'),
        Hobbies__c = this.hobbies == null ? null : String.join(this.hobbies, ';'),
        Animals__c = this.animals == null ? null : String.join(this.animals, ';'),
        Teams__c = this.teams,
        WOW_Notes__pc = this.wowNotes
      );
    }

    public Lead revertToLead()
    {
      Lead l = new Lead(
        FirstName = this.firstName,
        LastName = this.lastName,
        Email = this.email,
        Phone = this.phone,
        MobilePhone = this.mobilePhone,
        Preferred_Language__c = this.preferredLanguage
      );
      if( this.id != null )
        l.Id = this.Id;
      return l;
    }

    private String formatPhoneNumber( String pn )
    {
      if( pn == null )
        return null;
      pn = pn.replaceAll('[^0-9]','');
      return pn.substring(0,3) + '-' + pn.substring(3,6) + '-' + pn.substring(6);
    }
  }

  public class OppWrapper {
    public String priceBook;
    public String campaignSource;
    public String leadSource;
    public Date closeDate;
    public OppWrapper(){
      this.priceBook = [SELECT Id FROM Pricebook2 WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c].Id;
    }
  }

  public Class initWrapper {
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

    public initWrapper(){
      this.opp = new OppWrapper();
    }
  }

  public class OptionGroup {
    public String groupName;
    public List<Map<String, String>> options;
    public OptionGroup(){}
  }

  @AuraEnabled
  public static String buildSelectOptions()
  {
    String userType = UserInfo.getUserType();
    System.debug( userType );
    InitWrapper result = new initWrapper();
    result.preferredLanguage = listToMap(
      LGND_Utilities.getPicklistValues('Account', 'Preferred_Language__c') );
    result.relationshipStatus = listToMap(
      LGND_Utilities.getPicklistValues('Account', 'Relationship_Status__c') );
    result.towVehicle = listToMap(
      LGND_Utilities.getPicklistValues('Account', 'Tow_Vehicle__c') );
    result.emotionalMotivation = listToMap(
      LGND_Utilities.getPicklistValues('Account', 'Emotional_Motivation__c') );
    result.hobbies = listToMap(
      LGND_Utilities.getPicklistValues('Account', 'Hobbies__c') );
    result.animals = listToMap(
      LGND_Utilities.getPicklistValues('Account', 'Animals__c') );
    result.priceBooks = fetchPricebooks( userType );
    result.campaigns = fetchCampaignOptions( userType );
    result.leadSource = listToMap(
      LGND_Utilities.getPicklistValues('Opportunity', 'LeadSource') );
    result.gender = listToMap(
      LGND_Utilities.getPicklistValues('Account', 'Gender__pc') );

    return JSON.serialize( result );
  }

  @AuraEnabled
  public static String fetchCustomer( String objectId )
  {
    Schema.sObjectType entityType = Id.valueOf(objectId).getSObjectType();
    if( entityType == Account.sObjectType )
      return fetchPersonAccount( objectId );
    if( entityType == Lead.sObjectType )
      return fetchLead( objectId );
    return null;
  }

  @AuraEnabled
  public static String fetchBusiness( String objectId )
  {
    return fetchBusinessAccount( objectId );
  }

  @AuraEnabled
  public static String checkDuplicate( String customerJSON)
  {
    List<Account> listAcc = new List<Account>();
    Customer c = (Customer)JSON.deserialize( customerJSON, Customer.class );
    c.fillCountryAndState();
    Account acct = c.revertToAccount();
    List<Account_Matching_Field__mdt> listFields = queryDuplicateFields();
    if(!listFields.isEmpty()) {
      String query = ' SELECT Id, Name, PersonEmail, Phone, BillingStreet, BillingCity, BillingState, BillingCountry ';
      query += ' FROM Account WHERE ';
      String whereClause = '';
      for (Account_Matching_Field__mdt amf : listFields) {
        if(whereClause == '')
            whereClause += amf.DeveloperName + ' = \'' + acct.get(amf.DeveloperName) + '\'';
        else
            whereClause += ' and ' + amf.DeveloperName + ' = \'' + acct.get(amf.DeveloperName)  + '\'';
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
  public static String createSale( String customerJSON, String oppJSON )
  {
    User u = [SELECT Id, Sales_Department__c FROM User WHERE Id = :UserInfo.getUserId()];
    System.debug( customerJSON );
    Customer c = (Customer)JSON.deserialize( customerJSON, Customer.class );
    c.fillCountryAndState();
    OppWrapper oppFields = (OppWrapper)JSON.deserialize( oppJSON, OppWrapper.class);
    Opportunity opp;
    Schema.sObjectType entityType = c.id == null ? null : Id.valueOf(c.id).getSObjectType();
    System.debug('entityType:'+entityType);
    if(entityType == Lead.sObjectType)
    {
      Lead ld = c.revertToLead();
      upsert ld;
      Database.LeadConvertResult lcr = convertLead(ld);
      if( lcr.isSuccess() )
      {
        opp = [SELECT Id, Account.Name FROM Opportunity WHERE Id = :lcr.getOpportunityId() ];
        c.id = lcr.getAccountId();
        //save the extra details on the account;
        Account acct = c.revertToAccount();
        update acct;
      }
    }
    else if( entityType == null || entityType == Account.sObjectType )
    {
//      try {
        Account acct = c.revertToAccount();
        System.debug(acct);
        upsert acct;
        opp = new Opportunity(
            Name = buildOppName(c.firstName + ' ' + c.lastName),
            AccountId = acct.Id
        );
//      }catch(Exception e){
//        if(e.getMessage().contains('DUPLICATES_DETECTED')){
//
//        }
//      }
    }
    else {
      throw new AuraHandledException('The Id specified must be either a Lead or an Account');
    }

    opp.StageName = 'Quoting';
    opp.LeadSource = oppFields.leadSource;
    opp.CampaignId = oppFields.campaignSource == '' ? null : oppFields.campaignSource;
    opp.CloseDate = oppFields.closeDate;
    if( u.Sales_Department__c != null){
      opp.Sales_Department__c = u.Sales_Department__c;
    }

    try{
      if( opp.Id == null )
      {
        insert opp;
      }
      if( oppFields.pricebook != null )
      {
        opp.Pricebook2Id = oppFields.pricebook;
      }
      update opp;
      return opp.Id;
    }
    catch(Exception e){
      throw new AuraHandledException( e.getMessage() );
    }
  }

  @AuraEnabled
  public static String createSale_Business( String businessJSON, String oppJSON )
  {
    User u = [SELECT Id, Sales_Department__c FROM User WHERE Id = :UserInfo.getUserId()];
    Business b = (Business)JSON.deserialize( businessJSON, Business.class );
    b.fillCountryAndState();
    System.debug( b );
    OppWrapper oppFields = (OppWrapper)JSON.deserialize( oppJSON, OppWrapper.class );
    // insert/update Account information
    Account acct = b.toAccount();
    System.debug( acct );
    upsert acct;

    // insert/update contacts
    Map<String, Contact> conts = new Map<String,Contact>();
    for( BusinessContact bc : b.contacts )
    {
      Contact c = bc.toContact( acct.Id );
      if( bc.contactRoleType == null )
        conts.put('na', c );
      else
        conts.put( bc.contactRoleType, c );
    }
    // throw an error if none of the contacts where set as a buyer
    if( !conts.containsKey('buyer') )
      throw new AuraHandledException('None of the contacts where specified as a Buyer');
    upsert conts.values();

    // Build the Opportunity
    Opportunity opp = new Opportunity(
      Name = buildOppName( acct.Name ),
      AccountId = acct.Id,
      StageName = 'Quoting',
      LeadSource = oppFields.leadSource,
      CampaignId = oppFields.campaignSource == '' ? null : oppFields.campaignSource,
      CloseDate = oppFields.closeDate
    );
    if( u.Sales_Department__c != null){
      opp.Sales_Department__c = u.Sales_Department__c;
    }

    try{
      if( opp.Id == null )
      {
        insert opp;
      }
      if( oppFields.pricebook != null )
      {
        opp.Pricebook2Id = oppFields.pricebook;
      }
      update opp;
    }
    catch(Exception e){
      throw new AuraHandledException( e.getMessage() );
    }

    //Build the OpportunityContactRoles
    OpportunityContactRole[] ocrs = new List<OpportunityContactRole>();
    Contact buyer = conts.get('buyer');
    ocrs.add( new OpportunityContactRole(
      ContactId = buyer.Id,
      OpportunityId = opp.Id,
      Role = 'Buyer',
      isPrimary = true
    ));
    if( conts.containsKey('cobuyer') )
    {
      ocrs.add( new OpportunityContactRole(
        ContactId = conts.get('cobuyer').Id,
        OpportunityId = opp.Id,
        Role = 'Co-Buyer',
        isPrimary = false
      ));
    }

    try {
      insert ocrs;
      return opp.Id;
    }
    catch( Exception e )
    {
      throw new AuraHandledException( e.getMessage() );
    }

  }

  private static String buildOppName(String acctName )
  {
    Datetime today = Datetime.now();
    String nameString = acctName + ' - ';
    nameString += today.format('yyyy.MM.dd-HHmm');
    return nameString;
  }


  private static List<Map<String,String>> fetchPricebooks( String userType )
  {
    Id pbRT = LGND_Utilities.recordTypeIdFromName('Pricebook2', 'Sales');
    List<Map<String,String>> result = new List<Map<String,String>>();
    if( userType == 'PowerPartner' )
    {
      return result;
    }
    for( PriceBook2 pb : [SELECT Id, Name
                          FROM Pricebook2
                          WHERE IsStandard = false
                          AND IsActive = true
                          AND RecordTypeId = :pbRT
                          ORDER BY Name DESC] )
    {
      result.add( new Map<String, String>{
        'value' => pb.Id,
        'label' => pb.Name
      });
    }
    return result;
  }

  private static Database.LeadConvertResult convertLead(Lead ld)
  {
    Savepoint sp = Database.setSavepoint();
    try {
      Database.LeadConvert lc = new Database.LeadConvert();
      lc.setLeadId(ld.id);

      LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
      lc.setConvertedStatus(convertStatus.MasterLabel);
      lc.setOpportunityName( buildOppName( ld.FirstName + ' ' + ld.LastName ) );
      lc.setOwnerId( UserInfo.getUserId() );

      Database.LeadConvertResult lcr = Database.convertLead(lc);
      return lcr;
    }
    catch(Exception e){
      Database.rollback( sp );
      throw new AuraHandledException( e.getMessage() );
    }
  }

  private static optionGroup[] fetchCampaignOptions( String userType )
  {
    Map<String, List<Map<String, String>>> options = new Map<String, List<Map<String, String>>>();
    List<OptionGroup> result = new List<OptionGroup>();
    List<Campaign> campaigns = [SELECT Id, Name, Parent.Name, RecordType.Name
                                FROM Campaign
                                WHERE isActive = true
                                AND Status = 'In Progress' ];
    for( Campaign c : campaigns ){
      if( userType == 'PowerPartner' && c.RecordType.Name != 'National' )
      {
        System.debug( 'skipping ' + c.Name + ' beacuse userType is PowerPartner and RecordType is ' + c.RecordType.Name );
        continue;
      }
      String par = c.Parent.Name == null ? 'Standard' : c.Parent.Name;
      if( !options.containsKey(par) )
      {
        options.put( par , new List<Map<String, String>>() );
      }
      options.get( par ).add( new Map<String, String>{
        'label' => c.Name,
        'value' =>  c.Id
      });
    }
    for( String groupName : options.keySet() )
    {
      OptionGroup og = new OptionGroup();
      og.groupName = groupName;
      og.options = options.get(groupName);
      result.add(og);
    }
    return result;
  }

  private static List<Map<String, String>> listToMap( List<String> options )
  {
    List<Map<String, String>> result = new List<Map<String, String>>();
    for( String o : options )
    {
      result.add( new Map<String, String>{
        'label' => o,
        'value' => o
      });
    }
    return result;
  }

  private static String fetchPersonAccount( String acctId )
  {
    Account acct = [SELECT Id,
                           Name,
                           PersonEmail,
                           FirstName,
                           LastName,
                           Phone,
                           PersonHomePhone,
                           PersonMobilePhone,
                           PersonOtherPhone,
                           Preferred_Language__c,
                           Relationship_Status__c,
                           Number_Of_Children__c,
                           Hobbies__c,
                           Emotional_Motivation__c,
                           Occupation__c,
                           Animals__c,
                           Teams__c,
                           Tow_Vehicle__c,
                           WOW_Notes__pc,
                           Gender__pc,
                           Tax_Exempt_Status_Card_Number__pc,
                           BillingStreet,
                           BillingCity,
                           BillingState,
                           BillingStateCode,
                           BillingCountry,
                           BillingCountryCode,
                           BillingPostalCode
           FROM Account
           WHERE Id = :acctId];
    return JSON.serialize( new Customer( acct ) );
  }

  private static String fetchBusinessAccount( String acctId )
  {
    Account acct = [SELECT Id,
                           Name,
                           Phone,
                           AccountEmail__c,
                           Fax,
                           BillingStreet,
                           BillingCity,
                           BillingState,
                           BillingStateCode,
                           BillingCountry,
                           BillingCountryCode,
                           BillingPostalCode,
                           ShippingStreet,
                           ShippingCity,
                           ShippingState,
                           ShippingStateCode,
                           ShippingCountry,
                           ShippingCountryCode,
                           ShippingPostalCode,
                  (SELECT Id,
                          FirstName,
                          LastName,
                          Email,
                          Phone,
                          MobilePhone,
                          Title
                   FROM Contacts)
           FROM Account
           WHERE Id = :acctId];
    return JSON.serialize( new Business( acct ) );
  }

  private static String fetchLead( String leadId )
  {
    Lead l = [SELECT Id,
                     Email,
                     FirstName,
                     LastName,
                     Phone,
                     MobilePhone,
                     Preferred_Language__c
              FROM Lead
              WHERE Id = : leadId
              AND isConverted = false];
    return JSON.serialize( new Customer( l ) );
  }

  private static List<Account_Matching_Field__mdt> queryDuplicateFields() {
    return [
        SELECT
            Id,
            DeveloperName,
            Wrapper_Field_Name__c
        FROM Account_Matching_Field__mdt
    ];
  }

}