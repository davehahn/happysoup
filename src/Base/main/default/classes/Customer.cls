/**
 * Created by dave on 2020-06-09.
 */

public virtual class Customer {
  public String id { get; set; }
  public String type { get; set; }
  public String street { get; set; }
  public String city { get; set; }
  public String state { get; set; }
  public String stateCode { get; set; }
  public String country { get; set; }
  public String countryCode { get; set; }
  public String postalCode { get; set; }
  public String leadSource { get; set; }
  public List<Map<String, String>> leadCampaignInfluences { get; set; }

  private Account theAccount;
  private Lead theLead;
  private Boolean createOpportunityOnLeadConvert = false;

  public Customer() {
  }

  public Customer(Account acct) {
    this.id = acct.Id;
    this.street = acct.BillingStreet;
    this.city = acct.BillingCity;
    this.state = acct.BillingState;
    this.stateCode = acct.BillingStateCode;
    this.country = acct.BillingCountry;
    this.countryCode = acct.BillingCountryCode;
    this.postalCode = acct.BillingPostalCode;
  }

  public void fillCountryAndState() {
    if (this.state != null && this.stateCode == null) {
      fixState('code');
    }
    if (this.stateCode != null && this.state == null) {
      fixState('state');
    }
    if (this.country != null && this.countryCode == null) {
      fixCountry('code');
    }
    if (this.countryCode != null && this.country == null) {
      fixCountry('country');
    }
  }

  public Customer setCreateOpportunityOnLeadConvert(boolean shouldConvert) {
    this.createOpportunityOnLeadConvert = shouldConvert;
    return this;
  }

  private void fixState(String missingAttr) {
    Schema.DescribeFieldResult fieldResult = User.statecode.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for (Schema.PicklistEntry f : ple) {
      if (missingAttr == 'code' && f.getLabel() == this.state) {
        this.stateCode = f.getValue();
      }
      if (missingAttr == 'state' && f.getValue() == this.stateCode) {
        this.state = f.getLabel();
      }
    }
  }

  private void fixCountry(String missingAttr) {
    Schema.DescribeFieldResult fieldResult = User.Countrycode.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for (Schema.PicklistEntry f : ple) {
      if (missingAttr == 'code' && f.getLabel() == this.country) {
        this.countryCode = f.getValue();
      }
      if (missingAttr == 'country' && f.getValue() == this.countryCode) {
        this.country = f.getLabel();
      }
    }
  }

  private String formatPhoneNumber(String pn) {
    if (pn == null)
      return null;
    pn = pn.replaceAll('[^0-9]', '');
    return pn.substring(0, 3) + '-' + pn.substring(3, 6) + '-' + pn.substring(6);
  }

  public virtual class Person extends Customer {
    public String firstName { get; set; }
    public String lastName { get; set; }
    public String email { get; set; }
    public String phone { get; set; }
    public String gender { get; set; }
    public String mobilePhone { get; set; }
    public Boolean isTaxExempt { get; set; }
    public String taxExemptNumber { get; set; }
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

    public Person() {
      super();
      this.type = 'person';
    }

    public Person(Account acct) {
      super(acct);
      this.type = 'person';
      this.firstName = acct.FirstName;
      this.lastName = acct.LastName;
      this.email = acct.PersonEmail;
      this.phone = formatPhoneNumber(acct.Phone);
      this.mobilePhone = formatPhoneNumber(acct.PersonMobilePhone);
      this.gender = acct.Gender__pc;
      this.isTaxExempt = acct.Tax_Exempt_Status_Card_Number__pc != null;
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
      this.leadCampaignInfluences = new List<Map<String, String>>();
    }

    public Person(Lead l) {
      this.type = 'person';
      this.id = l.Id;
      this.firstName = l.FirstName;
      this.lastName = l.LastName;
      this.leadSource = l.LeadSource;
      this.email = l.Email;
      this.phone = l.Phone;
      this.mobilePhone = l.MobilePhone;
      this.street = l.Street;
      this.city = l.City;
      this.state = l.State;
      this.stateCode = l.StateCode;
      this.country = l.Country;
      this.countryCode = l.CountryCode;
      this.postalCode = l.PostalCode;
      this.preferredLanguage = l.Preferred_Language__c;
      this.numberOfChildren = 0;
      this.isTaxExempt = false;
      this.leadCampaignInfluences = new List<Map<String, String>>();
      try {
        for (CampaignMember cm : l.CampaignMembers) {
          this.leadCampaignInfluences.add(
            new Map<String, String>{ 'label' => cm.Campaign.Name, 'value' => cm.CampaignId }
          );
        }
      } catch (Exception e) {
      }
    }

    public Account revertToAccount() {
      fillCountryAndState();
      this.theAccount = new Account(
        Id = this.id == null || this.id.length() == 0 ? null : this.id,
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
      return this.theAccount;
    }

    public Lead revertToLead() {
      fillCountryAndState();
      this.theLead = new Lead(
        FirstName = this.firstName,
        LastName = this.lastName,
        LeadSource = this.leadSource,
        Email = this.email,
        Phone = this.phone,
        MobilePhone = this.mobilePhone,
        Preferred_Language__c = this.preferredLanguage,
        Country = this.country,
        CountryCode = this.countryCode,
        City = this.city,
        State = this.state,
        StateCode = this.stateCode,
        Street = this.street,
        PostalCode = this.postalCode
      );
      if (this.id != null)
        this.theLead.Id = this.id;
      return this.theLead;
    }

    public AccountSaveResult upsertRecord() {
      if (this.id != null && this.id.length() > 0 && LGND_Utilities.sObjectNameFromId(this.id) == 'Lead') {
        revertToLead();
        update this.theLead;
        return convertLead();
      } else {
        return doAccountSave();
      }
    }

    //This method is added by Pooja as a part of Ecwid Integration
    public AccountSaveResult convertLead(String operation) {
      return convertLead();
    }

    private AccountSaveResult convertLead() {
      Database.LeadConvert lc = new Database.LeadConvert();
      lc.setLeadId(this.theLead.Id);
      LeadStatus convertStatus = [SELECT Id, ApiName FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
      lc.setConvertedStatus(convertStatus.ApiName);
      lc.setDoNotCreateOpportunity(!this.createOpportunityOnLeadConvert);
      lc.setOwnerId(UserInfo.getUserId());
      if (this.id != null && this.id != this.theLead.Id) {
        lc.setAccountId(this.id);
      }
      try {
        Database.LeadConvertResult leadConvertResult = Database.convertLead(lc);
        if (leadConvertResult.isSuccess()) {
          this.id = leadConvertResult.getAccountId();
          AccountSaveResult result = new AccountSaveResult();
          result.status = 'success';
          result.record = revertToAccount();
          if (this.createOpportunityOnLeadConvert)
            result.opportunityId = leadConvertResult.getOpportunityId();
          return result;
        } else {
          return handleErrors(leadConvertResult.getErrors());
        }
      } catch (Exception e) {
        if (e.getMessage().contains('DUPLICATES_DETECTED')) {
          this.id = null;
          AccountSaveResult result = doAccountSave();
          return result;
        }
        AccountSaveResult result = new AccountSaveResult();
        result.status = 'error';
        result.addMessage(e.getMessage());
        return result;
      }
    }

    private AccountSaveResult doAccountSave() {
      System.debug('doAccountSave');
      Database.UpsertResult saveResult = Database.upsert(this.revertToAccount(), Account.Fields.Id, false);

      if (saveResult.isSuccess()) {
        return handleSaveSuccess();
      } else {
        return handleErrors(saveResult.getErrors());
      }
    }

    private AccountSaveResult forceAccountUpdate() {
      System.debug('forceAccountUpdate');
      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.allowSave = true;
      dml.DuplicateRuleHeader.runAsCurrentUser = true;
      Database.SaveResult saveResult = Database.update(revertToAccount(), dml);
      if (saveResult.isSuccess()) {
        return handleSaveSuccess();
      } else {
        return handleErrors(saveResult.getErrors());
      }
    }

    private AccountSaveResult forceAccountSave() {
      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.allowSave = true;
      dml.DuplicateRuleHeader.runAsCurrentUser = true;
      Database.SaveResult saveResult = Database.insert(revertToAccount(), dml);
      if (saveResult.isSuccess()) {
        return handleSaveSuccess();
      } else {
        return handleErrors(saveResult.getErrors());
      }
    }

    private AccountSaveResult handleSaveSuccess() {
      System.debug('handleSaveSuccess');
      AccountSaveResult result = new AccountSaveResult();
      result.record = this.theAccount;
      result.status = 'success';
      return result;
    }

    private AccountSaveResult handleErrors(List<Database.Error> errors) {
      System.debug('handleErrors');
      AccountSaveResult result = new AccountSaveResult();
      result.status = 'error';
      for (Database.Error error : errors) {
        System.debug(error.getMessage());
        result.addMessage(error.getMessage());
        if (error instanceof Database.DuplicateError) {
          System.debug('Instance of Duplicate Error');
          /* The Error */
          Database.DuplicateError duplicateError = (Database.DuplicateError) error;
          Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();

          /* Matched Records */
          Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
          Datacloud.MatchResult matchResult = matchResults[0];
          Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
          for (Datacloud.MatchRecord matchRecord : matchRecords) {
            result.addDuplicate(matchRecord.getRecord());
          }
        }
      }
      if (result.duplicateRecords != null) {
        System.debug('we have duplicate records');
        if (result.duplicateRecords.size() == 1) {
          System.debug('Single Duplicate Error');
          System.debug(result.duplicateRecords[0]);
          if (result.duplicateRecords[0].get('PersonEmail') == this.email) {
            System.debug('EMAIL IS THE DUP');
            String err =
              this.email +
              ' is already in use by a Customer by the name of ' +
              result.duplicateRecords[0].get('Name');
            AuraHandledException ex = new AuraHandledException(err);
            ex.setMessage(err);
            throw ex;
          } else {
            this.id = (Id) result.duplicateRecords[0].get('Id');
          }
        }

        if (result.duplicateRecords.size() > 1) {
          for (SObject dup : result.duplicateRecords) {
            if (dup.get('PersonEmail') == this.email) {
              System.debug('EMAIL IS THE DUP');
              throw new AuraHandledException(
                this.email +
                ' is already in use by a Customer by the name of ' +
                dup.get('Name')
              );
            }
            if (dup.get('Name') == this.firstName + ' ' + this.lastName) {
              this.id = (Id) dup.get('Id');
              break;
            }
          }
        }
        return this.id == null ? forceAccountSave() : this.theLead != null ? convertLead() : forceAccountUpdate();
      }
      return result;
    }
  }

  public virtual class Dealer extends Customer {
    public String name { get; set; }

    public Dealer(Account acct) {
      super(acct);
      this.name = acct.Name;
      this.type = 'dealer';
    }
  }

  public virtual class AccountSaveResult {
    @AuraEnabled
    public Account record;
    @AuraEnabled
    public String opportunityId;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String[] messages;
    @AuraEnabled
    public List<SObject> duplicateRecords;

    public AccountSaveResult() {
    }

    public void addDuplicate(SObject dup) {
      if (this.duplicateRecords == null)
        this.duplicateRecords = new List<SObject>();
      this.duplicateRecords.add(dup);
    }

    public void addMessage(String msg) {
      if (this.messages == null)
        this.messages = new List<String>();
      this.messages.add(msg);
    }
  }
}
