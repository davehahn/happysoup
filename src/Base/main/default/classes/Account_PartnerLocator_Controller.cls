public with sharing class Account_PartnerLocator_Controller {
  public class Partner {
    public String title;
    public String description;
    public Boolean isLegend;
    public String icon;
    public Map<String, String> location;

    public Partner(Account acct) {
      this.location = new Map<String, String>();
      this.title = acct.Name;
      this.description = buildDescription(acct);
      this.isLegend = acct.Is_Internal__c;
      this.icon = 'standard:account';
      this.location.put('Latitude', String.valueOf(acct.BillingLatitude));
      this.location.put('Longitude', String.valueOf(acct.BillingLongitude));
      this.location.put('State', String.valueOf(acct.BillingState));
      this.location.put('City', String.valueOf(acct.BillingCity));
      this.location.put('Country', String.valueOf(acct.BillingCountry));
      this.location.put('Street', String.valueOf(acct.BillingStreet));
      this.location.put('PostalCode', String.valueOf(acct.BillingPostalCode));
    }

    private String buildDescription(Account acct) {
      String result = acct.BillingStreet;
      result += '<br />' + acct.BillingCity + ', ' + acct.BillingState;
      result += '<br />' + acct.BillingPostalCode;
      return result;
    }
  }

  @AuraEnabled
  public static String fetchPartners() {
    Id dealerRTid = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer');
    List<Partner> result = new List<Partner>();
    for (Account acct : [
      SELECT
        Id,
        Name,
        BillingCity,
        BillingStreet,
        BillingCountry,
        BillingPostalCode,
        BillingState,
        BillingLatitude,
        BillingLongitude,
        Is_Internal__c
      FROM Account
      WHERE RecordTypeId = :dealerRTid AND Active__c = TRUE AND (NOT Name LIKE '%Wholesale%')
    ]) {
      result.add(new Partner(acct));
    }
    return JSON.serialize(result);
  }
}
