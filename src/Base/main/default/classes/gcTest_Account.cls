@isTest //(SeeAllData=TRUE)
private class gcTest_Account {
  @IsTest
  static void test1() {
    gcAccount.disableTrigger = true;
    gcAccount.disableTrigger = false;
    gcAccount.disableTrigger = null;
    Boolean b = gcAccount.disableTrigger;

    Account a = gcTest_Triggers.createAccount();
    insert a;
    update a;
    delete a;
  }

  @IsTest
  static void personAccount_GeoCodes_Creation_Test() {
    Id rtId = LGND_Utilities.recordTypeIdFromName('Account', 'Person Account');
    Account a = new Account(
      RecordTypeId = rtId,
      FirstName = 'Tester',
      LastName = 'McTesterson',
      BillingStreet = '139 Fittons Rd West',
      BillingCity = 'Orillia',
      BillingState = 'Ontario',
      BillingCountry = 'Canada',
      BillingPostalCode = 'L3V 3V3'
    );
    Test.startTest();
    insert a;
    Test.stopTest();
    Account[] geoAccounts = [SELECT Id FROM Account WHERE Geo_Account__c = :a.Id];
    a = [SELECT Id, IsPersonAccount, PersonMailingLatitude, PersonMailingLongitude FROM Account WHERE ID = :a.Id];
    System.assertEquals(1, geoAccounts.size());
    System.assertEquals(true, a.IsPersonAccount);
    //System.assert( a.PersonMailingLongitude != null, 'Mailing Longitude should be populated');
    //System.assert( a.PersonMailingLatitude != null, 'Mailing Latitude should be populated');
  }
}
