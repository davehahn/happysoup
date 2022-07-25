public with sharing class lgnd_account_createForm {
  @AuraEnabled
  public static Account createLeadAndConvert(
    String FirstName,
    String LastName,
    String Email,
    String Phone,
    String Street,
    String City,
    String State,
    String StateCode,
    String Country,
    String CountryCode,
    String PostalCode,
    String PersonMobilePhone
  ) {
    Lead lead = createLead(
      FirstName = FirstName,
      LastName = LastName,
      Email = Email,
      Phone = Phone,
      Street = Street,
      City = City,
      State = State,
      StateCode,
      Country = Country,
      CountryCode = CountryCode,
      PostalCode = PostalCode
    );
    Account account = convertLead(lead, PersonMobilePhone);

    return [
      SELECT
        Id,
        RecordTypeId,
        FirstName,
        LastName,
        PersonEmail,
        PersonHomePhone,
        BillingCountry,
        BillingCity,
        BillingStreet,
        BillingStateCode,
        BillingPostalCode,
        PersonMobilePhone
      FROM Account
      WHERE Id = :account.Id
    ];
  }

  @AuraEnabled
  public static Account createAccount(
    String FirstName,
    String LastName,
    String Email,
    String Phone,
    String Street,
    String City,
    String State,
    String StateCode,
    String Country,
    String CountryCode,
    String PostalCode,
    String PersonMobilePhone
  ) {
    Account acct = new Account(
      RecordTypeId = LGND_Utilities.recordTypeIdFromName('Account', 'Person Account'),
      FirstName = FirstName,
      LastName = LastName,
      PersonEmail = Email,
      Phone = Phone,
      BillingCountry = Country,
      BillingCountryCode = CountryCode,
      BillingCity = City,
      BillingStreet = Street,
      BillingState = State,
      BillingStateCode = StateCode,
      BillingPostalCode = PostalCode,
      PersonMobilePhone = PersonMobilePhone
    );
    insert acct;
    return [
      SELECT
        Id,
        RecordTypeId,
        FirstName,
        LastName,
        PersonEmail,
        PersonHomePhone,
        BillingCountry,
        BillingCity,
        BillingStreet,
        BillingStateCode,
        BillingPostalCode,
        PersonMobilePhone
      FROM Account
      WHERE Id = :acct.Id
    ];
  }

  private static Lead createLead(
    String FirstName,
    String LastName,
    String Email,
    String Phone,
    String Street,
    String City,
    String State,
    String StateCode,
    String Country,
    String CountryCode,
    String PostalCode
  ) {
    Lead lead = new Lead(
      FirstName = FirstName,
      LastName = LastName,
      Email = Email,
      Phone = Phone,
      street = Street,
      city = City,
      state = State,
      country = Country,
      postalCode = PostalCode
    );

    insert lead;

    return lead;
  }

  public static Account convertLead(Lead lead, String PersonMobilePhone) {
    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(lead.id);
    lc.setDoNotCreateOpportunity(true);

    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
    lc.setConvertedStatus(convertStatus.MasterLabel);

    Database.LeadConvertResult lcr = Database.convertLead(lc);
    System.assert(lcr.isSuccess());

    String accountId = lcr.getAccountId();

    Account account = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
    account.PersonMobilePhone = PersonMobilePhone;

    update account;
    return account;
  }
}
