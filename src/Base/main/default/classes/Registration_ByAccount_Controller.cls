/**
 * Created by dave on 2019-09-04.
 */

public with sharing class Registration_ByAccount_Controller {

  public class Customer {
    public String accountId;
    public String title;
    public String description;
    public String icon;
    public String registrationYear;
    public Map<String, String> location;

    public Customer( Registration__c reg )
    {
      this.accountId = reg.Account__c;
      this.location = new Map<String, String>();
      this.icon = 'standard:account';
      //this.title = reg.Account__r.Name;
      this.registrationYear = String.valueOf( reg.Registered_Date__c.year() );
      this.location.put('Longitude', String.valueOf( reg.Account__r.PersonMailingLongitude ) );
      this.location.put('Latitude', String.valueOf( reg.Account__r.PersonMailingLatitude ) );
      this.location.put('State', String.valueOf( reg.Account__r.PersonMailingState ) );
      this.location.put('City', String.valueOf( reg.Account__r.PersonMailingCity ) );
      this.location.put('Country', String.valueOf( reg.Account__r.PersonMailingCountry ) );
      this.location.put('Street', String.valueOf( reg.Account__r.PersonMailingStreet ) );
      this.location.put('PostalCode', String.valueOf( reg.Account__r.PersonMailingPostalCode ) );
      this.description = buildDescription( reg );
    }

    private String buildDescription( Registration__c reg )
    {
      String result = '<b>' + reg.Account__r.Name + '</b>';
      result += '<br /><b>' + reg.SerialNumber__r.GMBLASERP__Product__r.Name + '</b>';
      result +=  '<br />' + reg.Account__r.PersonMailingStreet;
      result += '<br />' + reg.Account__r.PersonMailingCity + ', ' + reg.Account__r.PersonMailingState;
      result += '<br />' + reg.Account__r.PersonMailingPostalCode;
      return result;
    }

  }

  @AuraEnabled
  public static String fetchRegistrations( String registeredByAccountId )
  {
    if( registeredByAccountId == null )
    {
      User u = [ SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() ];
      if( u.AccountId == null ) return null;
      registeredByAccountId = u.AccountId;
    }
    Map<Id, Customer> result = new Map<Id, Customer>();
    Map<String, List<Customer>> byYear = new Map<String, List<Customer>>();
    for( Registration__c reg : Registration_Selector.allCustomerBoatRegisteredByAccountId( registeredByAccountId ) )
    {
      if( reg.Account__r.PersonMailingLatitude != null &&
          reg.Account__r.PersonMailingLongitude != null &&
          !result.containsKey( reg.Account__c ) )
        result.put( reg.Account__c, new Customer( reg ) );
    }
    for( Customer c : result.values() )
    {
      if( !byYear.containsKey( c.registrationYear ) )
        byYear.put( c.registrationYear, new List<Customer>() );
      byYear.get( c.registrationYear ).add( c );
    }
    return JSON.serialize( byYear );
  }

}