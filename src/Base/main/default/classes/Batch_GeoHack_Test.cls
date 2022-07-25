/**
 * Created by dave on 2019-09-13.
 */

@IsTest
private class Batch_GeoHack_Test {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void theTest() {
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
    Boolean orig = gcAccount.disableTrigger;
    gcAccount.disableTrigger = true;
    insert a;
    gcAccount.disableTrigger = orig;
    Test.startTest();
    Database.executeBatch(new Batch_GeoHack());
    Test.stopTest();
    Id geoHackRtId = LGND_Utilities.recordTypeIdFromName('Account', 'Geo Hack');
    Account[] geoAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :geoHackRtId];
    System.assertEquals(1, geoAccounts.size());
  }
}
