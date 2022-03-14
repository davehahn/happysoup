@isTest
public class Factory_Account {
  public static Account[] buildDealerAccounts(Integer count) {
    return buildAccounts(count, 'Dealer');
  }

  public static Account[] insertDealerAccounts(Integer count) {
    return insertAccounts(count, 'Dealer');
  }

  public static Account[] insertSupplierAccounts(Integer count) {
    return insertAccounts(count, 'Supplier');
  }

  public static Account[] insertFinancialInstitutions(Integer count) {
    Account[] result = new List<Account>();
    for (Account acct : buildAccounts(count, 'Supplier')) {
      acct.Financing_Vendor__c = true;
      result.add(acct);
    }
    insert result;
    return result;
  }

  public static Account[] insertCustomerAccounts(Integer count) {
    String aType = 'Person Account';
    Id rtId = LGND_Utilities.recordTypeIdFromName('Account', aType);
    Account[] result = new List<Account>();
    for (Integer i = 0; i < count; i++) {
      result.add(
        new Account(
          RecordTypeId = rtId,
          FirstName = aType,
          LastName = aType + ' - ' + String.valueOf(i),
          Type = aType,
          PersonEmail = 'noemail@legendboats.com'
        )
      );
    }
    insert result;
    return result;
  }

  public static Account[] buildAccounts(Integer count, String aType) {
    Id rtId = LGND_Utilities.recordTypeIdFromName('Account', aType);
    Account[] result = new List<Account>();
    for (Integer i = 0; i < count; i++) {
      result.add(
        new Account(RecordTypeId = rtId, Name = aType + ' - ' + String.valueOf(i), Type = aType, Active__c = true)
      );
    }
    return result;
  }

  private static Account[] insertAccounts(Integer count, String aType) {
    Account[] result = buildAccounts(count, aType);
    insert result;
    return result;
  }

  public static Account insertAccountWithContacts(String name, Id acctRecordTypeId, Integer contactCount) {
    Account a = new Account(
      RecordTypeId = acctRecordTypeId,
      Name = name,
      Phone = '111-111-1111',
      Fax = '222-222-2222',
      BillingStreet = '1 Test Street',
      BillingCity = 'Test City',
      BillingState = 'Ontario',
      BillingCountry = 'Canada',
      BillingPostalCode = 'a1b 2c3',
      ShippingStreet = '2 Test Street',
      ShippingCity = 'Test City',
      ShippingState = 'Ontario',
      ShippingCountry = 'Canada',
      ShippingPostalCode = 'a2b 5c6'
    );
    insert a;
    Contact[] conts = new List<Contact>();
    for (Integer i = 0; i < contactCount; i++) {
      conts.add(
        Factory_Contact.newContact(a.Id, 'contFirstName' + String.valueOf(i), 'contLastName' + String.valueOf(i))
      );
    }
    insert conts;
    return a;
  }

  public static Account insertBusinessAccountWithContacts(String name, Integer contactCount) {
    Id rTid = new Application_RecordType().getAccountRecordTypes().getBusinessAccountId();
    return insertAccountWithContacts(name, rTid, contactCount);
  }

  public static Account insertSupplierAccountWithContacts(String name, Integer contactCount) {
    Id rTid = new Application_RecordType().getAccountRecordTypes().getSupplierId();
    return insertAccountWithContacts(name, rTid, contactCount);
  }

  public static Account buildFullPersonAccount(String fName, String lName) {
    String[] hobbies = LGND_Utilities.getPicklistValues('Account', 'Hobbies__c');
    String[] emoMoto = LGND_Utilities.getPicklistValues('Account', 'Emotional_Motivation__c');
    String[] animals = LGND_Utilities.getPicklistValues('Account', 'Animals__c');
    String[] towVehicles = LGND_Utilities.getPicklistValues('Account', 'Tow_Vehicle__c');
    String[] relStatuses = LGND_Utilities.getPicklistValues('Account', 'Relationship_Status__c');
    String[] langs = LGND_Utilities.getPicklistValues('Account', 'Preferred_Language__c');
    String[] genders = LGND_Utilities.getPicklistValues('Account', 'Gender__pc');
    Id rTid = LGND_Utilities.recordTypeIdFromName('Account', 'Person Account');

    return new Account(
      RecordTypeId = rTid,
      FirstName = fName,
      LastName = lName,
      PersonEmail = fname.toLowerCase() + '@' + lname.toLowerCase() + '.com',
      Phone = '111-111-1111',
      PersonMobilePhone = '222-222-2222',
      Gender__pc = genders[0],
      Preferred_Language__c = langs[0],
      Relationship_Status__c = relStatuses[0],
      Number_Of_Children__c = 2,
      Occupation__c = 'Code Wizard',
      Tow_Vehicle__c = towVehicles[0],
      Emotional_Motivation__c = emoMoto[0],
      Hobbies__c = hobbies[0],
      Animals__c = animals[0],
      Teams__c = 'No Sports',
      BillingStreet = '139 Fittons Rd West',
      BillingCity = 'Orillia',
      BillingState = 'Ontario',
      BillingCountry = 'Canada',
      BillingPostalCode = 'L3V 3V3'
    );
  }

  public static Account insertFullPersonAccount(String fName, String lName) {
    Account a = buildFullPersonAccount(fName, lName);
    insert a;
    return a;
  }
}
