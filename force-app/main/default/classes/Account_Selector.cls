/**
 * Created by dave on 2020-06-09.
 */

public virtual class Account_Selector extends Application_Selector
{
  public class PersonAccount_Selector extends Account_Selector
  {
    public PersonAccount_Selector()
    {
      this.fields.addAll( defaultPersonFields );
    }
  }

  private final List<String> defaultFields = new List<String>{
    'Id',
    'RecordTypeId',
    'Name',
    'Phone',
    'BillingStreet',
    'BillingCity',
    'BillingState',
    'BillingStateCode',
    'BillingCountry',
    'BillingCountryCode',
    'BillingPostalCode'
  };

  private final List<String> defaultPersonFields = new List<String>{
    'PersonEmail',
    'FirstName',
    'LastName',
    'PersonHomePhone',
    'PersonMobilePhone',
    'PersonOtherPhone',
    'Preferred_Language__c',
    'Relationship_Status__c',
    'Number_Of_Children__c',
    'Hobbies__c',
    'Emotional_Motivation__c',
    'Occupation__c',
    'Animals__c',
    'Teams__c',
    'Tow_Vehicle__c',
    'WOW_Notes__pc',
    'Gender__pc',
    'Tax_Exempt_Status_Card_Number__pc'
  };

  public Account_Selector()
  {
    this.sObjectName = 'Account';
    this.fields = defaultFields;
  }

  public static Account[] allByIds( Set<Id> ids )
  {
    Account_Selector selector = new PersonAccount_Selector();
    selector.addWhereIdIn( ids );
    return selector.query();
  }

  public static Account[] allPersonAccountsByIds( Set<Id> ids )
  {
    PersonAccount_Selector selector = new PersonAccount_Selector();
    selector.addWhereIdIn( ids );
    return selector.query();
  }


}