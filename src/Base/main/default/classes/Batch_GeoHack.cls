/**
 * Created by dave on 2019-09-13.
 */

global class Batch_GeoHack implements Database.Batchable<sObject> {
  String query;

  global Batch_GeoHack() {
    query = 'SELECT Id, FirstName, LastName, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode FROM Account WHERE IsPersonAccount = true AND GeoHack_Attempted__c = false';
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<Account> accts) {
    List<Account> geoAccts = new List<Account>();
    Id geoHackRtId = LGND_Utilities.recordTypeIdFromName('Account', 'Geo Hack');
    for (Account a : accts) {
      geoAccts.add(
        new Account(
          Name = a.FirstName + '_' + a.LastName + '-geo',
          BillingStreet = a.BillingStreet,
          BillingCity = a.BillingCity,
          BillingState = a.BillingState,
          BillingCountry = a.BillingCountry,
          BillingPostalCode = a.BillingPostalCode,
          RecordTypeId = geoHackRtId,
          Geo_Account__c = a.Id
        )
      );
      a.GeoHack_Attempted__c = true;
    }
    insert geoAccts;
    update accts;
  }

  global void finish(Database.BatchableContext BC) {
  }
}
