global with sharing class RetailSalesToolController {

  public class MyException extends Exception {}

  static Id personTypeAccountId;

  static {
    Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Account;
    Map<String,Schema.RecordTypeInfo> RecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
    personTypeAccountId = RecordTypeInfo.get('Person Account').getRecordTypeId();
  }

  public Opportunity opp { get; set; }
  public String defaultPricebookId { get; set; }
  public String defaultPartnerPricebookId { get; set; }

  global class DealerWrapper {
    public String Id { get; set; }
    public String Name { get; set; }
    public String PreferredLanguage { get; set; }
    public String AddressLine1 { get; set; }
    public String AddressLine2 { get; set; }
    public String AddressLine3 { get; set; }
    public String Phone { get; set; }
    public String Fax { get; set; }

    global DealerWrapper(Account acct){
      this.Id = acct.Id;
      this.Name = acct.Name;
      this.AddressLine1 = acct.BillingStreet + ', ' + acct.BillingCity;
      this.AddressLine2 = acct.BillingState + ', ' + acct.BillingCountry;
      this.AddressLine3 = acct.BillingPostalCode;
      this.Phone = acct.Phone;
      this.Fax = acct.Fax;
      this.PreferredLanguage = acct.Preferred_Language__c;
    }
  }

  global class CustomerWrapper {
    public String Id { get; set; }
    public String FirstName { get; set; }
    public String LastName { get; set; }
    public String Email { get; set; }
    public String Phone { get; set; }
    public String MobilePhone { get; set; }
    public String LeadStatus { get; set; }

    public String PreferredLanguage { get; set; }
    public String RelationshipStatus { get; set; }
    public Decimal NumberOfChildren { get; set; }
    public String Occupation { get; set; }
    public String TowVehicle { get; set; }

    public String[] EmotionalMotivation { get; set; }
    public String[] Hobbies { get; set; }
    public String[] Animals { get; set; }
    public String Teams { get; set; }

    public String WowNotes { get; set; }

    global CustomerWrapper(){}

    global CustomerWrapper(Account acct)
    {
      this.Id = acct.Id;
      this.FirstName = acct.FirstName;
      this.LastName = acct.LastName;
      this.Email = acct.PersonEmail;
      this.Phone = acct.Phone;
      this.MobilePhone = acct.PersonMobilePhone;

      this.PreferredLanguage = acct.Preferred_Language__c == null ? 'English' : acct.Preferred_Language__c;
      this.RelationShipStatus = acct.Relationship_Status__c;
      this.NumberOfChildren = acct.Number_Of_Children__c;
      this.Occupation = acct.Occupation__c;
      this.TowVehicle = acct.Tow_Vehicle__c;

      this.EmotionalMotivation = acct.Emotional_Motivation__c == null ? null : acct.Emotional_Motivation__c.split(';');
      this.Hobbies = acct.Hobbies__c == null ? null : acct.Hobbies__c.split(';');
      this.Animals = acct.Animals__c == null ? null : acct.Animals__c.split(';');
      this.Teams = acct.Teams__c;

      this.WowNotes = acct.WOW_Notes__pc;

    }

    global CustomerWrapper(Lead ld)
    {
      this.Id = ld.Id;
      this.FirstName = ld.FirstName;
      this.LastName = ld.LastName;
      this.Email = ld.Email;
      this.Phone = ld.Phone;
      this.MobilePhone = ld.MobilePhone;
      this.PreferredLanguage = ld.Preferred_Language__c;
      this.LeadStatus = ld.Status;
    }

    public Lead revertToLead()
    {
      return new Lead(
        Id = this.Id,
        FirstName = this.FirstName,
        LastName = this.LastName,
        Email = this.Email,
        Phone = this.Phone,
        MobilePhone = this.MobilePhone,
        Preferred_Language__c = this.PreferredLanguage,
        Status = (this.LeadStatus == null || this.LeadStatus == 'New') ? 'Accepted' : this.LeadStatus
      );
    }



    public Account revertToAccount()
    {
      Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Account;
      Map<String,Schema.RecordTypeInfo> RecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
      Id personTypeAId = RecordTypeInfo.get('Person Account').getRecordTypeId();
      return new Account(
        Id = this.Id,
        FirstName = this.FirstName,
        LastName = this.LastName,
        PersonEmail = this.Email,
        Phone = this.Phone,
        PersonMobilePhone = this.MobilePhone,
        RecordTypeId = personTypeAId,
        Preferred_Language__c = this.PreferredLanguage,
        Tow_Vehicle__c = this.TowVehicle,
        Occupation__c = this.Occupation,
        Number_Of_Children__c = this.NumberOfChildren,
        Relationship_Status__c = this.RelationshipStatus,
        Emotional_Motivation__c = stringifyArray( this.EmotionalMotivation ),
        Hobbies__c = stringifyArray( this.Hobbies ),
        Animals__c = stringifyArray( this.Animals ),
        Teams__c = this.Teams,
        WOW_Notes__pc = this.WowNotes
      );
    }

    private String stringifyArray(List<String> arr)
    {
      String result = '';
      if( arr != null )
      {
        for(String s : arr)
        {
          result += s + ';';
        }
      }
      return result;
    }
  }

  public Class OpportunityWrapper {
    public String oppLeadSource { get; set; }
    public String oppCampaignId { get; set; }
    public String oppCloseDate { get; set; }
    public String oppPricebook {get; set; }

    public OpportunityWrapper(){}
  }


	global RetailSalesToolController() {
    opp = new Opportunity();
    try
    {
      defaultPricebookId = [SELECT Id FROM Pricebook2 WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c].Id;
      defaultPartnerPricebookId = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;
    }
    catch(Exception e){}
	}

  public Map<String, Map<String, String>> getCampaignOptions() {
    //List<SelectOption> options = new List<SelectOption>();
    Map<String, Map<String, String>> options = new Map<String, Map<String, String>>();
    //options.add( new SelectOption( '', '- None -') );
    List<Campaign> campaigns = [SELECT Id, Name, Parent.Name
                                FROM Campaign
                                WHERE isActive = true
                                AND Status = 'In Progress' ];
    for( Campaign c : campaigns ){
      if( !options.containsKey(c.Parent.Name) )
      {
        options.put( c.Parent.Name , New Map<String, String>() );
      }
      options.get( c.Parent.Name ).put( c.Name, c.Id );
      //options.add( new SelectOption( c.Id, c.Name ) );
    }
    return options;
  }

  public List<SelectOption> getPriceBookOptions(){
   return buildPricebookOptions('Sales');
  }

  public List<SelectOption> getPartnerPriceBookOptions(){
    return buildPricebookOptions('Dealer');
  }

  private List<SelectOption> buildPricebookOptions( String recordTypeName )
  {
    List<SelectOption> options = new List<SelectOption>();
    Id dealerRT = LGND_Utilities.recordTypeIdFromName('Pricebook2', recordTypeName);
    List<Pricebook2> pbs = [SELECT Id, Name
                            FROM Pricebook2
                            WHERE IsStandard = false
                            AND IsActive = true
                            AND RecordTypeId = :dealerRT
                            ORDER BY Name DESC];
    for(Pricebook2 pb : pbs){
      options.add( new SelectOption( pb.Id, pb.Name) );
    }
    return options;
  }

  public List<SelectOption> getLanguageOptions()
  {
     return buildSelectOptions( Account.Preferred_Language__c.getDescribe(), false );
  }

  public List<SelectOption> getRelationshipStatusOptions()
  {
    return buildSelectOptions( Account.Relationship_Status__c.getDescribe(), true );
  }

  public List<SelectOption> getHobbyOptions()
  {
    return buildSelectOptions( Account.Hobbies__c.getDescribe(), false );
  }

  public List<SelectOption> getEmotionalMotivationOptions()
  {
    return buildSelectOptions( Account.Emotional_Motivation__c.getDescribe(), false );
  }

  public List<SelectOption> getAnimalOptions()
  {
    return buildSelectOptions( Account.Animals__c.getDescribe(), false );
  }


  public List<SelectOption> getTowVehicleOptions()
  {
    return buildSelectOptions( Account.Tow_Vehicle__c.getDescribe(), true );
  }


  private List<SelectOption> buildSelectOptions( Schema.DescribeFieldResult field, Boolean includeNullValue )
  {
    SelectOption[] options = new List<SelectOption>();
    if( includeNullValue == true )
    {
      options.add( new SelectOption('', '-- Select--') );
    }
    for( Schema.PicklistEntry f : field.getPicklistValues() )
    {
      options.add(new SelectOption(f.getValue(), f.getLabel()));
    }
    return options;
  }

  //@RemoteAction
  //global static List<Account> findAccounts(String searchString){
  //  String s = '%' + searchString + '%';
  //  return [SELECT Id, Name FROM Account WHERE Name LIKE :s AND RecordTypeId = :personTypeAccountId];
  //}


  @RemoteAction
  global static CustomerWrapper selectCustomer(Id objId)
  {
    Schema.sObjectType entityType = objId.getSObjectType();
    if( entityType == Account.sObjectType )
    {
      //try {
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
                               WOW_Notes__pc
           FROM Account
           WHERE Id = :objId];
        return new CustomerWrapper(acct);
      //}
      //catch(Exception e)
      //{
      //  return null;
      //}
    }

    if( entityType == Lead.sObjectType )
    {
      //try {
      List<Lead> leads = Lead_Selector.allUncovertedByIds( new Set<Id>{objId} );
      if( leads.size() == 1 ){
        return new CustomerWrapper(leads[0]);
      }
//        Lead ld = [SELECT Id, Name, Email, FirstName, LastName, Phone, MobilePhone, Preferred_Language__c
//                           FROM Lead
//                           WHERE Id = :objId
//                           AND isConverted = false];
//        return new CustomerWrapper(ld);
      //}
      //catch(Exception e)
      //{
      //  return null;
      //}
    }
    return null;

  }

  @RemoteAction
  global static Map<String, List<Map<String, String>>> customerSearch(String searchString)
  {
    String s = '%' + searchString + '%';
    Map<String, List< Map<String, String>> > results = new Map<String, List<Map<String, String>>>();
    Account[] accts = [SELECT Id, Name FROM Account WHERE Name LIKE :s AND RecordTypeId = :personTypeAccountId];
    Lead[] leads = [SELECT Id, Name FROM Lead WHERE Name LIKE :s AND isConverted = false];
    if( accts.size() > 0 )
    {
      results.put('Accounts', new List<Map<String, String>>() );
      for(Account a : accts)
      {
        results.get('Accounts').add( new Map<String, String>{'Id' =>  a.Id, 'Name' => a.Name} );
        //results.get('Accounts').add(new Map<String, String>{'Name', a.Name);
      }
    }
    if( leads.size() > 0 )
    {
      results.put('Leads', new List<Map<String, String>>() );
      for(Lead l : leads)
      {
        results.get('Leads').add( new Map<String, String>{'Id' =>  l.Id, 'Name' => l.Name} );
        //results.get('Leads').put('Name', l.Name);
      }
    }
    if( results.size() > 0 ) return results;
    return null;
  }

  @RemoteAction
  global static List<DealerWrapper> dealerSearch( String searchString )
  {
    String s = '%' + searchString + '%';
    Id dealerRecordType = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer');
    List<DealerWrapper> results = new List<DealerWrapper>();
    for( Account acct : [SELECT Id,
                                Name,
                                BillingCity,
                                BillingCountry,
                                BillingPostalCode,
                                BillingState,
                                BillingStreet,
                                Preferred_Language__c,
                                Phone,
                                Fax
                         FROM Account
                         WHERE Name
                         LIKE :s
                         AND RecordTypeId = : dealerRecordType ] )
    {
      results.add( new DealerWrapper(acct) );
    }
    return results;
  }

  //@RemoteAction
  //global static PageReference createDealerSale(String accountId, String oppData )
  //{
  //  Account acct = [SELECT Id, Name FROM Account WHERE Id = :accountId];
  //  OpportunityWrapper oppW = (OpportunityWrapper)JSON.deserializeStrict(oppData, OpportunityWrapper.class);
  //  if( accountId != null || accountId != '' )
  //  {
  //    Opportunity opp = new Opportunity(
  //      AccountId = accountId,
  //      RecordTypeId = LGND_Utilities.recordTypeIdFromName('Opportunity', 'Wholesale'),
  //      Name = buildOppName(acct.Name),
  //      CloseDate = Date.parse( oppW.oppCloseDate ),
  //      StageName = 'Quoting'
  //    );

  //    insert opp;
  //    if( oppW.oppPricebook != null )
  //    {
  //      opp.Pricebook2Id = oppW.oppPricebook;
  //    }
  //    update opp;
  //    return new PageReference('/apex/BoatConfigurator?opportunity_id=' + opp.Id);
  //  }
  //  return null;
  //}

  @remoteAction
  global static PageReference createSale(String customerData, String oppData) {
    User u = [SELECT Id, Sales_Department__c FROM User WHERE Id = :UserInfo.getUserId()];
    Account workingAccount;
    Opportunity opp;
    Schema.sObjectType entityType;
    CustomerWrapper cw = (CustomerWrapper)JSON.deserializeStrict(customerData, CustomerWrapper.class);
    OpportunityWrapper oppW = (OpportunityWrapper)JSON.deserializeStrict(oppData, OpportunityWrapper.class);
    // determine if we are dealling with an Account or a Lead
    // If the Id is Null it is new Lead, if not we need to check
    if( cw.Id != null )
    {
      entityType = Id.valueOf( cw.Id ).getSObjectType();
    }
    if(entityType != null && entityType == Account.sObjectType)
    {
      workingAccount = cw.revertToAccount();
      update workingAccount;
      workingAccount = [SELECT Id, Name,
            (SELECT Id, Name From Opportunities WHERE RecordType.Name = 'Retail' ORDER BY Name DESC)
            FROM Account WHERE Id = :workingAccount.Id];
      Integer oppNum = 1 + workingAccount.Opportunities.size();
      //if( workingAccount.Opportunities.size() > 0 ){
        //Integer lastNum = Integer.valueOf( workingAccount.Opportunities[0].Name.replace(' ', '').split('-')[1] );
        //oppNum += lastNum;

      //}

      opp = new Opportunity();
      opp.Name = buildOppName( workingAccount.Name );
      opp.StageName = 'Quoting';
      opp.LeadSource = oppW.oppLeadSource;
      opp.CampaignId = oppW.oppCampaignId == '' ? null : oppW.oppCampaignId;
      opp.CloseDate = Date.parse( oppW.oppCloseDate );
      opp.AccountId = workingAccount.Id;

      if( u.Sales_Department__c != null){
        opp.Sales_Department__c = u.Sales_Department__c;
      }

    }
    else
    //We are dealling with a lead
    {

      Database.LeadConvertResult lcr = parseCustomerDataForLead(cw);
      if( lcr.isSuccess() )
      {
        opp = [SELECT Id, Account.Name FROM Opportunity WHERE Id = :lcr.getOpportunityId() ];
        //Save the extra details to the account
        cw.Id = lcr.getAccountId();
        workingAccount = cw.revertToAccount();
        update workingAccount;
        opp.StageName = 'Quoting';
        opp.LeadSource = oppW.oppLeadSource;
        opp.CampaignId = oppW.oppCampaignId == '' ? null : oppW.oppCampaignId;
        opp.CloseDate = Date.parse( oppW.oppCloseDate );
        //opp.Name = buildOppName( opp.Account.Name );
        if( u.Sales_Department__c != null){
          opp.Sales_Department__c = u.Sales_Department__c;
        }

      }
    }

    try{
      if( opp.Id == null )
      {
        insert opp;
      }
      if( oppW.oppPricebook != null )
      {
        opp.Pricebook2Id = oppW.oppPricebook;
        //opp.Product_Year__c = getProductYear(oppW.oppPricebook);
      }
      update opp;
      return new PageReference('/apex/BoatConfigurator?opportunity_id=' + opp.Id);
    }
    catch(Exception e){
      throw new MyException( e.getMessage() );
      return null;
    }
  }

  public static String getProductYear(String pb2Id)
  {
    Date today = Date.today();
    Integer pYear = today.month() > 9 ? today.year() + 1 : today.year();

    try
    {
      Pricebook2 pb = [SELECT Name FROM Pricebook2 WHERE Id = :pb2Id];
      List<String> splitName = pb.Name.split(' ');
      String pbYear = splitName.get( splitName.size() - 1 );
      pYear = Integer.valueOf(pbYear);
    }
    catch(Exception e){}
    return String.valueOf(pYear);
  }

/************************* PRIVATES ******************************/

  private static String buildOppName(String acctName )
  {
    Datetime today = Datetime.now();
    String nameString = acctName + ' - ';
    nameString += today.format('yyyy.MM.dd-HHmm');
    return nameString;
  }

  private static Database.LeadConvertResult parseCustomerDataForLead(CustomerWrapper cWrap)
  {
    if( cWrap.Id == null )
    //This is a new customer record we need to create a Lead then convert to an account
    {
      Lead ld = cWrap.revertToLead();
      ld.OwnerId = UserInfo.getUserId();
      insert ld;
      //and now convert it
      return convertLead(ld);
    }
    else
    {
      //here we have a previously created record so we update it and then convert it
      Lead ld = cWrap.revertToLead();
      ld.OwnerId = UserInfo.getUserId();
      update ld;
      //and now convert it
      return convertLead(ld);
    }
    return null;
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
      throw new MyException( e.getMessage() );
      return null;
    }
  }

}