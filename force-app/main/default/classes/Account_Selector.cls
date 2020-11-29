/**
 * Created by dave on 2020-06-09.
 */

public virtual class Account_Selector extends Application_Selector
{

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

  private final List<String> defaultBusinessFields = new List<String>{
    'AccountEmail__c',
    'Fax',
    'ShippingStreet',
    'ShippingCity',
    'ShippingState',
    'ShippingStateCode',
    'ShippingCountry',
    'ShippingCountryCode',
    'ShippingPostalCode'
  };

  public Account_Selector()
  {
    this.sObjectName = 'Account';
    this.fields = defaultFields;
  }


  public virtual class PersonAccount_Selector extends Account_Selector
  {
    public PersonAccount_Selector()
    {
      super();
      this.fields.addAll( defaultPersonFields );
    }
  }

  public virtual class BusinessAccount_Selector extends Account_Selector
  {
    public BusinessAccount_Selector()
    {
      super();
      this.fields.addAll( defaultBusinessFields );
    }
  }


  public static Account[] allByIds( Set<Id> ids )
  {
    PersonAccount_Selector selector = new PersonAccount_Selector();
    selector.addWhereIdIn( ids );
    return selector.query();
  }

  public static Account[] allPersonAccountsByIds( Set<Id> ids )
  {
    PersonAccount_Selector selector = new PersonAccount_Selector();
    selector.addWhereIdIn( ids );
    return selector.query();
  }

  public static Account personAccountById( Id recordId )
  {
    List<Account> result = allPersonAccountsByIds(
      new Set<Id>{recordId}
    );
    if( result.size() == 0 )
    {
      throw new Application_Selector.SelectorException(
        'No Account record found with supplied Id'
      );
    }
    else
    {
      return result[0];
    }
  }

  public static Account businessAccountWithContactsById( Id recordId )
  {
    BusinessAccount_Selector selector = new BusinessAccount_Selector();
    selector.addWhereIdIn( new Set<Id>{ recordId } )
    .addChildQuery(
      '(SELECT Id, FirstName, LastName, Email, Phone, MobilePhone, Title FROM Contacts)'
    );
    List<SObject> result = selector.query();
    if( result.size() == 0 )
    {
      throw new Application_Selector.SelectorException(
        'No Account record found with supplied Id'
      );
    }
    else
    {
      return (Account)result[0];
    }
  }


}